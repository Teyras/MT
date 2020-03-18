import asyncio
import re
from concurrent.futures import ProcessPoolExecutor
from datetime import datetime
from tempfile import NamedTemporaryFile, TemporaryDirectory

import numpy as np
import pandas as pd
import yaml


META_LIMITS = {
    "01-worker1-regular": {
        "memory": 1048576,
        "cpuTimePerTest": 60,
        "cpuTimePerExercise": 300,
        "wallTimePerTest": 60,
        "wallTimePerExercise": 300
    },
    "10-worker1-longrunning": {
        "memory": 4194304,
        "cpuTimePerTest": 900,
        "cpuTimePerExercise": 3600,
        "wallTimePerTest": 900,
        "wallTimePerExercise": 3600
    },
    "20-tomsk-parallel": {
        "memory": 4194304,
        "cpuTimePerTest": 120,
        "cpuTimePerExercise": 600,
        "wallTimePerTest": 120,
        "wallTimePerExercise": 600
    },
    "30-compilers": {
        "memory": 524288,
        "cpuTimePerTest": 900,
        "cpuTimePerExercise": 3600,
        "wallTimePerTest": 900,
        "wallTimePerExercise": 3600
    }
}


def read_timestamp(line: str) -> datetime:
    m = re.search(r'^\[([^\]]+)\]', line)
    return datetime.strptime(m.group(1), '%Y-%m-%d %H:%M:%S.%f')


async def unzip(sem_unzip, path, df, index):
    async with sem_unzip:
        unzip_process = await asyncio.create_subprocess_exec(
            "unzip",
            "-p",
            path,
            "result/job_system_log.log",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL
        )

        stdout, stderr = await unzip_process.communicate()

    if not stdout:
        return

    lines = stdout.decode().split("\n")
    first = read_timestamp(lines[0])
    last = read_timestamp(lines[-2])

    df.at[index, "processing_time"] = (last - first).total_seconds() * 1000


def read_time_limit_from_job_config(path, hwgroup):
    total = 0
    task_limit_found = False

    try:
        with open(path, "r") as config_file:
            config = yaml.safe_load(config_file)
            for task in config["tasks"]:
                if "sandbox" not in task:
                    continue
                elif "limits" not in task["sandbox"]:
                    time_limit = META_LIMITS[hwgroup]["cpuTimePerTest"]
                else:
                    for limit in task["sandbox"]["limits"]:
                        if limit["hw-group-id"] == hwgroup:
                            time_limit = max(limit.get("wall-time", 0), limit.get("time", 0))

                            if time_limit > 0:
                                task_limit_found = True
                                break
                    else:
                        time_limit = META_LIMITS[hwgroup]["cpuTimePerTest"]

                total += time_limit
    except FileNotFoundError:
        pass

    if not task_limit_found:
        total = min(META_LIMITS[hwgroup]["cpuTimePerExercise"], total)

    return total * 1000


def fill_in_time_limit(executor, path, df, index):
    hwgroup = df.at[index, "hardware_group_id"]
    #limit = await asyncio.get_running_loop().run_in_executor(executor, read_time_limit_from_job_config, path, hwgroup)
    limit = read_time_limit_from_job_config(path, hwgroup)
    df.at[index, "time_limit"] = limit


async def download(sem_scp, executor, sem_unzip, df, index, batch_size):
    async with sem_scp:
        fileserver = "recodex:/var/recodex-fileserver"
        ids = df["id"][index : index + batch_size]
        result_files = [*map(lambda x: f"{fileserver}/results/student_{x}.zip", ids)]
        job_config_files = [*map(lambda x: f"{fileserver}/submissions/./student_{x}/job-config.yml", ids)]

        tmp = TemporaryDirectory(prefix="ReCodEx_results_")
        results_process = await asyncio.create_subprocess_exec(
            "rsync",
            *result_files,
            tmp.name,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL
        )

        job_configs_process = await asyncio.create_subprocess_exec(
            "rsync",
            "--relative",
            *job_config_files,
            tmp.name,
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL
        )

        await asyncio.gather(results_process.wait(), job_configs_process.wait())

    if results_process.returncode != 0:
        tmp.cleanup()
        return

    await asyncio.gather(*[
        unzip(sem_unzip, f"{tmp.name}/student_{assignment_id}.zip", df, index + i) 
        for i, assignment_id in enumerate(ids)])

    [
        fill_in_time_limit(executor, f"{tmp.name}/student_{assignment_id}/job-config.yml", df, index + i)
        for i, assignment_id in enumerate(ids)]

    tmp.cleanup()


async def main():
    df = pd.read_csv("out.tsv", sep="\t")
    df["processing_time"] = np.nan
    df["time_limit"] = np.nan

    sem_scp = asyncio.Semaphore(8)
    sem_unzip = asyncio.Semaphore(64)
    executor = ProcessPoolExecutor()
    tasks = [asyncio.create_task(download(sem_scp, executor, sem_unzip, df, index, 256)) for index in range(0, len(df.index), 256)]

    await asyncio.gather(*tasks)
    df = df.dropna()
    df.to_csv("processed.tsv", sep="\t")


if __name__ == "__main__":
    asyncio.run(main())

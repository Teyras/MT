import pandas as pd
import sys
import click
import math

def read_isolation_results(filename: str):
    df = pd.read_csv(filename, header=None, names=[
        "isolation", "setup_type", "setup_size", "worker", "workload", "input_size", "iteration", "metric", "value"
    ], dtype=str, engine="c")

    df = df.assign(
        setup=df["setup_type"] + "," + df["setup_size"],
        value=df["value"].apply(pd.to_numeric),
        taskset=df["setup_type"].str.contains("taskset"),
        numa=df["setup_type"].str.contains("numa")
    )

    return df

@click.command()
@click.argument("filename")
def main(filename):
    df = read_isolation_results(filename)
    df = df[df["setup_type"] == "parallel-homogenous"]
    #df = df.set_index(["workload", "input_size", "isolation", "setup_type", "setup_size", "setup", "taskset", "worker", "iteration", "metric"])
    #df = df.unstack("metric")
    #df = pd.DataFrame(df.to_records())

    #def rename(x):
        #if ',' in x:
            #return x.split(",")[1].replace(")", "").replace("'", "").strip()

        #return x

    #df.rename(rename, axis="columns", inplace=True)

    last = df["iteration"].max()
    first = df["iteration"].min()
    result = []

    for key, values in df.groupby(["workload", "input_size", "isolation", "setup_type", "setup_size"]):
        start_values = values[values["metric"] == "start-wall"]
        result.append([
            key[0],
            key[1],
            key[2],
            key[3],
            key[4],
            start_values["value"].max() - start_values["value"].min(),
            start_values[start_values["iteration"] == last]["value"].min() - start_values[start_values["iteration"] == first]["value"].max()
        ])

    result_df = pd.DataFrame(result, columns=["workload", "input_size", "isolation", "setup_type", "setup_size", "total_runtime", "parallel_runtime"])
    result_df = result_df.assign(
        parallel_ratio=result_df["parallel_runtime"] / result_df["total_runtime"],
        workload_label=result_df["workload"].str.replace("^[^/]*/", ""),
    )

    table = result_df[["setup_size", "workload_label", "isolation", "parallel_ratio"]]
    table = table.sort_values(by="parallel_ratio")

    table.to_csv(sys.stdout)

if __name__ == "__main__":
    main()

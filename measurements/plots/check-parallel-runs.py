import pandas as pd
import click
from tabulate import tabulate

from helpers import read_isolation_results

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
        workload_label=result_df["workload"] + " " + result_df["input_size"],
    )

    table = result_df[["setup_size", "workload_label", "isolation", "parallel_ratio"]]
    table = table.sort_values(by="parallel_ratio")
    table["parallel_ratio"] = pd.Series(["{0:.2f}%".format(val * 100) for val in table['parallel_ratio']], index=table.index)

    print(table.pipe(tabulate, headers="keys", tablefmt="pipe", showindex="never"))

if __name__ == "__main__":
    main()

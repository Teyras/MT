import pandas as pd

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


import pandas as pd
import numpy as np
import seaborn
import random
import click
import os
from matplotlib import colors
from pathlib import Path

from helpers import read_isolation_results


def background_gradient(s, m, M, low=0, high=0):
    colormap = seaborn.light_palette("red", as_cmap=True)

    rng = M - m
    norm = colors.Normalize(m - (rng * low), M + (rng * high))
    normed = norm(s.values)
    c = [colors.rgb2hex(x) for x in colormap(normed)]
    return ['background-color: %s' % color for color in c]


def highlight_gt(s, threshold):
    return ['font-weight: 700' if value > threshold else '' for value in s.values]


def mad(values):
    median = np.median(values)
    return np.median(np.abs(values - median))


def value_range(values):
    return values.max() - values.min()


def process(result_file, aggregation_func, values):
    groups = values.groupby(["workload", "input_size", "isolation", "setup"])["value"].aggregate(aggregation_func)
    min_value = groups.min()
    max_value = groups.max()

    for workload, frame in values.groupby(["workload", "input_size"]):
        for taskset in (False, True):
            worker = frame.iloc[0]["worker"]
            value_group = frame[(frame["taskset"] == taskset) & (frame["worker"] == worker) & (frame["numa"] == False)]

            colnames = list(value_group.groupby(["setup", "setup_size"]).groups.keys())
            colnames.sort(key=lambda row: int(row[1]))
            colnames = list(map(lambda row: row[0], colnames))
            rownames = list(filter(lambda x: x in value_group["isolation"].values, 
                                  ("bare", "isolate", "docker-bare", "docker-isolate", "vbox-bare", "vbox-isolate")))

            result = pd.pivot_table(value_group, index="isolation", columns="setup", values="value", aggfunc=aggregation_func)
            result = result.reindex(colnames, axis="columns")
            result = result.reindex(rownames, axis="index")

            style = result.style.apply(background_gradient, m=min_value, M=max_value).format("{:.3}")
            style = style.apply(highlight_gt, threshold=0.05)

            result_file.write(f"<h3>{workload}{' + taskset' if taskset else ''}</h3>")
            result_file.write(style.render())

@click.command()
@click.argument("filename")
def main(filename):
    target_dir = Path.cwd() / "isolation-comparison"
    os.makedirs(str(target_dir), exist_ok=True)

    df = read_isolation_results(filename)

    for metric, values in df.groupby("metric"):
        for aggregation_func in (mad, value_range, np.std):
            with (target_dir / f"{metric}-{aggregation_func.__name__}.html").open("w") as result_file:
                process(result_file, aggregation_func, values)


if __name__ == "__main__":
    main()


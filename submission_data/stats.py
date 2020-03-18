import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import timedelta

from utils import read_df


def success(series):
    return len(series) - sum(series)


def analyze_assignment_success(df):
    success_table = pd.pivot_table(df, index=["assignment_id", "author_id"], values="failed", aggfunc=[len, success])

    counts = success_table["success"]["failed"].value_counts()
    observations = sum(counts)
    continued = sum(counts[counts.index > 1])

    print("# Success rate analysis")
    print(f"Unfinished: {counts[0]} ({counts[0] * 100 / observations:.2f}%)")
    print(f"Finished after first success: {counts[1]} ({counts[1] * 100 / observations:.2f}%)")
    print(f"Multiple successful attempts: {continued} ({continued * 100 / observations:.2f}%)")
    print()


def ratio(df, cond):
    return f"{len(df[cond]) * 100 / len(df):.2f}%"


def analyze_proximity_to_deadline(df):
    df = df.copy()
    df["deadline_proximity"] = (df["first_deadline"] - df["submitted_at"]).map(lambda d: timedelta(hours=d.total_seconds() // 3600))

    print("# Deadline proximity analysis")
    print(ratio(df, df["deadline_proximity"] < timedelta(hours=0)))
    print(ratio(df, (df["deadline_proximity"] >= timedelta(hours=0)) & (df["deadline_proximity"] < timedelta(hours=2))))  # TODO
    print(ratio(df, (df["deadline_proximity"] >= timedelta(hours=2)) & (df["deadline_proximity"] < timedelta(hours=12))))
    print(ratio(df, (df["deadline_proximity"] >= timedelta(hours=12)) & (df["deadline_proximity"] < timedelta(hours=48))))
    print(ratio(df, df["deadline_proximity"] >= timedelta(hours=48)))
    print()


def analyze_proximity_to_assignment(df):
    df = df.copy()
    df["assignment_proximity"] = (df["submitted_at"] - df["assigned_at"]).map(lambda d: timedelta(hours=d.total_seconds() // 3600))

    print("# Assignment proximity analysis")
    print(ratio(df, df["assignment_proximity"] < timedelta(hours=2)))
    print(ratio(df, (df["assignment_proximity"] >= timedelta(hours=2)) & (df["assignment_proximity"] < timedelta(hours=12))))
    print(ratio(df, (df["assignment_proximity"] >= timedelta(hours=12)) & (df["assignment_proximity"] < timedelta(hours=48))))
    print(ratio(df, (df["assignment_proximity"] >= timedelta(hours=48)) & (df["assignment_proximity"] < timedelta(hours=168))))
    print(ratio(df, df["assignment_proximity"] >= timedelta(hours=168)))
    print()


def analyze_hourly_activity(df):
    counts = df["submitted_at"].map(lambda t: t.hour).value_counts()
    result = pd.DataFrame({"hour_of_submission": counts.index, "freq": counts.values})
    result["%"] = result["freq"] * 100 / len(df)
    result = result.sort_values("hour_of_submission")
    print(result)
    print()


def analyze_second_deadline_exploitation(df):
    after_first = df[df["submitted_at"] > df["first_deadline"]]
    before_second = after_first[after_first["submitted_at"] <= after_first["second_deadline"]]
    without_second = after_first[after_first["second_deadline"] <= after_first["first_deadline"]]
    print("# Analysis of submissions after deadline")
    print(f"Submissions after first deadline: {len(after_first)} ({len(after_first) * 100 / len(df):.2f}%)")
    print(f"Submissions before second deadline: {len(before_second)} ({len(before_second) * 100 / len(df):.2f}% of all, {len(before_second) * 100 / len(after_first):.2f}% of late)")
    print(f"Submissions after first deadline with second deadline disabled: {len(without_second)} ({len(without_second) * 100 / len(df):.2f}% of all, {len(without_second) * 100 / len(after_first):.2f}% of late)")
    print()


def analyze_processing_times_of_failures(df):
    times = pd.pivot_table(df, index=["runtime_environment_id", "assignment_id", "failed"], values="processing_time", aggfunc=[np.mean, np.median])
    print(times)


def analyze_processing_times(df):
    times = pd.pivot_table(df, index=["runtime_environment_id", "hardware_group_id"], values="processing_time", aggfunc=[np.mean, np.median, np.std])
    print(times)
    
    eval_times = pd.pivot_table(df, index=["runtime_environment_id", "hardware_group_id"], values="evaluation_time", aggfunc=[np.mean, np.median, np.std])
    print(eval_times)


def analyze_delay(df):
    df = df.copy()
    df["delay"] = df["evaluation_time"] - df["processing_time"]

    print(df["delay"])


def main():
    df = read_df("processed.tsv")
    analyze_assignment_success(df)
    analyze_proximity_to_deadline(df)
    analyze_proximity_to_assignment(df)
    analyze_second_deadline_exploitation(df)
    analyze_hourly_activity(df)
    analyze_processing_times(df)
    analyze_delay(df)
    # analyze_processing_times_of_failures(df)


if __name__ == "__main__":
    main()

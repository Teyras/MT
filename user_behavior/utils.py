from datetime import timedelta

import pandas as pd

def to_datetime(column):
    return pd.to_datetime(column, format="%Y-%m-%d %H:%M:%S", infer_datetime_format=False, errors="coerce")


def read_df(filename):
    df = pd.read_csv(filename, sep="\t")

    df['submitted_at'] = to_datetime(df['submitted_at'])
    df['evaluated_at'] = to_datetime(df['evaluated_at'])
    df['assigned_at'] = to_datetime(df['assigned_at'])
    df['first_deadline'] = to_datetime(df['first_deadline'])
    df['second_deadline'] = to_datetime(df['second_deadline'])
    df['evaluation_time'] = (df['evaluated_at'] - df['submitted_at']) / timedelta(milliseconds=1)

    return df



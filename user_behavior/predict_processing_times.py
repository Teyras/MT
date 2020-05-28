from collections import deque, defaultdict
from datetime import timedelta

import numpy as np
import pandas as pd

from utils import read_df


class Predictor:
    RETAINED_OBSERVATIONS = 20

    def __init__(self):
        record_container_factory = lambda: deque(maxlen=self.RETAINED_OBSERVATIONS)
        self.observations_by_rtenv = defaultdict(record_container_factory)
        self.observations_by_exercise = defaultdict(record_container_factory)
        self.observations_by_author = defaultdict(record_container_factory)
        self.hits = defaultdict(lambda: 0)
    
    def add_observation(self, hwgroup: str, rtenv: str, exercise: int, author: int, processing_time: float) -> None:
        self.observations_by_rtenv[f"{hwgroup}${rtenv}"].append(processing_time)
        self.observations_by_exercise[f"{hwgroup}${rtenv}${exercise}"].append(processing_time)
        self.observations_by_author[f"{hwgroup}${rtenv}${exercise}${author}"].append(processing_time)

    def predict(self, hwgroup: str, rtenv: str, exercise: int, author: int, limit: int) -> float:
        by_author = self.observations_by_author[f"{hwgroup}${rtenv}${exercise}${author}"]
        if len(by_author) > 0:
            self.hits["author"] += 1
            return np.median(by_author)

        by_exercise = self.observations_by_exercise[f"{hwgroup}${rtenv}${exercise}"]
        if len(by_exercise) > 1:
            self.hits["exercise"] += 1
            return np.median(by_exercise)

        by_rtenv = [o for o in self.observations_by_rtenv[f"{hwgroup}${rtenv}"] if o < limit]
        if len(by_rtenv) > 1:
            self.hits["rt_env"] += 1
            return np.median(by_rtenv)

        self.hits["limit"] += 1
        return limit / 2


def main():
    df = read_df("processed.tsv")
    result_data = []
    pred = Predictor()

    for index, row in df.iterrows():
        hwgroup = row["hardware_group_id"]
        rtenv = row["runtime_environment_id"]
        exercise = row["exercise_id"]
        author = row["author_id"]
        submitted_at = row["submitted_at"]
        processing_time = row["processing_time"] / 1000
        limit = row["time_limit"] / 1000

        prediction = pred.predict(hwgroup, rtenv, exercise, author, limit)
        pred.add_observation(hwgroup, rtenv, exercise, author, processing_time)
        result_data.append([hwgroup, rtenv, exercise, author, submitted_at, processing_time, round(prediction, 3)])

    result = pd.DataFrame(result_data, columns=["hardware_group_id", "runtime_environment_id", "exercise_id", "author_id", "submitted_at", "processing_time", "prediction"])
    result.to_csv("predictions.tsv", sep="\t")

    print(pred.hits)



if __name__ == "__main__":
    main()

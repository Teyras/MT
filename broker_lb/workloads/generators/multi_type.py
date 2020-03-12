from argparse import Namespace, ArgumentTypeError
from dataclasses import dataclass
import random

from numpy.random import normal

from common import create_args_parser, generate


@dataclass
class JobType:
    hwgroup: str
    weight: int
    duration_mean: int
    duration_sd: int

    @classmethod
    def load(cls, string_value):
        try:
            parts = string_value.split(",")
            return JobType(hwgroup=parts[1], weight=int(parts[0]), duration_mean=int(parts[2]), duration_sd=int(parts[3]))
        except Exception as e:
            raise ArgumentTypeError(f"Invalid job type specification: {str(e)}")


args_parser = create_args_parser("Generate jobs of multiple types with the same composition over the whole duration of the workload.")
args_parser.add_argument("--jobs", dest="jobs", nargs="+", type=JobType.load, help="description of job types")


def job_generator(args: Namespace):
    while True:
        job_type: JobType = random.choices(args.jobs, [*map(lambda t: t.weight, args.jobs)], k=1)[0]

        headers = ['env=c', f'hwgroup={job_type.hwgroup}']
        duration = int(normal(job_type.duration_mean, job_type.duration_sd))

        yield duration, headers


if __name__ == "__main__":
    args = args_parser.parse_args()
    generate(job_generator(args), args)

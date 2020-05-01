from argparse import Namespace
import random

from numpy.random import normal

from common import create_args_parser, generate, JobType


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

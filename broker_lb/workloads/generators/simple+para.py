from argparse import Namespace
from numpy.random import randint, normal

from common import create_args_parser, generate

args_parser = create_args_parser("Generate simple jobs and parallel jobs with a configured probability")
args_parser.add_argument("--para-rate", dest="para_rate", type=int)
args_parser.add_argument("--para-duration", dest="para_duration_params", nargs=2, type=int, help="Parameters of a normal distribution")
args_parser.add_argument("--simple-duration", dest="simple_duration_params", nargs=2, type=int, help="Parameters of a normal distribution")


def job_generator(args: Namespace):
    while True:
        para = randint(0, 99) < args.para_rate

        duration_params = args.para_duration_params if para else args.simple_duration_params
        duration = int(normal(*duration_params))

        headers = ["env=c", "hwgroup=group_parallel"] if para else ["env=c", "hwgroup=group_common|group_parallel"]

        yield duration, headers


if __name__ == "__main__":
    args = args_parser.parse_args()
    generate(job_generator(args), args)

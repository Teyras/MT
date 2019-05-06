from argparse import Namespace

from itertools import count
from numpy.random import randint, normal

from common import create_args_parser, generate

args_parser = create_args_parser("Generate jobs of two types. In the first phase, only the first type is generated. In the second phase, both are generated.")
args_parser.add_argument("--second-rate", dest="second_rate", type=int, help="How likely (in percents) are jobs of the second type in the second phase")
args_parser.add_argument("--phase-threshold", dest="phase_threshold", type=int, help="How many jobs of the first type must be generated before the second phase begins")
args_parser.add_argument("--first-duration", dest="first_duration_params", nargs=2, type=int, help="Parameters of a normal distribution")
args_parser.add_argument("--second-duration", dest="second_duration_params", nargs=2, type=int, help="Parameters of a normal distribution")


def job_generator(args: Namespace):
    first_type_headers = ['env=c']
    second_type_headers = ['env=java']

    for i in count():
        first_duration = normal(*args.first_duration_params)
        second_duration = normal(*args.second_duration_params)

        if i > args.phase_threshold and randint(0, 99) < args.second_rate:
            yield second_duration, second_type_headers

        yield first_duration, first_type_headers


if __name__ == "__main__":
    args = args_parser.parse_args()
    generate(job_generator(args), args)

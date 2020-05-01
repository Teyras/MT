from argparse import Namespace

from itertools import count
from numpy.random import randint, normal

from common import create_args_parser, generate, JobType

args_parser = create_args_parser("Generate jobs of two types. In the first phase, only the first type is generated. In the second phase, both are generated.")
args_parser.add_argument("--second-rate", dest="second_rate", type=int, help="How likely (in percents) are jobs of the second type in the second phase")
args_parser.add_argument("--phase-threshold", dest="phase_threshold", type=int, help="How many jobs of the first type must be generated before the second phase begins")
args_parser.add_argument("--first-job", dest="first_type", type=JobType.load, help="Description of the first job type")
args_parser.add_argument("--second-job", dest="second_type", type=JobType.load, help="Description of the second job type")


def job_generator(args: Namespace):
    for i in count():
        first_duration = normal(args.first_type.duration_mean, args.first_type.duration_sd)
        second_duration = normal(args.second_type.duration_mean, args.second_type.duration_sd)

        if i > args.phase_threshold and randint(0, 99) < args.second_rate:
            yield second_duration, ['env=c', f'hwgroup={args.second_type.hwgroup}']
        else:
            yield first_duration, ['env=c', f'hwgroup={args.first_type.hwgroup}']


if __name__ == "__main__":
    args = args_parser.parse_args()
    generate(job_generator(args), args)

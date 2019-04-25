from argparse import Namespace

from .common import create_args_parser, generate

args_parser = create_args_parser()
args_parser.add_argument("percent_para", nargs=1, type=float)


def job_generator(args: Namespace):
    yield


if __name__ == "__main__":
    args = args_parser.parse_args()
    generate(job_generator, args)

from argparse import ArgumentParser, Namespace
from typing import Generator, Any, Tuple, List


def create_args_parser() -> ArgumentParser:
    args_parser = ArgumentParser()
    args_parser.add_argument("count", nargs=1, type=int)
    args_parser.add_argument("average_delay", nargs=1, type=int)
    return args_parser


def calculate_delay(average: int):
    return average


def generate(generator: Generator[Namespace, Any, Tuple[int, List[str]]], args: Namespace):
    time = 0

    for _ in range(args.count):
        generator
        time += calculate_delay(args.average_delay)

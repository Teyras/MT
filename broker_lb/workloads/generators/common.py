import csv
import sys
from argparse import ArgumentParser, Namespace
from numpy.random import exponential
from typing import Generator, Any, List, Tuple


def create_args_parser(description: str) -> ArgumentParser:
    args_parser = ArgumentParser(description=description)
    args_parser.add_argument("--count", dest="count", type=int)
    args_parser.add_argument("--avg-delay", dest="average_delay", type=int)
    return args_parser


def calculate_delay(average: int):
    return int(exponential(average))


def generate(generator: Generator[Tuple[int, List[str]], int, Any], args: Namespace):
    """
    :param generator: a generator that yields tuples where the first item is the duration of a job and the second is a
                      list of string headers (as understood by the broker) and receives the total elapsed time
    :param args: CLI configuration
    """

    out = csv.writer(sys.stdout)
    time = 0

    for _ in range(args.count):
        # Let the generator generate a job
        duration, job_headers = next(generator)
        duration = max(duration, 100)

        # Output the generated job
        out.writerow([time, duration] + job_headers)

        # Calculate the delay before another job is generated and tell the generator the current time
        time += calculate_delay(args.average_delay)
        generator.send(time)

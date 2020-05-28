import random
import sys

def cli(n: int):
    with open("data.{}.in".format(n), "w") as f:
        f.write(str(n) + "\n")
        f.writelines(( str(random.randint(-(2**16), 2**16 - 1)) + "\n" for _ in range(n) ))

if __name__ == "__main__":
    cli(int(sys.argv[1]))


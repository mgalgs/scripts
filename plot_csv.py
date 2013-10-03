#!/usr/bin/env python2

import sys
import os
import csv
import argparse
from itertools import cycle
from matplotlib import pyplot as plt


DESCRIPTION = """Plots csv data from sdtin. Data should be in the following format:

header1,header2,...
data,data,...
data,data,...
"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=DESCRIPTION,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('title')
    parser.add_argument('ylabel')
    parser.add_argument('xlabel')
    parser.add_argument('--y-bottom', type=int, metavar='YB',
                        help='Lower limit for y-axis on plot')
    parser.add_argument('--y-top', type=int, metavar='YT',
                        help='Upper limit for y-axis on plot')

    args = parser.parse_args()

    reader = csv.reader(sys.stdin)
    lines = []
    for row in reader:
        lines.append(row)

    titles = lines.pop(0)
    data = []
    for line in lines:
        data.append([float(d) for d in line])

    ymin = min([min(row) for row in data])
    ymax = max([max(row) for row in data])
    yrange = ymax - ymin
    ymin -= .1 * yrange
    ymax += .1 * yrange

    if args.y_bottom is not None:
        ymin = args.y_bottom
    if args.y_top is not None:
        ymax = args.y_top

    p1 = plt.plot(data, '-o')
    plt.legend(p1, titles)
    plt.ylim([ymin, ymax])
    plt.title(args.title)
    plt.ylabel(args.ylabel)
    plt.xlabel(args.xlabel)
    plt.grid(True)
    plt.show()

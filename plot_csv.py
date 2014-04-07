#!/usr/bin/env python2

import sys
import os
import csv
import argparse
from itertools import cycle
from matplotlib import pyplot as plt
import numpy as np


DESCRIPTION = """Plots csv data from sdtin. Data should be in the following format:

header1,header2,...
data,data,...
data,data,...
"""

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=DESCRIPTION,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--title')
    parser.add_argument('--ylabel')
    parser.add_argument('--xlabel')
    parser.add_argument('--y-bottom', type=float, metavar='YB',
                        help='Lower limit for y-axis on plot')
    parser.add_argument('--y-top', type=float, metavar='YT',
                        help='Upper limit for y-axis on plot')
    parser.add_argument('--x-bottom', type=float, metavar='XB',
                        help='Lower limit for x-axis on plot')
    parser.add_argument('--x-top', type=float, metavar='XT',
                        help='Upper limit for x-axis on plot')
    parser.add_argument('--scatter', action='store_true',
                        help='Generate a scatter plot. When given, there should only be two columns of data.')

    args = parser.parse_args()

    xlabel = ylabel = None

    reader = csv.reader(sys.stdin)
    lines = []
    for row in reader:
        lines.append(row)

    titles = lines.pop(0)
    data = []
    for cnt,line in enumerate(lines):
        try:
            data.append([float(d) for d in line])
        except:
            print 'Skipping invalid line (%d):' % cnt, line
            pass

    ymin = min([min(row) for row in data])
    ymax = max([max(row) for row in data])

    if args.y_bottom is not None:
        ymin = args.y_bottom
    if args.y_top is not None:
        ymax = args.y_top

    yrange = ymax - ymin
    if args.y_bottom is None:
        ymin -= .1 * yrange
    if args.y_top is None:
        ymax += .1 * yrange

    xmin = args.x_bottom
    xmax = args.x_top

    if args.scatter:
        data = np.array(data)
        plt.scatter(data[:, 0], data[:, 1])
        if xmin is None:
            xmin = min(data[:, 0])
        if xmax is None:
            xmax = xmax or max(data[:, 0]) + 1
        xlabel, ylabel = titles
    else:
        p1 = plt.plot(data, '-o')
        plt.legend(p1, titles, loc='best')

    if xmin is not None and xmax is not None:
        plt.xlim([xmin, xmax])

    plt.ylim([ymin, ymax])

    if args.title:
        plt.title(args.title.replace('\\n', '\n'))
    if args.ylabel or ylabel:
        plt.ylabel(args.ylabel or ylabel)
    if args.xlabel or xlabel:
        plt.xlabel(args.xlabel or xlabel)

    plt.grid(True)
    plt.show()

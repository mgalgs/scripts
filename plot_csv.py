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
    parser.add_argument('--smooth', type=int,
                        nargs='?', const=11, metavar='window_len',
                        help='Smooth the data by convolving it with a Hanning window of the given length. window_len defaults to 11.')
    parser.add_argument('--raw', action='store_true',
                        help='When --smooth is given, raw data is not plotted. This overrides that behavior, forcing raw data to be plotted as well.')

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

    data = np.array(data)

    xmin = args.x_bottom
    xmax = args.x_top

    if args.scatter:
        plt.scatter(data[:, 0], data[:, 1])
        if xmin is None:
            xmin = min(data[:, 0])
        if xmax is None:
            xmax = xmax or max(data[:, 0]) + 1
        xlabel, ylabel = titles
    else:
        smoothed = []
        linestyle = os.getenv('LINESTYLE', '-o')
        if args.smooth:
            w = np.hamming(args.smooth)
            smoothed = []
            for d in data.transpose():
                out = np.convolve(d, w / w.sum(), mode='valid')
                smoothed.append(out)
            smoothed = np.array(smoothed).transpose()
            psmoothed = plt.plot(smoothed,  linestyle)
            # plt.legend(psmoothed, 'Smoothed')
        if not args.smooth or args.raw:
            p1 = plt.plot(data, linestyle)
            plt.legend(p1, titles, loc='best')

    if xmin is not None and xmax is not None:
        plt.xlim([xmin, xmax])

    ymin = data.min()
    ymax = data.max()

    if args.y_bottom is not None:
        ymin = args.y_bottom
    if args.y_top is not None:
        ymax = args.y_top

    yrange = ymax - ymin
    if args.y_bottom is None:
        ymin -= .1 * yrange
    if args.y_top is None:
        ymax += .1 * yrange

    plt.ylim([ymin, ymax])

    if args.title:
        plt.title(args.title.replace('\\n', '\n'))
    if args.ylabel or ylabel:
        plt.ylabel(args.ylabel or ylabel)
    if args.xlabel or xlabel:
        plt.xlabel(args.xlabel or xlabel)

    plt.grid(True)
    plt.show()

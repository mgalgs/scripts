#!/usr/bin/env python2

import sys
import csv
from itertools import cycle
from matplotlib import pyplot as plt


if __name__ == "__main__":
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

    p1 = plt.plot(data)
    plt.legend(p1, titles)
    plt.ylim([ymin, ymax])
    plt.title(sys.argv[1])
    plt.ylabel(sys.argv[2])
    plt.xlabel(sys.argv[3])
    plt.grid(True)
    plt.show()

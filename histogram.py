#!/usr/bin/env python

# script adapted from http://stackoverflow.com/a/5328669/209050

import numpy as np
import matplotlib.pyplot as plt
import sys

def get_data(min_thresh, max_thresh ):
    try:
        data = []
        for n in sys.stdin.readlines():
            if n == '' or n == '\n': continue
            nf = float(n)
            if nf > max_thresh: continue
            if nf < min_thresh: continue
            data.append( nf )
    except Exception, e:
        print "Invalid input format!"
        print "please make sure you're only giving me numbers on stdin."
        print e
        sys.exit(1)
    return data

if __name__ == "__main__":
    min_thresh = float(sys.argv[1])
    max_thresh = float(sys.argv[2])
    data = get_data(min_thresh, max_thresh)

    hist,bins = np.histogram(data, bins=max_thresh - min_thresh)
    width = 0.7 * (bins[1] - bins[0])
    center = (bins[:-1] + bins[1:]) / 2
    plt.bar(center, hist, align='center', width=width)
    plt.show()

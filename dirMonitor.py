#!/usr/bin/env python

import os, sys, time

folders = sys.argv[1:]

currSize = dict((x, 0) for x in folders)
totalSize = dict((x, 0) for x in folders)
maxSize = dict((x, 0) for x in folders)

fmts = "%*s  %13s  %13s  %13s"
fmtd = "%*s  %13d  %13d  %13d"

n = 0
while True:
    print fmts % (15, "dir", "size", "avg", "max")
    n += 1
    for folder in folders:
        bytes = sum( os.path.getsize(os.path.join(dirpath, filename)) for dirpath, dirnames, filenames in os.walk( folder ) for filename in filenames )
        currSize[folder] = bytes
        totalSize[folder] += bytes
        maxSize[folder] = max(maxSize[folder], bytes)
        avg = totalSize[folder] / n
        print fmtd % (15, folder, bytes, avg, maxSize[folder])
    print ""
    time.sleep(1)

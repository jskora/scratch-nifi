#!/usr/bin/env python

import os, sys, time

folders = sys.argv[1:]
nameWidth = max([len(f) for f in folders])

currSize = dict((x, 0) for x in folders)
totalSize = dict((x, 0) for x in folders)
maxSize = dict((x, 0) for x in folders)

fmts = "%*s  %13s%s  %13s%s  %13s%s"

n = 0
while True:
    print fmts % (nameWidth, "directory", "curr size", " ", "avg size", " ", "max size", " ")
    n += 1
    for folder in folders:
        try:
            bytes = sum( os.path.getsize(os.path.join(dirpath, filename))
                            for dirpath, dirnames, filenames in os.walk( folder )
                            for filename in filenames )
            oldSize = currSize[folder]
            oldAvg = 1 if n == 1 else totalSize[folder]/(n-1)
            oldMax = maxSize[folder]
            currSize[folder] = bytes
            totalSize[folder] += bytes
            maxSize[folder] = max(maxSize[folder], bytes)
            avg = totalSize[folder] / n
            print fmts % (nameWidth, folder,
                            "{:,}".format(bytes), "+" if bytes > oldSize else "-" if bytes < oldSize else " ",
                            "{:,}".format(avg), "+" if avg > oldAvg else "-" if avg < oldAvg else " ",
                            "{:,}".format(maxSize[folder]), "+" if maxSize[folder] > oldMax else " ")
        except:
            pass
    print ""
    time.sleep(2)

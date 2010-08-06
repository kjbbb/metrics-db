#!/usr/bin/python

import pyRserve
from datetime import date, timedelta
import hashlib
import sys

conn = pyRserve.rconnect()

datefmt = "%Y-%m-%d"
basepath = "/tmp/ernie/"
networksize = "plot_networksize_line('%s','%s','%s')"

graphs = ["networksize", "versions", "platforms", "bandwidth", "uptime",
    "gettor", "torperf"]

ranges = ["30", "90", "180"]

for r in ranges:
    end = date.today()
    start = end - timedelta(days=int(r))

    path = basepath + hashlib.md5("networksize-" + str(start) \
           + "-" + str(end)).hexdigest() + ".png"

    networksize_q = networksize % (start, end, path)
    #Query Rserve
    conn(networksize_q)

conn.close()

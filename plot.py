#!/usr/bin/python

import pyRserve
from datetime import date, timedelta
import hashlib
import sys
import pg

dbhost = "localhost"
dbuser = "ernie"
dbpassword = ""
db = "tordir"

conn = pyRserve.rconnect()
dbconn = pg.connect(dbname=dbuser, dbhost=dbhost, \
    dbpasswd=dbpassword, dbname=db)

datefmt = "%Y-%m-%d"
basepath = "/tmp/ernie/"
networksize = "plot_networksize_line('%s','%s','%s')"

graphs = ["networksize", "versions", "platforms", "bandwidth", "uptime",
    "gettor", "torperf"]

#Find years, min and max ranges.
ranges = ["30", "90", "180"]

yearquery = "select extract(year from date(date)) " +
            "from network_size " +
            "group by extract(year from date(date))"

dbconn.query(yearquery)

for r in ranges:
    end = date.today()
    start = end - timedelta(days=int(r))

    path = basepath + hashlib.md5("networksize-" + str(start) \
           + "-" + str(end)).hexdigest() + ".png"

    networksize_q = networksize % (start, end, path)

    #Query Rserve
    conn(networksize_q)

conn.close()

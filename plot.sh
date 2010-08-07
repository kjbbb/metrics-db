#!/bin/sh

#Plot default graphs using Rserve, in a way that the website
#find and use them.

#The graphs are encoded like "md5sum(graphname-start-end).png"

R --slave < R/graphs.R

if [ ! -d "/tmp/ernie/"]; then
  #mkdir /tmp/ernie/
  #groupmod -a -G apache /tmp/ernie
fi

basepath = "/tmp/ernie/"
ranges = ("-30 day" "-90 day" "-180 day")

for r in $ranges do
  #Calculate date ranges and file names.
  start = `date --utc -d "$r" +%Y-%m-%d`
  end = `date --utc +%Y-%m-%d`
  md5path = `echo "networksize-$start-$end" | md5sum`
  rstring = "plot_networksize_line('$start','$end','$path')"

  #Connect to Rserve and plot the graphs
  echo "library(Rserve)
  c <- RSconnect()
  RSeval(\"$rstring\")" | R --slave
done

years = ("2006" "2007" "2008" "2009" "2010")
for y in $years do
  start = `date --utc -d "$r-01-01" +%Y-%m-%d`
  end = `date --utc -d "$r-01-01" +%Y-%m-%d`
done

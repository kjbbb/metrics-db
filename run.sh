#!/bin/sh

# TODO get database name and user from config
if [ $# != 2 ]; then
  echo "usage: $0 dbname dbuser"
  exit
fi
DB=$1
USER=$2

# TODO is there a better way to suppress Ant's output?
ant -q | grep -Ev "^$|^BUILD SUCCESSFUL|^Total time: "

# TODO check whether or not we should even use database from config
# Include time it takes to do this in ernie run time.
psql -A -t -q $DB $USER -f db/matviewrefresh.sql

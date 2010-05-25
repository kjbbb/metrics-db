#!/bin/sh

# TODO is there a better way to suppress Ant's output?
ant -q | grep -Ev "^$|^BUILD SUCCESSFUL|^Total time: "

# Refresh matviews if we are supposed to
n=`grep "^WriteRelayDescriptorDatabase" config | awk '{print $2}'`
if [ "$n" -eq 1 ]; then
    # TODO Alternatively use a more reliable URI parser?
        #db=$( echo "$uri" | ruby -ruri -e 'puts URI.parse(gets.chomp).path' )

    uri=`grep "^RelayDescriptorDatabaseJDBC" config | awk '{print $2}'`
    conn=`echo $uri | awk -F"//" '{print $2}'`
    host=`echo $conn | sed -e 's/\/.*//'`
    db=`echo $conn | awk -F"/" '{print $2}' | sed -e 's/\?.*//'`
    user=`echo $conn | awk -F"=" '{print $2}' | sed -e 's/\&.*//'`
    pswd=`echo $conn | awk -F"password=" '{print $2}'`

    export PGPASSWORD="$pswd"
    psql -d $db -h $host -A -t -q -U $user -f db/refresh.sql
fi

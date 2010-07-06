#!/bin/sh

###########################################################
# NOTE                                                    #
# RUN THIS AS ROOT - Rserve will run as user rserve       #
###########################################################

dir=`pwd`
R CMD Rserve --RS-conf $dir/Rserv.conf

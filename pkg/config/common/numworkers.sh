#!/bin/bash

NUMCORES=`/usr/bin/nproc`
NUMWORKERS=$(( $NUMCORES / 2 )):

if [ $NUMWORKERS -lt 2 ]]; then
        NUMWORKERS=2
fi

echo $NUMWORKERS

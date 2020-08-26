#!/bin/bash

# invoke this script with `watch observe_jobs.sh <PROJECT>`
PROJECT="${1}"
STEPS=$(ls -1 "${PROJECT}/jobs" | sed '/lock/d')
JOBS=$(find "${PROJECT}/jobs" -iname '*.job')

for istep in $STEPS ; do
  echo "${istep}:"
  for cstate in pending finished ; do
    CJ=$(echo "${JOBS}" | grep $istep | grep $cstate | \
      sed -e "s/${istep}//g" -e "s/${cstate}//g" -e "s/jobs//g" -e "s/\///g" -e "s/^\.//g" | tr '\n' ' ')
    echo "  ${cstate}: $CJ" 
  done
done

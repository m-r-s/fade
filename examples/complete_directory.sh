#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 DIRECTORY [START] [FILTER]"
  echo ""
  echo "  Will complete all projects in DIRECTORY using the complete_project.sh script."
  echo "  An additional START point can be specified which will overwrite the"
  echo "  specified step and all following steps."
  echo "  Available steps are: corpus features training recognition evaluation figures"
  echo "  An additional FILTER can be used to complete only matching projects."
  echo ""
  exit 1
fi

DIRECTORY="$1"
START="$2"
FILTER="$3"

DIR=$(cd "$( dirname "$0" )" && pwd)

(cd "${DIRECTORY}" && ls -1 */.fade-*) | \
  sed 's/\/\.fade-[-.0-9a-zA-Z]*$//g' | sort -u | \
  grep -E -e "$FILTER" | while read line; do
    "${DIR}/complete_project.sh" "${DIRECTORY}/${line}" "$START"
  done
  

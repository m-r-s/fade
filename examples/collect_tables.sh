#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 DIRECTORY [FILTER] [COLUMNS] [MODE]"
  echo ""
  echo "  Will join tables from all projects in DIRECTORY and cut the selected columns."
  echo "  FILTER allows to filter the projects."
  echo "  Selected columns are specified with comma-separation."
  echo "  E.g.: '1,3-' would select columns 1 and 3 and all following columns (-)."
  echo "  MODE can be 'ascii' (default) or 'matlab'."
  echo " 'matlab' converts the table to valid copy-and-pastable Matlab code."
  echo ""
  exit 1
fi

FIELDS='1-'
MODE='ascii'
DIRECTORY="$1"

if [ -n "$2" ]; then
  FILTER="$2"
fi

if [ -n "$3" ]; then
  FIELDS="$3"
fi

if [ -n "$4" ]; then
  MODE="$4"
fi

printtable() {
local MODE="$1"
case $MODE in
  ascii)
    cat - | column -t
  ;;
  matlab)
    TABLE=$(cat -)
    echo 'table_data = { ...'
    echo -e "$TABLE" | sed -e "s/^/'/g" -e "s/ /' '/g" -e "s/$/'/g" | awk '{print $0 " ; ..."}' | column -t | awk '{print "  " $0}'
    echo '};'
  ;;
esac
}

HEADER=0
(cd "${DIRECTORY}" && ls -1 */figures/table.txt) | grep -E -e "$FILTER" | sort | while read line; do
  NAME=$(echo "$line" | cut -d/ -f1)
  if [ "$HEADER" == "0" ]; then
    echo "PROJECT "$(cat "${DIRECTORY}/$line" | head -n1)
    HEADER=1
  fi
  cat "${DIRECTORY}/${line}" | tail -n+2 | awk -v name="$NAME" '{print name " " $0}'
done | tr -s " " | cut -d" " -f"$FIELDS" | printtable "$MODE"




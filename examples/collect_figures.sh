#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 DIRECTORY [TARGET]"
  echo ""
  echo "  Will collect figures from all projects in DIRECTORY copy them to TARGET."
  echo "  Default target is the current directory."
  echo ""
  exit 1
fi

DIRECTORY="$1"
TARGET="$2"

[ -n "$TARGET" ] || TARGET="$PWD"

mkdir -p "$TARGET" || exit 1

(cd "${DIRECTORY}" && ls -1 */figures/*.eps) | while read line; do
  cp "${DIRECTORY}/$line" "${TARGET}/"$(echo $line | sed 's/\/figures\//-/g')
done

#!/bin/bash

# removes multiple whitespaces, duplicates, and trailing / leading spaces
echo "${1}" | \
#   tr '\n' ' ' | \
#   awk '$1=$1' | \ # created problems with zeros, whyever, try this with "+00 +03"
   tr ' ' '\n'  | \
   sort -u | \
   tr '\n' ' ' | \
   sed -e 's/[[:space:]]*$//' | \
   sed -e 's/^[[:space:]]*//'

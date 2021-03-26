#!/bin/bash

# Debugging script that keeps track on the number of calls to anything that is nice to track

PROJECT=$1
CASE_NUM=$2
CASE_EXP=$3

# lock file
TARGET="${PROJECT}/case-counts.txt"
while ! mkdir "${TARGET%.txt}-lock.d" &>/dev/null; do
  sleep 1
done

# add file if it does not exist
[ -f "${TARGET}" ] || touch "${TARGET}"
# init value with 0
[ -z $(cat "${TARGET}" | grep "^${CASE_NUM}: ${CASE_EXP}" | awk '{print $3}') ] && echo "${CASE_NUM}: ${CASE_EXP} 0" >> ${TARGET}

# increase count
NEW_VAL=$(cat "${TARGET}" | grep "^${CASE_NUM}: ${CASE_EXP}" | awk '{print $3+1}')
sed -i "s/^${CASE_NUM}: ${CASE_EXP}.*/${CASE_NUM}: ${CASE_EXP} ${NEW_VAL}/" "${TARGET}"

# unlock file
rmdir "${TARGET%.txt}-lock.d"

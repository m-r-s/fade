#!/bin/bash

# 1. Get triggered
# 2. Read from jobs/features
# 3. Extract features from jobs in queues
# 4. Write to jobs/train or jobs/test
# 5. Trigger train or test

## Variables
PROJECT=$1
DATABANK="${PROJECT}/config/databank"

# Script Name
SCN=$(basename "$0")
# Script Log File
SLF="${PROJECT}/log/${SCN%.sh}.log"
# Project config file
PCF="${PROJECT}/config/config.cfg"
source "${PCF}"

# MUTEX
sleep 2
LDIR="${PROJECT}/jobs/${SCN%.sh}-lock.d"
if ! mkdir "${LDIR}" &>/dev/null; then
  echo "could not get lock on '${LDIR}'" >> ${SLF} #LOG
  exit 0
fi

# pending features jobs dir
PFJ="${PROJECT}/jobs/features/pending"
# finished features jobs dir
FFJ="${PROJECT}/jobs/features/finished"

# pending training jobs dir
PTJ="${PROJECT}/jobs/training/pending"
# finished training jobs directory
FTJ="${PROJECT}/jobs/training/finished"

# pending recognition jobs dir
PREJ="${PROJECT}/jobs/recognition/pending"
# finished recognition jobs directory
FREJ="${PROJECT}/jobs/recognition/finished"

## Script body
JOBS_PENDING=$(ls -1 "${PFJ}" | grep "job$" | wc -l)
while [ ${JOBS_PENDING} -gt 0 ]; do
  ls -1 "${PFJ}" | grep "job$" | while read line ; do
    # source new parameters
    source "${PFJ}/${line}"
      dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
      echo "${dt}: running ${line}" >> ${SLF} #LOG
    # extract features
    fade "${SUB_PROJECT}" features $FO >> ${SLF}

    # queuing Training script, and trigger it
    if [ -n "${TRAIN_SNR}" ] ; then
      NUMBER_PENDING_JOBS_TRAIN=$(ls -1 ${PTJ} | grep "job$" | wc -l)
      NUMBER_FINISHED_JOBS_TRAIN=$(ls -1 ${FTJ} | grep "job$" | wc -l)
      NUM_TRAIN=$((NUMBER_PENDING_JOBS_TRAIN + NUMBER_FINISHED_JOBS_TRAIN))
      {
        echo "SUB_PROJECT='${SUB_PROJECT}'"
        echo "TRAIN_SNR='${TRAIN_SNR}'"
      } > "${PTJ}/t${NUM_TRAIN}.job"
      q_train.sh ${PROJECT} > /dev/null 2>&1 &
    fi

    # queuing Recognition script, and trigger it
    if [ -n "${TEST_SNR}" ] ; then
      NUMBER_PENDING_JOBS_RECOG=$(ls -1 ${PREJ} | grep "f2.*job$" | wc -l)
      NUMBER_FINISHED_JOBS_RECOG=$(ls -1 ${FREJ} | grep "f2.*job$" | wc -l)
      NUM_RECOG=$((NUMBER_PENDING_JOBS_RECOG + NUMBER_FINISHED_JOBS_RECOG))
      {
        echo "SUB_PROJECT='${SUB_PROJECT}'"
        echo "TEST_SNR='${TEST_SNR}'"
      } > "${PREJ}/f2re${NUM_RECOG}.job"
      q_db.sh "${DATABANK}" "add" "ALL_TEST_SNRS_RECOG" "${TEST_SNR}"
      q_recog.sh ${PROJECT} > /dev/null 2>&1 &
    fi
    # cleaning up
    mv "${PFJ}/${line}" "${FFJ}/${line}"
  done
  JOBS_PENDING=$(ls -1 "${PFJ}" | grep "job$" | wc -l)
done
rmdir "${LDIR}"

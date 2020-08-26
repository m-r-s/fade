#!/bin/bash

# 1. Get triggered
# 2. Read from jobs/train
# 3. Train GMM/HMM from jobs in queues
# 4. Write to jobs/recog
# 5. Trigger recog

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

# pending training jobs dir
PTJ="${PROJECT}/jobs/training/pending"
# finished training jobs directory
FTJ="${PROJECT}/jobs/training/finished"

# pending recognition jobs dir
PREJ="${PROJECT}/jobs/recognition/pending"
# finished recognition jobs directory
FREJ="${PROJECT}/jobs/recognition/finished"

## Script body
JOBS_PENDING=$(ls -1 "${PTJ}" | grep "job$" | wc -l)
while [ ${JOBS_PENDING} -gt 0 ]; do
  ls -1 "${PTJ}" | grep "job$" | while read line ; do
    # source new parameters
    source "${PTJ}/${line}"
      dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
      echo "${dt}: running ${line}" >> ${SLF} #LOG

    # create dummy feature files for corpus-format
    create_dummy_test_features_and_format.sh "${SUB_PROJECT}" >> ${SLF}
    # train models
    fade "${SUB_PROJECT}" training $TO  >> ${SLF}

    mv "${PTJ}/${line}" "${FTJ}/${line}"
    NUMBER_PENDING_JOBS_RECOG=$(ls -1 ${PREJ} | grep "t2.*job$" | wc -l)
    NUMBER_FINISHED_JOBS_RECOG=$(ls -1 ${FREJ} | grep "t2.*job$" | wc -l)
    NUM_RECOG=$((NUMBER_PENDING_JOBS_RECOG + NUMBER_FINISHED_JOBS_RECOG))
    {
      echo "SUB_PROJECT='${SUB_PROJECT}'"
      echo "TRAIN_SNR='${TRAIN_SNR}'"
    } > "${PREJ}/t2re${NUM_RECOG}.job"
    q_db.sh "${DATABANK}" "add" "ALL_TRAIN_SNRS" "${TRAIN_SNR}"
    q_recog.sh ${PROJECT} > /dev/null 2>&1 &
  done
  JOBS_PENDING=$(ls -1 "${PTJ}" | grep "job$" | wc -l)
done
rmdir "${LDIR}"

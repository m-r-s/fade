#!/bin/bash

## Script Description
# Record signals and store them in the projects corpus directory
# 1. Get triggered
# 2. Read from jobs/record
# 3. Record jobs in queues
# 4. Write to jobs/features
# 5. Trigger features

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

# recording jobs dir
RJ="${PROJECT}/jobs/record"
# pending recording jobs dir
PRJ="${PROJECT}/jobs/record/pending"
# finished recording jobs directory
FRJ="${PROJECT}/jobs/record/finished"
# pending features jobs dir
PFJ="${PROJECT}/jobs/features/pending"
# finished features jobs dir
FFJ="${PROJECT}/jobs/features/finished"

# handle processing and its options
OLEN=$(echo "${PO}" | wc -w)
PROC="$(echo "${PO}" | cut -d' ' -f1)"
[ "$OLEN" -gt 1 ] && PROC_OPTS="$(echo "${PO}" | cut -d' ' -f2-)" || PROC_OPTS=''

## Script body
JOBS_PENDING=$(ls -1 "${PRJ}" | grep -c "job$")
while [ ${JOBS_PENDING} -gt 0 ]; do # run loop until no more jobs are pending
  ls -1 "${PRJ}" | grep "job$" | while read line ; do # run loop for all pending jobs
    # source new parameters
    source "${PRJ}/${line}"
      dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
      echo "${dt}: running ${line} with Train SNR ${TRAIN_SNR} and Test SNR ${TEST_SNR}" >> ${SLF} #LOG

    # add recorded SNRs to databank
    q_db.sh "${DATABANK}" "add" "ALL_REAL_TRAIN_SNRS" "${TRAIN_SNR}"
    ALL_REAL_TRAIN_SNRS=$(q_db.sh "${DATABANK}" "get" "ALL_REAL_TRAIN_SNRS" "")
      echo "${dt}:   ALL_REAL_TRAIN_SNRS='${ALL_REAL_TRAIN_SNRS}'" >> ${SLF} #LOG
    q_db.sh "${DATABANK}" "add" "ALL_TEST_SNRS_RECORD" "${TEST_SNR}"
    ALL_TEST_SNRS_RECORD=$(q_db.sh "${DATABANK}" "get" "ALL_TEST_SNRS_RECORD" "")
      echo "${dt}:   ALL_TEST_SNRS_RECORD='${ALL_TEST_SNRS_RECORD}'" >> ${SLF} #LOG

    copy_essentials.sh "${PROJECT}" "${SUB_PROJECT}" >> ${SLF}
    # generate corpus, if test sample size is 20, use one random list for testing
    if [ ${NUM_TEST_SAMPLES} -eq 20 ] ; then
      echo "run: link_corpus_rand_list.sh '${SUB_PROJECT}' '${TRAIN_SNR}' '${NUM_TRAIN_SAMPLES}' '${TEST_SNR}' '${NUM_TEST_SAMPLES}'" >> ${SLF}
      link_corpus_rand_list.sh "${SUB_PROJECT}" "${TRAIN_SNR}" "${NUM_TRAIN_SAMPLES}" "${TEST_SNR}" "${NUM_TEST_SAMPLES}" >> ${SLF}
    else
      echo "run: link_corpus.sh '${SUB_PROJECT}' '${TRAIN_SNR}' '${NUM_TRAIN_SAMPLES}' '${TEST_SNR}' '${NUM_TEST_SAMPLES}'" >> ${SLF}
      link_corpus.sh "${SUB_PROJECT}" "${TRAIN_SNR}" "${NUM_TRAIN_SAMPLES}" "${TEST_SNR}" "${NUM_TEST_SAMPLES}" >> ${SLF}
    fi
    # process corpus
    preproc_corpus.sh "${SUB_PROJECT}" "${EAR}" "${SAMPLING_RATE}" "${PROC}" "${PROC_OPTS}" "${TRAIN_SNR}" "${TEST_SNR}" >> ${SLF} #FIXME! CHECK HERE
    wait

    # removes extra whitespace, duplicates, and trailing and leading whitspaces
    if [ $(echo "${ALL_REAL_TRAIN_SNRS}" | tr ' ' '\n' | wc -l) -gt 1 ]; then
        echo "${dt}:   run: copy_virtual.sh '${PROJECT}' '${SUB_PROJECT}' '${ALL_REAL_TRAIN_SNRS}'" >> ${SLF} #LOG
      VSNRS_NEW=$(copy_virtual.sh "${PROJECT}" "${SUB_PROJECT}" "${ALL_REAL_TRAIN_SNRS}")
    fi

    # add recorded virtual SNRs to databank (mixed by using two training SNRs)
    q_db.sh "${DATABANK}" "add" "VIRTUAL_SNRS" "${VSNRS_NEW}"
    VIRTUAL_SNRS=$(q_db.sh "${DATABANK}" "get" "VIRTUAL_SNRS" "")
      dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
      echo "${dt}:   VIRTUAL_SNRS='${VIRTUAL_SNRS}'" >> ${SLF} #LOG

    TRAIN_SNRS_FOR_EXTEND=$(rws.sh "${TRAIN_SNR} ${VSNRS_NEW}")

    # queuing next script
    NUMBER_PENDING_JOBS_FEATURES=$(ls -1 ${PFJ} | grep -c "job$")
    NUMBER_FINISHED_JOBS_FEATURES=$(ls -1 ${FFJ} | grep -c "job$" )
    NUM=$((NUMBER_PENDING_JOBS_FEATURES + NUMBER_FINISHED_JOBS_FEATURES))
    # do not create file if both are empty
    if [ -n "${TRAIN_SNRS_FOR_EXTEND}" ] || [ -n "${TEST_SNR}" ] ; then
      {
        echo "SUB_PROJECT='${SUB_PROJECT}'"
        echo "TRAIN_SNR='${TRAIN_SNRS_FOR_EXTEND}'"
        echo "TEST_SNR='${TEST_SNR}'"
      } > "${PFJ}/f${NUM}.job"
    fi
    # Trigger next script and send it to bg
    q_features.sh ${PROJECT} > /dev/null 2>&1 &
    # cleaning up
    mv "${PRJ}/${line}" "${FRJ}/${line}"
  done
  # before finishing the loop, check if there are still jobs pending
  JOBS_PENDING=$(ls -1 "${PRJ}" | grep -c "job$")

  # break loop and remove lock
done
rmdir "${LDIR}"

#!/bin/bash

# 1. Get triggered from train AND features
# 2. Read from jobs/recog
# 3. Recog from jobs in queues
# 4. Write to jobs/check
# 5. Trigger check

# This script is more complicated to ensure that the recognition process is not
# repeated for all available training/testing SNRs.
# Hence, only NEW traing SNRs are tested with the OLD test SNRs and vice versa.

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

function is_missing {
  # function to check if the recognition was already performed
  # required to save time and due to adding the training/test SNRs in q_traing
  # and q_features.
  PRO="${1}"
  IND="${2}"
  SNR="${3}"
  OUT="1"
  if [ -f "${PRO}/evaluation/summary" ] ; then
    PERF_RECOG=($(cat "${PRO}/evaluation/summary" | cut -d' ' -f${IND} | sort -u | grep "snr${SNR}"))
    [ "${#PERF_RECOG[@]}" -eq "0" ] || OUT="0"
  fi
  echo "${OUT}"
}

# recognition jobs dir
REJ="${PROJECT}/jobs/recognition"
[ -d ${REJ} ] || mkdir -p ${REJ}
# pending recognition jobs dir
PREJ="${PROJECT}/jobs/recognition/pending"
[ -d ${PREJ} ] || mkdir -p ${PREJ}
# finished recognition jobs directory
FREJ="${PROJECT}/jobs/recognition/finished"
[ -d ${FREJ} ] || mkdir -p ${FREJ}

# check if training files exist
## Script body
JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c ".*job$")
while [ ${JOBS_PENDING} -gt 0 ]; do
  # wait until there are enough features/models available for training AND testing SNRs
  T2JOBS=$(find "${REJ}" -iname "t2*job$")
  F2JOBS=$(find "${REJ}" -iname "f2*job$")
  ALL_TRAIN_SNRS=$(q_db.sh "${DATABANK}" "get" "ALL_TRAIN_SNRS" "")
  ALL_TEST_SNRS_RECOG=$(q_db.sh "${DATABANK}" "get" "ALL_TEST_SNRS_RECOG" "")
  while [ "${#T2JOBS[@]}" -eq 0 ] || \
        [ "${#F2JOBS[@]}" -eq 0 ] || \
        [ "$(echo ${ALL_TRAIN_SNRS} | wc -w)" -lt 2 ] || \
        [ "$(echo ${ALL_TEST_SNRS_RECOG} | wc -w)" -lt 2 ] ; do
    sleep 2
    T2JOBS=$(find "${REJ}" -iname "t2*job$")
    F2JOBS=$(find "${REJ}" -iname "f2*job$")
    ALL_TRAIN_SNRS=$(q_db.sh "${DATABANK}" "get" "ALL_TRAIN_SNRS" "")
    ALL_TEST_SNRS_RECOG=$(q_db.sh "${DATABANK}" "get" "ALL_TEST_SNRS_RECOG" "")
  done

  #######################
  # Do the training jobs
  #######################
  T2JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c "t2.*job$")
  while [ ${T2JOBS_PENDING} -gt 0 ]; do
    ls -1 "${PREJ}" | grep "t2.*job$" | while read t2line ; do
      source "${PREJ}/${t2line}"
      # check if all required files exists
      TRAIN_SNRS=(${TRAIN_SNR})
        dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
        echo "${dt}: running ${t2line}" >> ${SLF} #LOG

      #FIXME: remove this?
      USE_THESE_TRAIN_SNRS=$(for ((itrain=0; itrain<${#TRAIN_SNRS[@]}; itrain++)); do
        NEW_TRAIN=${TRAIN_SNRS[$itrain]}
        if [ $(is_missing "${PROJECT}" 1 "${NEW_TRAIN}") -eq "1" ]; then
          echo "${NEW_TRAIN}"
        fi
      done | tr '\n' ' ')
      RSP=$(create_recog_subproject.sh "${PROJECT}" "${USE_THESE_TRAIN_SNRS}" "${ALL_TEST_SNRS_RECOG}")
      fade "${RSP}" recognition $RO >> ${SLF}
      fade "${RSP}" evaluation >> ${SLF}

      # mv job and trigger next script
      mv "${PREJ}/${t2line}" "${FREJ}/${t2line}"
      q_break_or_adjust.sh ${PROJECT} > /dev/null 2>&1 &
    done #t2line
    T2JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c "t2.*job$")
  done #T2JOBS_PENDING

  ###########################################################################################
  # Do the testing jobs
  ###########################################################################################
  F2JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c "f2.*job$")
  while [ ${F2JOBS_PENDING} -gt 0 ]; do
    ls -1 "${PREJ}" | grep "f2.*job$" | while read f2line ; do
      # source new parameters
      source "${PREJ}/${f2line}"
      # only do something if it was not already conducted before
      if [ $(is_missing "${PROJECT}" 2 "${TEST_SNR}") -eq "1" ]; then
          dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
          echo "${dt}: running ${f2line}: ${TEST_SNR} --> [${ALL_TRAIN_SNRS}] [${TEST_SNR}]" >> ${SLF} #LOG
        RSP=$(create_recog_subproject.sh "${PROJECT}" "${ALL_TRAIN_SNRS}" "${TEST_SNR}")
        fade "${RSP}" recognition $RO >> ${SLF}
        fade "${RSP}" evaluation >> ${SLF}
        # cat that into the overall summary
        # [ -d "${PROJECT}/evaluation" ] || mkdir "${PROJECT}/evaluation"
        # cat "${RSP}/evaluation/summary" >> "${PROJECT}/evaluation/summary"
      fi

      # mv job and trigger next script
      mv "${PREJ}/${f2line}" "${FREJ}/${f2line}"
      q_break_or_adjust.sh ${PROJECT} > /dev/null 2>&1 &
    done # f2line
    F2JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c "f2.*job$")
  done # F2JOBS_PENDING
  # check if there are new jobs
  JOBS_PENDING=$(ls -1 "${PREJ}" | grep -c ".*job$")
done
rmdir "${LDIR}"

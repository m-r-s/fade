#!/bin/bash

# 1. Get triggered
# 2. Run evaluation
# 3. Check for break condition or adjust Train and Test snrs
# 4. Write to jobs/pending/record
# 5. Trigger record

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


DIR=$( dirname "$0" )
# pending recording jobs dir
PRJ="${PROJECT}/jobs/record/pending"
[ -d ${PRJ} ] || mkdir -p ${PRJ}
# finished recording jobs directory
FRJ="${PROJECT}/jobs/record/finished"
[ -d ${FRJ} ] || mkdir -p ${FRJ}

# Get all summaries #TODO: sort -u should not be required!
[ -d "${PROJECT}/evaluation" ] || mkdir "${PROJECT}/evaluation"
find "${PROJECT}" -mindepth 3 -iwholename "*evaluation/summary" | sed -e '/sub-pre/d' | xargs cat | sort -u > "${PROJECT}/evaluation/summary"

# Break or adjust storage
BAS="${PROJECT}/jobs/break_or_adjust"

ALL_REAL_TRAIN_SNRS=$(q_db.sh "${DATABANK}" "get" "ALL_REAL_TRAIN_SNRS" "")

## Script body
NUM_RECOG=$(find "${PROJECT}" -mindepth 1 -maxdepth 1 -iname "*-recog-*" | wc -l)
while [ "${NUM_RECOG}" -lt 2 ]; do
  sleep 5
  NUM_RECOG=$(find "${PROJECT}" -mindepth 1 -maxdepth 1 -iname "*-recog-*" | wc -l)
done

NUM_CONDITIONS_PER_TRAIN_SNR=0
NUM_CONDITIONS_PER_TEST_SNR=0

# backup summary, and only use recorded SNRs #TODO simplify?
[ -f "${BAS}/tmp-summary" ] && rm "${BAS}/tmp-summary"
[ -s "${PROJECT}/evaluation/summary" ] && cp "${PROJECT}/evaluation/summary" "${BAS}/tmp-summary"
# filters out all snrs which are "virtual" but does not consider real train snrs which are not processed yet
[ -s "${BAS}/tmp-summary" ] && ALL_TRAIN_SNRS=$(for itrain in ${ALL_REAL_TRAIN_SNRS}; do
      cat "${BAS}/tmp-summary" | awk '{gsub(/snr/,"snr ",$1); print}' | awk -v snr=${itrain} '$2==snr {print $2}' | sort -u | tr '\n' ' '
    done)
[ -s "${BAS}/tmp-summary" ] && ALL_TEST_SNRS=$(cat "${BAS}/tmp-summary" | awk '{gsub(/snr/,"snr ",$2); print}' | awk '{print $3}' | sort -u | tr '\n' ' ')

[ -s "${BAS}/tmp-summary" ] && NUM_CONDITIONS_PER_TRAIN_SNR=$(for itrain in $ALL_REAL_TRAIN_SNRS; do
    cat "${BAS}/tmp-summary" | awk '{gsub(/snr/,"snr ",$1); print}' | awk -v snr=${itrain} '$2==snr {print $2}' | wc -w
  done | sort -n | head -1)
[ -s "${BAS}/tmp-summary" ] && NUM_CONDITIONS_PER_TEST_SNR=$(for itest in $ALL_TEST_SNRS; do
    cat "${BAS}/tmp-summary" | awk '{gsub(/snr/,"snr ",$2); print}' | awk -v snr=${itest} '$3==snr {print $3}' | wc -w
  done | sort -n | head -1)

[ -z "${NUM_CONDITIONS_PER_TRAIN_SNR}" ] && NUM_CONDITIONS_PER_TRAIN_SNR=0
[ -z "${NUM_CONDITIONS_PER_TEST_SNR}" ] && NUM_CONDITIONS_PER_TEST_SNR=0

# check that there are two conditions per train and test snrs
if [ $NUM_CONDITIONS_PER_TRAIN_SNR -ge 2 ] && [ $NUM_CONDITIONS_PER_TEST_SNR -ge 2 ]; then
  # check how to modify the training and testing snrs, do this only on real training snrs and not for virtual ones (see copy_virtual.sh)
  TTR=$(for itrain in ${ALL_REAL_TRAIN_SNRS}; do
        cat "${BAS}/tmp-summary" | tr '_' ' ' | sed 's/snr//g' | awk -v snr=${itrain} '$2==snr {print $2" "$4" "$6/$5; }'
      done)

  # log the config of gen_cases
  echo "-----------------------" >> "${BAS}/gen_cases_config.txt"
  echo "ttr=[${TTR}]"            >> "${BAS}/gen_cases_config.txt"
  echo "thr=[${TARGET_RECOGNITION_RATE}]" >> "${BAS}/gen_cases_config.txt"
  echo "ats=[${ALL_TRAIN_SNRS}]" >> "${BAS}/gen_cases_config.txt"
  echo "gen_cases(ttr,thr,ats);" >> "${BAS}/gen_cases_config.txt"

  CASES=($(echo "gen_cases([${TTR}],${TARGET_RECOGNITION_RATE},[${ALL_TRAIN_SNRS}])" | run-matlab 'ror-fade' | tr ',' ' '))
  # cases: true means do something, false means do nothing
  CASE_1="${CASES[0]}" # true if all rrs lower than target
                       # --> increase test snrs
  CASE_2="${CASES[1]}" # true if all rrs greater than target
                       # --> decrease test snrs
  CASE_3="${CASES[2]}" # true if rr at upper train snr
                       # --> increase train snr
  CASE_4="${CASES[3]}" # true if rr at lower train snr and if rr not at upper train snr, i.e., first increase train snr before decreasing
                       # --> decrease train snr
  CASE_5="${CASES[4]}" # true if less than two test snrs are below srt
                       # --> decrease test snrs
  CASE_6="${CASES[5]}" # true if the simulation should be stopped
                       # --> stop simulation

    dt=$(date '+%d/%m/%Y %H:%M:%S'); #LOG
    echo "${dt}: running q_break_or_adjust.sh, cases: ${CASE_1} ${CASE_2} ${CASE_3} ${CASE_4} ${CASE_5} ${CASE_6}" >> ${SLF} #LOG

  TEST_SNR=''
  TRAIN_SNR=''
  if [ ${CASE_1} -eq 1 ]; then
    # --> increase test snrs record
    TEST_SNR=$( echo "val = max([${ALL_TEST_SNRS}]) + ${TEST_CORRECTION}; printf('%+03.0f',val);" | run-matlab )
      echo "${dt}: CASE_1 --> increase test snrs" >> "${SLF}" #LOG
  fi
  if [ ${CASE_2} -eq 1 ] || [ ${CASE_5} -eq 1 ]; then
    # --> decrease test snrs
    TEST_SNR=$( echo "val = min([${ALL_TEST_SNRS}]) - ${TEST_CORRECTION}; printf('%+03.0f',val);" | run-matlab )
      echo "${dt}: CASE_2 or CASE_5 --> decrease test snrs" >> "${SLF}" #LOG
  fi
  if [ ${CASE_3} -eq 1 ]; then
    # --> increase train snr
    TRAIN_SNR=$( echo "val = max([${ALL_TRAIN_SNRS}]) + ${TRAIN_CORRECTION}; printf('%+03.0f',val);" | run-matlab )
      echo "${dt}: CASE_3 --> increase train snr" >> "${SLF}" #LOG
  fi
  if [ ${CASE_4} -eq 1 ]; then
    # --> decrease train snr
    TRAIN_SNR=$( echo "val = min([${ALL_TRAIN_SNRS}]) - ${TRAIN_CORRECTION}; printf('%+03.0f',val);" | run-matlab )
      echo "${dt}: CASE_4 --> decrease train snr" >> "${SLF}" #LOG
  fi
  if [ ${CASE_6} -eq 1 ]; then
    # --> stop simulation
      echo "${dt}: CASE_6 --> stop simulation" >> "${SLF}" #LOG

    # using only the multicondition SNRs typically yields lower SRTs,
    # However one can also use the recorded SNR ---> (marginally) increases cpu load
    # Otherwise use this function:
    # filter_virtual_summary.sh "${PROJECT}" "${TRAIN_CORRECTION}"

    fade "${PROJECT}" figures >> ${SLF}
    rmdir "${LDIR}"
    echo "Breaking the loop" > "${PROJECT}/is-running" # parse to fifo, otherwise project will never finish
    exit 0
  fi

  # Abort if range is exceeded (max level is 130 dB SPL, and min level is -20 dB SPL)
  MAX_TRAIN=$((130-$SPEECH_LEVEL))
  MIN_TRAIN=$((-20-$SPEECH_LEVEL))
  MAX_TEST=$((130-$SPEECH_LEVEL))
  MIN_TEST=$((-20-$SPEECH_LEVEL))
  if [ ${TRAIN_SNR} -ge ${MAX_TRAIN} ] || [  ${TEST_SNR} -ge ${MAX_TEST} ] || [ ${TRAIN_SNR} -le ${MIN_TRAIN} ] || [  ${TEST_SNR} -le ${MIN_TEST} ]; then
    mkdir "${PROJECT}/figures"
    echo "Exceeded range, aborting: Train SNR was ${TRAIN_SNR}, Test SNR was ${TEST_SNR}" > "${PROJECT}/figures/table.txt"
    rmdir "${LDIR}"
    echo "Breaking the loop" > "${PROJECT}/is-running" # parse to fifo, otherwise project will never finish
    exit 1
  fi

  # get number of finished and pending record jobs and number of sub projects
  NUMBER_PENDING_JOBS_RECORD=$(ls -1 ${PRJ} | grep "job$" | wc -l)
  NUMBER_FINISHED_JOBS_RECORD=$(ls -1 ${FRJ} | grep "job$" | wc -l)
  NUMBER_TOTAL_JOBS_RECORD=$((NUMBER_PENDING_JOBS_RECORD + NUMBER_FINISHED_JOBS_RECORD))
  NUM_SUBS=$(find "${PROJECT}" -mindepth 1 -maxdepth 1 -iname "*sub-main-*" | sed '/recog/d' | grep -c "sub-main")

  # queuing record script, and trigger it if the train snr is new
  ALL_REAL_TRAIN_SNRS_RECORD=$(q_db.sh "${DATABANK}" "get" "ALL_REAL_TRAIN_SNRS" "")
  C_TRAIN=""
  [ -n "${TRAIN_SNR}" ] && C_TRAIN=$(echo "${ALL_REAL_TRAIN_SNRS_RECORD}" | tr ' ' '\n' | grep '\'"${TRAIN_SNR}")
  if [ -n "${TRAIN_SNR}" ] && [ -z "${C_TRAIN}" ] ; then
    {
      echo "SUB_PROJECT='${PROJECT}/sub-main-${NUM_SUBS}'"
      echo "TRAIN_SNR='${TRAIN_SNR}'"
      echo "TEST_SNR=''"
    } > "${PRJ}/r${NUMBER_TOTAL_JOBS_RECORD}.job"
    NUM_SUBS=$((NUM_SUBS + 1))
    NUMBER_TOTAL_JOBS_RECORD=$((NUMBER_TOTAL_JOBS_RECORD + 1))
  fi

  # queuing record script, and trigger it
  ALL_TEST_SNRS_RECORD=$(q_db.sh "${DATABANK}" "get" "ALL_TEST_SNRS_RECORD" "")
  C_TEST=""
  [ -n "${TEST_SNR}" ] && C_TEST=$(echo "${ALL_TEST_SNRS_RECORD}" | tr ' ' '\n' | grep '\'"${TEST_SNR}")
  if [ -n "${TEST_SNR}" ] && [ -z "${C_TEST}" ] ; then
    {
      echo "SUB_PROJECT='${PROJECT}/sub-main-${NUM_SUBS}'"
      echo "TRAIN_SNR=''"
      echo "TEST_SNR='${TEST_SNR}'"
    } > "${PRJ}/r${NUMBER_TOTAL_JOBS_RECORD}.job"
    # NUM_SUBS=$((NUM_SUBS + 1))
    # NUMBER_TOTAL_JOBS_RECORD=$((NUMBER_TOTAL_JOBS_RECORD + 1))
  fi

  # trigger recording script
  q_record.sh ${PROJECT} > /dev/null 2>&1 &
fi # ALL_T*_SNRS
rmdir "${LDIR}"

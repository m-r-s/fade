#!/bin/bash
# script for conducting a pre simulation as an estimate of the SRT.

PROJECT="${1}"

# script name and log file
SCN=$(basename "$0")
SLF="${PROJECT}/log/${SCN%.sh}.log"

SNR_ESTIMATE="${2}"
NUM_TRAIN_SAMPLES="${3}"
EAR="${4}"
SAMPLING_RATE="${5}"
TARGET_RECOGNITION_RATE="${6}"

# Constants
PCF="${PROJECT}/config/config.cfg"
source "${PCF}"
PREVIOUS_SNRS="${SNR_ESTIMATE}"
STEP_SIZE="5" # dB
MIN_STEP="3"
ACCURACY="0.15" # Stop if the current rate is within $ACCURACY of the target rate
# NOVER simply copies the recorded files N times to bloat the training and testing material to N+1 times
NOVER="3 3" # 1st value for train, 2nd for test
NUM_TEST_SAMPLES="25" # with nover should be about 100 for a <=1% resolution
PRE_SIM_NUM_OPTIONS="10" # number of options for the names
CRUN=0
COUNTER_ALREADY_THERE=0
ALREADY_THERE_CORRECTION="-1"
PREVIOUS_CORRECTION="0"

# Feature, processing, and their options
OLEN=$(echo "${PO}" | wc -w)
PROC="$(echo "${PO}" | cut -d' ' -f1)"
[ "$OLEN" -gt 1 ] && PROC_OPTS="$(echo "${PO}" | cut -d' ' -f2-)" || PROC_OPTS=''

PRE_SUB="${PROJECT}/sub-pre"

while true; do
  # copy essential parts to the current pre-sub-project
  copy_essentials.sh "${PROJECT}" "${PRE_SUB}-${CRUN}" >> ${SLF}
  # Link/Record speech signals from PROJECT to PROJECT
  link_corpus.sh "${PRE_SUB}-${CRUN}" "${SNR_ESTIMATE}" "${NUM_TRAIN_SAMPLES}" "${SNR_ESTIMATE}" "${NUM_TEST_SAMPLES}" >> ${SLF}
  # process corpus
  preproc_corpus.sh "${PRE_SUB}-${CRUN}" "${EAR}" "${SAMPLING_RATE}" "${PROC}" "${PROC_OPTS}" "${SNR_ESTIMATE}" "${SNR_ESTIMATE}" >> ${SLF} #FIXME! CHECK HERE
  # Use each representation nover times
  copy_overdraw.sh "${PRE_SUB}-${CRUN}" "${NOVER}" >> ${SLF}
  # Run fade from features to evaluation
  fade "${PRE_SUB}-${CRUN}" features ${FO} >> ${SLF}
  [ -d "${PRE_SUB}-${CRUN}/corpus" ]     && mv "${PRE_SUB}-${CRUN}/corpus" "${PRE_SUB}-${CRUN}/corpus.bak"
  [ -d "${PRE_SUB}-${CRUN}/processing" ] && mv "${PRE_SUB}-${CRUN}/processing" "${PRE_SUB}-${CRUN}/processing.bak"
  fade "${PRE_SUB}-${CRUN}" corpus-format >> ${SLF}
  fade "${PRE_SUB}-${CRUN}" training ${TO} >> ${SLF}
  fade "${PRE_SUB}-${CRUN}" recognition ${RO} >> ${SLF}
  fade "${PRE_SUB}-${CRUN}" evaluation >> ${SLF}
  cat "${PRE_SUB}-${CRUN}/evaluation/summary" >> "${PROJECT}/pre-sim-summary"
  # just check for current examied SNR
  RATE=$( cat "${PROJECT}/pre-sim-summary" | tr '_' ' ' | sed 's/snr//g' | awk -v snr=${SNR_ESTIMATE} '{if($2 == snr && $4 == snr) print $6/$5; }' )
  # check if rate is empty, throw error if yes
  [ -e "${RATE}" ] && error "RATE is empty, aborting!" && exit 1
  # check if rate is within proximity of TARGET_RECOGNITION_RATE, break if yes
  BREAK_CONDITION_ONE=$( echo "if abs(${TARGET_RECOGNITION_RATE}-${RATE}) <= ${ACCURACY}; disp(1); else disp(0); end " | run-matlab )
  [ $BREAK_CONDITION_ONE -eq 1 ] && break

  # check if interpolation is possible
  INTERP_QUESTION=0
  if [ $CRUN -gt 0 ]; then
    # checks if there are recognition rates greater and lower than target recognition rate
    RATES=($(cat "${PROJECT}/pre-sim-summary" | tr '_' ' ' | sed 's/snr//g' | awk '{print $6/$5; }'))
    # in will have zeros and ones if there are values greater and lower than TARGET_RECOGNITION_RATE, thus length unique will be 2
    INTERP_QUESTION=$( echo "rrs = [${RATES[@]}]; in = rrs > ${TARGET_RECOGNITION_RATE}; disp(length(unique(in))>1);" | run-matlab )
    echo "DEBUG: INTERPOLATION ALLOWED: $INTERP_QUESTION" >> ${SLF}
  fi

  if [ ${INTERP_QUESTION} -eq 1 ]; then
    # interpolate srt if possible
    # get vector with TRAIN_SNRs, TEST_SNRs, and rates
    TTR_TRAIN=$(cat "${PROJECT}/pre-sim-summary" | tr '_' ' ' | sed 's/snr//g' | awk '{print $2}')
    TTR_TEST=$(cat "${PROJECT}/pre-sim-summary" | tr '_' ' ' | sed 's/snr//g' | awk '{print $4}')
    TTR_RATE=$(cat "${PROJECT}/pre-sim-summary" | tr '_' ' ' | sed 's/snr//g' | awk '{print $6/$5}')
    # interpolate next TRAIN_SNR and TEST_SNR
    SNR_ESTIMATE=$( echo "
          train_snrs = [${TTR_TRAIN}];
          test_snrs = [${TTR_TEST}];
          rr = [${TTR_RATE}];
          interpolate_srt(train_snrs, test_snrs, rr, ${TARGET_RECOGNITION_RATE}); " | run-matlab 'darf')
    echo "DEBUG: SNR_ESTIMATE FROM INTERP: $SNR_ESTIMATE" >> ${SLF}
    # check if recognition rates between 0.25 and 0.75 exist, if so break (i.e., TRAIN_SNR and TEST_SNR were interpolated from these values
    # assumption: nearly linear slope of psychometric function between these two rates
    BREAK_CONDITION_THREE=$( echo "
          test_snrs = [${TTR_TEST}];
          rr = [${TTR_RATE}];
          interpolate_srt_check_rr(test_snrs, rr, ${TARGET_RECOGNITION_RATE}, ${PRE_SIM_NUM_OPTIONS}, ${SNR_ESTIMATE});" | run-matlab 'darf')
    [ $BREAK_CONDITION_THREE -eq 1 ] && break
    #### log the actions
  else
    # Otherwise adapt snr
    CORRECTION=$( echo "disp(round((${TARGET_RECOGNITION_RATE}-${RATE})*5*${STEP_SIZE}))" | run-matlab )
    # only reduce step size if the correction direction has changed
    CDIR=$(echo "disp(sign(${CORRECTION}*${PREVIOUS_CORRECTION}))"  | run-matlab )
    [ ${CDIR} -lt 0 ] && STEP_SIZE=$( echo "disp(ceil(max(${MIN_STEP},${STEP_SIZE}/1.5)))" | run-matlab )
    SNR_ESTIMATE=$( echo "val = round(${SNR_ESTIMATE}+${CORRECTION}); printf('%+03.0f',val); " | run-matlab )
    PREVIOUS_CORRECTION="${CORRECTION}"
    echo "DEBUG: NO INTERPOLATION: $SNR_ESTIMATE" >> ${SLF}
  fi

  # check if SNR was already estimated and look in both directions --> avoids diverge
  ALREADY_THERE=0
  [[ $(rws.sh "${PREVIOUS_SNRS}") = *"${SNR_ESTIMATE}"* ]] && ALREADY_THERE=1
  [ ${ALREADY_THERE} -eq 0 ] || COUNTER_ALREADY_THERE=$((COUNTER_ALREADY_THERE+1))
  while [ ${ALREADY_THERE} -eq 1 ]; do
    SNR_ESTIMATE=$( echo "printf('%+03.0f',${SNR_ESTIMATE} + (${ALREADY_THERE_CORRECTION}))" | run-matlab )
    [[ $(rws.sh "${PREVIOUS_SNRS}") = *"${SNR_ESTIMATE}"* ]] || ALREADY_THERE=0
  done
  ALREADY_THERE_CORRECTION=$( echo "printf('%+1.0f',-(${ALREADY_THERE_CORRECTION}));" | run-matlab )

  # SNR_ESTIMATE=$(echo " if ${SNR_ESTIMATE} > 100; printf('%+03.0f',100); elseif ${SNR_ESTIMATE} < -80; printf('%+03.0f',-80); else printf('%+03.0f',${SNR_ESTIMATE}); end" | run-matlab )
  SNR_ESTIMATE=$(echo "snr_est = min(max(${SNR_ESTIMATE},-80),100); printf('%+03.0f', snr_est);" | run-matlab )
  PREVIOUS_SNRS="${PREVIOUS_SNRS} ${SNR_ESTIMATE}"
  [ ${COUNTER_ALREADY_THERE} -gt 4 ] && break # if this has to be done several times, the SRT should be somewhere around there
  echo "ESTIMATE AT END: ${SNR_ESTIMATE}" >> $SLF
  CRUN=$((CRUN + 1))
done
echo "${SNR_ESTIMATE}"

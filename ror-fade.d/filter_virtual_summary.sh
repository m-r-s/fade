#!/bin/bash

# creates summary where all conditions come from the "virtual" snrs, i.e., where the features were extracted from higher and lower snrs to artificially create the snr
# currently the stepsize is hard coded (6 dB), see line 16 & 17.

PROJECT="${1}"
TRAIN_STEP="${2}"
SUMMARY="${PROJECT}/evaluation/summary"
NSUMMARY="${PROJECT}/evaluation/normal-summary"
VSUMMARY="${PROJECT}/evaluation/virt-summary"
RSUMMARY="${PROJECT}/evaluation/real-summary"


[ -f "${NSUMMARY}" ] && mv "${NSUMMARY}" "${SUMMARY}"
if [ -f "${SUMMARY}" ] ; then
  mv "${PROJECT}/evaluation/summary" ${NSUMMARY}
  TRAIN_CONDITTIONS=$(cat "${NSUMMARY}" | sed 's/snr/snr /g' | awk '{print $1}' | sort -u)
  TRAIN_SNRS=$(cat "${NSUMMARY}" | sed 's/snr/snr /g' | awk '{print $2}' | sort -u)
  REAL_SNRS=$( echo "SNR = sort([${TRAIN_SNRS}]); printf('%+03.0f ', SNR(1:2:end));" | run-matlab )
  VIRT_SNRS=$( echo "SNR = sort([${TRAIN_SNRS}]); printf('%+03.0f ', SNR(2:2:end-1));" | run-matlab )
  [ -f "${RSUMMARY}" ] && rm "${RSUMMARY}"
  [ -f "${VSUMMARY}" ] && rm "${VSUMMARY}"
  for icond in $TRAIN_CONDITTIONS; do
    for ireal in $REAL_SNRS; do
      cat "${NSUMMARY}" | awk -v cond="${icond}${ireal}" '$1==cond {print}' >> "${RSUMMARY}"
    done
    for ivirt in $VIRT_SNRS; do
      cat "${NSUMMARY}" | awk -v cond="${icond}${ivirt}" '$1==cond {print}' >> "${VSUMMARY}"
    done
  done
  cp "${VSUMMARY}" "${SUMMARY}"
fi

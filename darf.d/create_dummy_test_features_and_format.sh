#!/bin/bash

SUB_PROJECT="${1}"

# make temporary fork of project
TMP_PROJECT=$(mktemp -u /dev/shm/fade-pr.XXXXXXXXXXXXX)
fade "${SUB_PROJECT}" fork "${TMP_PROJECT}"

# features training dir
FTD="${TMP_PROJECT}/features/train"
# features test dir
FED="${TMP_PROJECT}/features/test"

# backup corpus and processing dirs to have corpus-format run on features dir
[ -d "${TMP_PROJECT}/corpus"     ] && rm -r "${TMP_PROJECT}/corpus"
[ -d "${TMP_PROJECT}/processing" ] && rm -r "${TMP_PROJECT}/processing"

# create dummy condition list for the project
NOISE=($(basename $(find "${FTD}" -maxdepth 1 -mindepth 1)))
[ -d "${FED}/${NOISE}/snr-inf/rep00" ] || mkdir -p "${FED}/${NOISE}/snr-inf/rep00"
[ -f "${FED}/${NOISE}/snr-inf/rep00/nan.htk" ] || touch "${FED}/${NOISE}/snr-inf/rep00/nan.htk"

fade "${TMP_PROJECT}" corpus-format
rm -r "${SUB_PROJECT}/config"
cp -r "${TMP_PROJECT}/config" "${SUB_PROJECT}"
rm -r "${TMP_PROJECT}"
sleep 1

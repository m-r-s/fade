#!/bin/bash
# with prefered list
PROJECT=$1
TRAIN_SNRS=($2)
NUM_TRAIN_SAMPLES=$3
TEST_SNRS=($4)
NUM_TEST_SAMPLES=$5

PREF_TEST_ITEMS=($(pick_list.sh))
echo ""
echo "Generating corpus for snrs..."
TRAIN_SAMPLES=120
TEST_SAMPLES=120
TRAIN='[]'
TEST='[]'
[ "${NUM_TRAIN_SAMPLES}" -lt "${TRAIN_SAMPLES}" ] || TRAIN_SAMPLES="${NUM_TRAIN_SAMPLES}"
[ "${NUM_TEST_SAMPLES}" -lt "${TEST_SAMPLES}" ] || TEST_SAMPLES="${NUM_TEST_SAMPLES}"
[ -z ${TRAIN_SNRS[0]} ] || TRAIN=$(echo "[${TRAIN_SNRS[@]}]" | tr ' ' ',')
[ -z ${TEST_SNRS[0]} ] || TEST=$(echo "[${TEST_SNRS[@]}]" | tr ' ' ',')
fade ${PROJECT} corpus-matrix ${TRAIN_SAMPLES} ${TEST_SAMPLES}
sed -i '/SNRS/d' "${PROJECT}/config/corpus/generate.cfg"
{
  echo "TRAIN_SNRS='${TRAIN}'"
  echo "TEST_SNRS='${TEST}'"
} >> "${PROJECT}/config/corpus/generate.cfg"

fade ${PROJECT} corpus-generate
mv "${PROJECT}/corpus" "${PROJECT}/corpus-all"

# Link all files of TRAIN_SNRS
[ -z ${TRAIN_SNRS[0]} ] || for itrainsnr in ${TRAIN_SNRS[@]}; do
  TRAIN_FILES=($(find -L "${PROJECT}/corpus-all/train" -type f -iname '*.wav' | grep -w "snr${itrainsnr}" ))
  RFILES=$(shuf --input-range=0-$(( ${#TRAIN_FILES[*]} - 1 )) -n ${NUM_TRAIN_SAMPLES})
  for index in ${RFILES[@]}; do
    TARGET="${TRAIN_FILES[$index]//corpus-all/corpus}"
    TDIR=$(dirname ${TARGET})
    [ -d "${TDIR}" ] || mkdir --parents "${TDIR}" # --parents flag resolvs problem with missing subdirs
    [ -f "${TARGET}" ] || ln -s -r "${TRAIN_FILES[$index]}" "${TARGET}" # give absolute file path, create if it does not exist
  done
done

# Link all files of TEST_SNRS
[ -z ${TEST_SNRS[0]} ] || for itestsnr in ${TEST_SNRS[@]}; do
  TEST_FILE_PATH=$(find -L "${PROJECT}/corpus-all/test" -type f -iname '*.wav' | grep -w "snr${itestsnr}" | head -n 1 | sed 's/[0-9]\{5\}\.wav$//')
  for ipref in ${PREF_TEST_ITEMS[@]}; do
    SOURCE="${TEST_FILE_PATH}${ipref}.wav"
    TARGET="${SOURCE//corpus-all/corpus}"
    TDIR=$(dirname ${TARGET})
    [ -d "${TDIR}" ] || mkdir --parents "${TDIR}" # --parents flag resolvs problem with missing subdirs
    [ -f "${TARGET}" ] || ln -s -r "${SOURCE}" "${TARGET}"
  done
done

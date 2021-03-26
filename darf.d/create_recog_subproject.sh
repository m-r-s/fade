#!/bin/bash

[ -n "$1" ] && PROJECT="${1}"
[ -n "$2" ] && NEW_TRAIN_SNRS=(${2})
[ -n "$3" ] && NEW_TEST_SNRS=(${3})

# ESC_PROJECT=$(echo "${PROJECT}" | sed 's/\//\\\//g')
# NOISE=$(ls "${PROJECT}"/source/noise/*.wav)

# zero indexed sub project files
NUM_RECOG_SUBS=$(find "${PROJECT}" -mindepth 1 -maxdepth 1 -iwholename "*/sub-main-recog-*" | wc -l)
SPR="${PROJECT}/sub-main-recog-${NUM_RECOG_SUBS}"
copy_essentials.sh "${PROJECT}" "${SPR}" >> "${PROJECT}/log/copy_essentials.log"


# Train SNRs
[ -d "${SPR}/training" ] || mkdir "${SPR}/training"
[ -d "${SPR}/features" ] || mkdir "${SPR}/features"
for itrain in ${NEW_TRAIN_SNRS[@]} ; do
  # this may return/find just be ONE folder with that SNR for training
  NEW_TRAIN_DIRS=$(find "${PROJECT}" -mindepth 3 -maxdepth 3 -iwholename "*sub-main-*training*snr${itrain}" | sed '/-recog-/d')
  TARGET="$(echo ${NEW_TRAIN_DIRS} | sed -E "s/.*sub-main-[0-9]*//g" | awk -v sp="${SPR}" '{print sp$1}')"
  ln -s -r "${NEW_TRAIN_DIRS}" "${TARGET}"

  # link training features. This is required to run corpus-format
  #   Other implementation could would require to merge existing format lists,
  #   but this is much simpler
  # get features dir of sub project that includes the training snrs
  # SOURCE=$(echo "${NEW_TRAIN_DIRS}" | sed -e "s/${ESC_PROJECT}\///g" | sed -E -e "s/\/.*$/\/features/g" | awk -v sp="${PROJECT}" -v tar="${NOISE}/snr${itrain}" '{print sp"/"$1"/train/"tar}')
  # TARGET="${SPR}/features/train/${NOISE}/snr${itrain}"
  SOURCE=$(find "${PROJECT}" -mindepth 5 -maxdepth 5 -iwholename "*sub-main-*features*train*snr${itrain}" | sed '/-recog-/d')
  TARGET="$(echo ${SOURCE} | sed -E "s/.*sub-main-[0-9]*//g" | awk -v sp="${SPR}" '{print sp$1}')"
  [ -d $(dirname "${TARGET}") ] || mkdir -p $(dirname "${TARGET}")
  ln -s -r "${SOURCE}" "${TARGET}"
done

# Test SNRs
for itest in ${NEW_TEST_SNRS[@]} ; do
  # this may return/find just be ONE folder with that SNR for training
  SOURCE=$(find "${PROJECT}" -mindepth 5 -maxdepth 5 -iwholename "*sub-main-*features*test*snr${itest}" | sed '/-recog-/d')
  TARGET="$(echo ${SOURCE} | sed -E "s/.*sub-main-[0-9]*//g" | awk -v sp="${SPR}" '{print sp$1}')"
  [ -d $(dirname "${TARGET}") ] || mkdir -p $(dirname "${TARGET}")
  ln -s -r "${SOURCE}" "${TARGET}"
done

# Run corpus format for the sub project
[ -d "${SPR}/corpus" ]     && mv "${SPR}/corpus" "${SPR}/corpus.bak"
[ -d "${SPR}/processing" ] && mv "${SPR}/processing" "${SPR}/processing.bak"
fade "${SPR}" corpus-format >> "${PROJECT}/log/q_recog.log"

# Return subproject name
echo "${SPR}"

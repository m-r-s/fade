#!/bin/bash

PROJECT="${1}"
SUB_PROJECT="${2}"
TRAIN_SNRS=($3)

IFS=$'\n' TRAIN_SNRS=($(sort -n <<<"${TRAIN_SNRS[*]}"))

if [ -d "${SUB_PROJECT}/processing" ]; then
  SCD="${SUB_PROJECT}/processing"
  FILTER="processing"
else
  SCD="${SUB_PROJECT}/corpus"
  FILTER="corpus"
fi

# get all existing "virtual" projects
VIRTUAL_SNR_DIRS=($(find "${PROJECT}" -regextype posix-extended -regex ".*${FILTER}.*replo.*|.*${FILTER}.*rephi.*" |  sed -e 's/\/rep.*$//g' | sort -u))
NOISE=$(ls -1 "${SCD}/train")
SND="${SCD}/train/${NOISE}"

# Link all files of TRAIN_SNRS
COUNTER=0
for ((isnr=1; isnr<${#TRAIN_SNRS[@]}; isnr++)); do
  A=${TRAIN_SNRS[${isnr}-1]}
  B=${TRAIN_SNRS[${isnr}]}
  VIRTUAL_SNR=$(echo "val = abs(${A} - ${B})/2 + min(${A},${B}); fprintf('%+03d\n',val)" | run-matlab )

  # skip the virtual snr if it already exists
  VSD="${SND}/snr${VIRTUAL_SNR}"
  VSD_ALREADY_EXISTS=$(echo "${VIRTUAL_SNR_DIRS[@]}" | grep -c "snr${VIRTUAL_SNR}")
  if [ "${VSD_ALREADY_EXISTS}" == "0" ] ; then
    COUNTER=$((COUNTER+1))
    VIRTUAL_SNRS[COUNTER]=${VIRTUAL_SNR}
    TRAIN_DIRS_HI=($(find "${PROJECT}" -mindepth 6 -maxdepth 6 -iwholename "*${FILTER}*snr${B}/rep*" | sed -e '/\/rephi/d' -e '/\/replo/d'))
    TRAIN_DIRS_LO=($(find "${PROJECT}" -mindepth 6 -maxdepth 6 -iwholename "*${FILTER}*snr${A}/rep*" | sed -e '/\/rephi/d' -e '/\/replo/d'))

    [ -d ${VSD} ] || mkdir ${VSD}
    for ((index=0;index<${#TRAIN_DIRS_HI[@]};index++)); do
      SOURCE_HI=$( echo "${TRAIN_DIRS_HI[$index]}" )
      TARGET_HI=$( echo "${TRAIN_DIRS_HI[$index]}" | \
                    sed -e "s/\/rep/\/rephi/g"  -e "s/\/snr${B}/\/snr${VIRTUAL_SNR}/g" | \
                    sed -E "s/^.*sub-main-[0-9]*//g" | \
                    awk -v sp="${SUB_PROJECT}" '{print sp$1}')
      ln -s -r "${SOURCE_HI}" "${TARGET_HI}"
    done

    for ((index=0;index<${#TRAIN_DIRS_LO[@]};index++)); do
      SOURCE_LO=$( echo "${TRAIN_DIRS_LO[$index]}" )
      TARGET_LO=$( echo "${TRAIN_DIRS_LO[$index]}" | \
                    sed -e "s/\/rep/\/replo/g" -e "s/\/snr${A}/\/snr${VIRTUAL_SNR}/g" | \
                    sed -E "s/^.*sub-main-[0-9]*//g" | \
                    awk -v sp="${SUB_PROJECT}" '{print sp$1}')
      ln -s -r "${SOURCE_LO}" "${TARGET_LO}"
    done
  fi
done
echo "${VIRTUAL_SNRS[@]}"

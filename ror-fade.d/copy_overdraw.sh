#!/bin/bash

PROJECT=$1
NOVER=($2)

NOISE=$(ls "${PROJECT}/corpus/train/" | tr '_' '-')

if [ -d "${PROJECT}/processing" ]; then
  PCD="${PROJECT}/processing"
else
  PCD="${PROJECT}/corpus"
fi

TRAINSNRS=$( ls -1 "${PCD}/train/${NOISE}/")
TESTSNRS=$( ls -1 "${PCD}/test/${NOISE}/")

# Link all files of trainsnrs
for itrain in ${TRAINSNRS[@]}; do
  REPS=$( find "${PCD}/train/${NOISE}/${itrain}/" -maxdepth 1 -mindepth 1 | sed '/virtual/d' )
  for ir in ${REPS[@]}; do
    for ((iover=1; iover<${NOVER[0]}+1;iover++)); do
      TARGET="${ir}_virtual_${iover}"
      [ -d "${TARGET}" ] || ln -s -r "${ir}" "${TARGET}"
    done
  done
done

# Link all files of testsnrs
for itest in ${TESTSNRS[@]}; do
  REPS=$( find "${PCD}/test/${NOISE}/${itest}/" -maxdepth 1 -mindepth 1 | sed '/virtual/d' )
  for ir in ${REPS[@]}; do
    for ((iover=1; iover<${NOVER[1]}+1;iover++)); do
      TARGET="${ir}_virtual_${iover}"
      [ -d "${TARGET}" ] || ln -s -r "${ir}" "${TARGET}"
    done
  done
done

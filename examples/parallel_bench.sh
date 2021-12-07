#!/bin/bash
#
# Copyright (C) 2014-2018 Marc René Schädler

# Get the directory this script is stored in and its name
DIR=$(cd "$( dirname "$0" )" && pwd)
SCN=$(basename "$0")

PROJECT="$1"
shift
THREADS=("${@}")

echo "CORPUS"
BEST_TIME=""
for ((I=0;$I<${#THREADS[@]};I++)); do
  TRY_CORPUS_THREADS=${THREADS[$I]}
  echo "trying with (max) ${TRY_CORPUS_THREADS} threads"
  fade "${PROJECT}" parallel "$TRY_CORPUS_THREADS" 1 1 1 1 > /dev/null
  [ -e "${PROJECT}/corpus" ] && rm -r "${PROJECT}/corpus"   
  STARTTIME=$(date +%s)
  fade "${PROJECT}" corpus-generate > /dev/null
  STOPTIME=$(date +%s)
  TIME=$((STOPTIME-STARTTIME))
  if [ -z "$BEST_TIME" ] || [ $TIME -lt $BEST_TIME ]; then
    echo "new best time ${TIME}s with ${TRY_CORPUS_THREADS} threads"
    BEST_TIME=$TIME
    CORPUS_THREADS=$TRY_CORPUS_THREADS
  else
    echo "${TIME}s with ${TRY_CORPUS_THREADS} threads"
  fi
done

echo "PROCESSING"
BEST_TIME=""
for ((I=0;$I<${#THREADS[@]};I++)); do
  TRY_PROCESSING_THREADS=${THREADS[$I]}
  echo "trying with (max) ${TRY_PROCESSING_THREADS} threads"
  fade "${PROJECT}" parallel 1 "$TRY_PROCESSING_THREADS" 1 1 1 > /dev/null
  [ -e "${PROJECT}/processing" ] && rm -r "${PROJECT}/processing"   
  STARTTIME=$(date +%s)
  fade "${PROJECT}" processing > /dev/null
  STOPTIME=$(date +%s)
  TIME=$[$STOPTIME-$STARTTIME]
  if [ -z "$BEST_TIME" ] || [ $TIME -lt $BEST_TIME ]; then
    echo "new best time ${TIME}s with ${TRY_PROCESSING_THREADS} threads"
    BEST_TIME=$TIME
    PROCESSING_THREADS=$TRY_PROCESSING_THREADS
  else
    echo "${TIME}s with ${TRY_PROCESSING_THREADS} threads"
  fi
done

echo "FEATURES"
BEST_TIME=""
for ((I=0;$I<${#THREADS[@]};I++)); do
  TRY_FEATURES_THREADS=${THREADS[$I]}
  echo "trying with (max) ${TRY_FEATURES_THREADS} threads"
  fade "${PROJECT}" parallel 1 1 "$TRY_FEATURES_THREADS" 1 1 > /dev/null
  [ -e "${PROJECT}/features" ] && rm -r "${PROJECT}/features"   
  STARTTIME=$(date +%s)
  fade "${PROJECT}" features > /dev/null
  STOPTIME=$(date +%s)
  TIME=$[$STOPTIME-$STARTTIME]
  if [ -z "$BEST_TIME" ] || [ $TIME -lt $BEST_TIME ]; then
    echo "new best time ${TIME}s with ${TRY_FEATURES_THREADS} threads"
    BEST_TIME=$TIME
    FEATURES_THREADS=$TRY_FEATURES_THREADS
  else
    echo "${TIME}s with ${TRY_FEATURES_THREADS} threads"
  fi
done

fade "${PROJECT}" corpus-format > /dev/null

echo "TRAINING"
BEST_TIME=""
for ((I=0;$I<${#THREADS[@]};I++)); do
  TRY_TRAINING_THREADS=${THREADS[$I]}
  echo "trying with (max) ${TRY_TRAINING_THREADS} threads"
  fade "${PROJECT}" parallel 1 1 1 "$TRY_TRAINING_THREADS" 1 > /dev/null
  [ -e "${PROJECT}/training" ] && rm -r "${PROJECT}/training"   
  STARTTIME=$(date +%s)
  fade "${PROJECT}" training > /dev/null
  STOPTIME=$(date +%s)
  TIME=$[$STOPTIME-$STARTTIME]
  if [ -z "$BEST_TIME" ] || [ $TIME -lt $BEST_TIME ]; then
    echo "new best time ${TIME}s with ${TRY_TRAINING_THREADS} threads"
    BEST_TIME=$TIME
    TRAINING_THREADS=$TRY_TRAINING_THREADS
  else
    echo "${TIME}s with ${TRY_TRAINING_THREADS} threads"
  fi
done

echo "RECOGNITION"
TRY_RECOGNITION_THREADS=1
BEST_TIME=""
for ((I=0;$I<${#THREADS[@]};I++)); do
  TRY_RECOGNITION_THREADS=${THREADS[$I]}
  echo "trying with (max) ${TRY_RECOGNITION_THREADS} threads"
  fade "${PROJECT}" parallel 1 1 1 1 "$TRY_RECOGNITION_THREADS" > /dev/null
  [ -e "${PROJECT}/recognition" ] && rm -r "${PROJECT}/recognition"   
  STARTTIME=$(date +%s)
  fade "${PROJECT}" recognition > /dev/null
  STOPTIME=$(date +%s)
  TIME=$[$STOPTIME-$STARTTIME]
  if [ -z "$BEST_TIME" ] || [ $TIME -lt $BEST_TIME ]; then
    echo "new best time ${TIME}s with ${TRY_RECOGNITION_THREADS} threads"
    BEST_TIME=$TIME
    RECOGNITION_THREADS=$TRY_RECOGNITION_THREADS
  else
    echo "${TIME}s with ${TRY_RECOGNITION_THREADS} threads"
  fi
done

echo "FINISHED"

fade "${PROJECT}" parallel $CORPUS_THREADS $PROCESSING_THREADS $FEATURES_THREADS $TRAINING_THREADS $RECOGNITION_THREADS


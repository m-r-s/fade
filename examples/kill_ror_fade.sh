#!/bin/bash

SCRIPTS=(
   ror-fade
   # main scripts
   q_pre_simulation.sh
   q_record.sh
   q_features.sh
   q_train.sh
   q_recog.sh
   q_break_or_adjust.sh
   # scripts
   corpus-generate
   processing
   training
   recognition
   evaluation
   figures
  )

for ((ii=0; ii<${#SCRIPTS[@]} ; ii++)) ; do
  script="${SCRIPTS[$ii]}"
  PID=$(pidof -x "$script")
  [ -z "${PID}" ] || (
    kill ${PID}
    echo "killed ${script}"
    )
done

#!/bin/bash
#
# This script runs the parameter exploration
#

PROJECTS_PATH="$1"
TYPE="$2"
FEATURE="$3"

if [ $# -lt 3 ]; then
  echo "Usage: $0 PROJECTS_PATH TYPE FEATURE"
  echo ""
  echo "  Run the parameter exploration in PROJECTS_PATH"
  echo "  PROJECTS_PATH must contain a prepared project called TYPE"
  echo "  TYPE can be 'matrix' or 'stimulus'"
  echo "  The exploration is performed using FEATURE as the front-end"
  echo ""
  exit 1
fi

# Baseline parameters
TRAIN_SAMPLES_BASE=96
TEST_SAMPLES_BASE=600
STATES_BASE=6
SPECIAL_STATES_BASE=6
MIXTURES_BASE=1
ITERATIONS_BASE=8

# Variations to baseline
TRAIN_SAMPLES=(12 24 48 96 192 384)
STATES=(1 2 3 4 6 8 12 16 24)
SPECIAL_STATES=(1 2 3 4 6 8 12 16 24)
ITERATIONS=(1 2 3 4 6 8 12 16 24)

# Get project path and create it
mkdir -p "${PROJECTS_PATH}" || exit 1

run_experiment() {
  local PROJECTS_PATH="$1" 
  local TYPE="$2"
  local FEATURE="$3"
  local TRAIN_SAMPLE="$4"
  local TEST_SAMPLE="$5"
  local STATE="$6"
  local SPECIAL_STATE="$7"
  local MIXTURE="$8"
  local ITERATION="$9"

  # Type specific factors to get the correct sample size
  case ${TYPE} in
    matrix)
      local TRAIN_FACTOR=10
      local TEST_DIVISOR=5
    ;;
    stimulus)
      local TRAIN_FACTOR=1
      local TEST_DIVISOR=2
    ;;
  esac

  local BASE_PROJECT="${PROJECTS_PATH}/${TYPE}"
  local CORPUS_PROJECT="${BASE_PROJECT}-corpus-${TRAIN_SAMPLE}-${TEST_SAMPLE}"
  local FEATURE_PROJECT="${CORPUS_PROJECT}-features-${FEATURE}"
  local PROJECT="${FEATURE_PROJECT}-run-${STATE}-${SPECIAL_STATE}-${MIXTURE}-${ITERATION}"

  if [ ! -e "${PROJECT}" ]; then
    echo "Generate project '${STATE}-${SPECIAL_STATE}-${MIXTURE}-${ITERATION}'"
    if [ ! -e "${FEATURE_PROJECT}" ]; then
      echo "Generate missing features project '${FEATURE}'"
      if [ ! -e "${CORPUS_PROJECT}" ]; then
        echo "Generate missing corpus project '${TYPE}'"
        if [ ! -e "${BASE_PROJECT}" ]; then
          echo "Base project '${BASE_PROJECT}' does not exist. Create it!"
          return 1
        fi
        fade "${BASE_PROJECT}" fork "${CORPUS_PROJECT}" || return 1
        fade "${CORPUS_PROJECT}" "corpus-${TYPE}" "$[${TRAIN_SAMPLE}*${TRAIN_FACTOR}]" "$[${TEST_SAMPLE}/${TEST_DIVISOR}]" || return 1
        fade "${CORPUS_PROJECT}" corpus-generate || return 1
        fade "${CORPUS_PROJECT}" corpus-format || return 1
      fi
      fade "${CORPUS_PROJECT}" fork "${FEATURE_PROJECT}" || return 1
      fade "${FEATURE_PROJECT}" features "${FEATURE}" || return 1
    fi
    fade "${FEATURE_PROJECT}" fork "${PROJECT}" || return 1
    fade "${PROJECT}" training "${STATE}" "${SPECIAL_STATE}" "${MIXTURE}" "${ITERATION}" && \
      fade "${PROJECT}" recognition && \
      fade "${PROJECT}" evaluation && \
      fade "${PROJECT}" figures
  fi
}

# Baseline
run_experiment "${PROJECTS_PATH}" \
  "${TYPE}" \
  "${FEATURE}" \
  "${TRAIN_SAMPLES_BASE}" \
  "${TEST_SAMPLES_BASE}" \
  "${STATES_BASE}" \
  "${SPECIAL_STATES_BASE}" \
  "${MIXTURES_BASE}" \
  "${ITERATIONS_BASE}" || exit 1

# State dependency
for STATE in ${STATES[@]}; do
  run_experiment "${PROJECTS_PATH}" \
    "${TYPE}" \
    "${FEATURE}" \
    "${TRAIN_SAMPLES_BASE}" \
    "${TEST_SAMPLES_BASE}" \
    "${STATE}" \
    "${SPECIAL_STATES_BASE}" \
    "${MIXTURES_BASE}" \
    "${ITERATIONS_BASE}" || exit 1
done

# Special state dependency
for SPECIAL_STATE in ${SPECIAL_STATES[@]}; do
  run_experiment "${PROJECTS_PATH}" \
    "${TYPE}" \
    "${FEATURE}" \
    "${TRAIN_SAMPLES_BASE}" \
    "${TEST_SAMPLES_BASE}" \
    "${STATES_BASE}" \
    "${SPECIAL_STATE}" \
    "${MIXTURES_BASE}" \
    "${ITERATIONS_BASE}" || exit 1
done

# Iteration dependency
for ITERATION in ${ITERATIONS[@]}; do
  run_experiment "${PROJECTS_PATH}" \
    "${TYPE}" \
    "${FEATURE}" \
    "${TRAIN_SAMPLES_BASE}" \
    "${TEST_SAMPLES_BASE}" \
    "${STATES_BASE}" \
    "${SPECIAL_STATES_BASE}" \
    "${MIXTURES_BASE}" \
    "${ITERATION}" || exit 1
done

# Train data amount dependency
for TRAIN_SAMPLE in ${TRAIN_SAMPLES[@]}; do
  run_experiment "${PROJECTS_PATH}" \
    "${TYPE}" \
    "${FEATURE}" \
    "${TRAIN_SAMPLE}" \
    "${TEST_SAMPLES_BASE}" \
    "${STATES_BASE}" \
    "${SPECIAL_STATES_BASE}" \
    "${MIXTURES_BASE}" \
    "${ITERATIONS_BASE}" || exit 1
done


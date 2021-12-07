#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 PROJECT [START]"
  echo ""
  echo "  Will complete PROJECT using standard parameters."
  echo "  An additional START point can be specified which will overwrite the"
  echo "  specified step and all following steps."
  echo "  Available steps are: corpus processing features training recognition evaluation figures"
  echo ""
  exit 1
fi

# Get arguments
PROJECT="$1"
START="$2"

STEPS=(parallel corpus processing features training recognition evaluation figures)
STARTED=false

[ -n "$START" ] || START=parallel

for STEP in ${STEPS[@]}; do
  [ "$START" == "$STEP" ] && STARTED=true
  if ${STARTED}; then
    case "$STEP" in
      corpus|corpus-generate)
        fade "$PROJECT" corpus-generate || exit 1
      ;;
      training)
        fade "$PROJECT" corpus-format || exit 1
        fade "$PROJECT" training || exit 1
      ;;
      *)
        fade "$PROJECT" "$STEP" || exit 1
      ;;
    esac
  fi
done



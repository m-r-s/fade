#!/bin/bash

PROJECT="${1}"
TARGET="${2}"

FILTER="sub"

echo "creating subproject '${TARGET}'"
if ! (mkdir -p "${TARGET}"); then
  echo "could not create '${TARGET}'"
  exit 1
fi

# create filelist WITHOUT any sub projects
FILELIST=($(find "${PROJECT}" -mindepth 1 -maxdepth 1 | sed -e '/sub/d' -e '/jobs/d'))
for FULLFILENAME in ${FILELIST[@]}; do
  FILENAME=$(basename "${FULLFILENAME}")
  case "${FILENAME}" in
    .*|log|config)
      echo "copy '${FILENAME}'"
      cp -L -r "${FULLFILENAME}" "${TARGET}/${FILENAME}"
    ;;
    *)
      echo "link '${FILENAME}'"
      ln -s "${FULLFILENAME}" "${TARGET}/${FILENAME}"
  esac
done

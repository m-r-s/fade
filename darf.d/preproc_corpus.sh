#!/bin/bash

PROJECT="${1}"
EAR="${2}"
SAMPLING_RATE="${3}"
PROCESSING="${4}"
PROC_OPTS="${5}"
TRAIN_SNR="${6}"
TEST_SNR="${7}"

# Select ear
[ "${EAR}" = "m" ] && echo "Generate mono signals (ear '${EAR}')"
[ "${EAR}" = "l" ] && echo "Generate stereo signals (left, ear '${EAR}')"
[ "${EAR}" = "r" ] && echo "Generate stereo signals (right, ear '${EAR}')"
[ "${EAR}" = "b" ] && echo "Generate stereo signals (binaural, ear '${EAR}')"
[ -f "${PROJECT}/config/corpuslist.txt" ] && rm "${PROJECT}/config/corpuslist.txt"
for itrain in ${TRAIN_SNR} ; do
  (cd "${PROJECT}/corpus" && find -L -iname '*.wav' | grep "train" | grep "snr${itrain}") >> "${PROJECT}/config/corpuslist.txt"
done
for itest in ${TEST_SNR} ; do
  (cd "${PROJECT}/corpus" && find -L -iname '*.wav' | grep "test"  | grep "snr${itest}") >> "${PROJECT}/config/corpuslist.txt"
done
echo "progress = '0123456789#';
      ear = '${EAR}';
      filelist = strsplit(fileread('${PROJECT}/config/corpuslist.txt'),'\n');
      numfiles = length(filelist);
      for i=1:numfiles
        if ~isempty(filelist{i})
          filename=['${PROJECT}/corpus/' filelist{i}];
          [signal, fs]=audioread(filename);
          if fs ~= ${SAMPLING_RATE}
            signal = resample(signal, ${SAMPLING_RATE}, fs);
          end
          if size(signal,2) < 2
            switch ear
              case 'l'
                signal = [signal, zeros(size(signal))];
              case 'r'
                signal = [zeros(size(signal)), signal];
              case 'b'
                signal = [signal, signal];
              case 'm'
                signal = [signal];
              otherwise
                error('unknown ear definition (l/r/b/m)');
            end
          end
          audiowrite(filename, signal, ${SAMPLING_RATE}, 'BitsPerSample', 32);
          printf('%s',progress(1+floor(10.*i./numfiles)));
        end
      end
      printf('\nfinished\n');" | run-matlab
# Perform signal processing
fade "$PROJECT" processing "$PROCESSING" ${PROC_OPTS[@]}
wait

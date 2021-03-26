#!/bin/bash

# invoke this script with `watch observe_fast_fade.sh`

pidof -x darf &>/dev/null             && echo "1: darf             runs" || echo "0: darf             not"
echo ""
pidof -x q_pre_simulation.sh &>/dev/null  && echo "1: q_pre_simulation.sh  runs" || echo "0: q_pre_simulation.sh  not"
pidof -x q_record.sh &>/dev/null          && echo "1: q_record.sh          runs" || echo "0: q_record.sh          not"
pidof -x q_features.sh &>/dev/null        && echo "1: q_features.sh        runs" || echo "0: q_features.sh        not"
pidof -x q_train.sh &>/dev/null           && echo "1: q_train.sh           runs" || echo "0: q_train.sh           not"
pidof -x q_recog.sh &>/dev/null           && echo "1: q_recog.sh           runs" || echo "0: q_recog.sh           not"
pidof -x q_break_or_adjust.sh &>/dev/null && echo "1: q_break_or_adjust.sh runs" || echo "0: q_break_or_adjust.sh not"
echo ""
pidof -x corpus-generate &>/dev/null      && echo "1: corpus-generate      runs" || echo "0: corpus-generate      not"
pidof -x processing &>/dev/null           && echo "1: processing           runs" || echo "0: processing           not"
pidof -x training &>/dev/null             && echo "1: training             runs" || echo "0: training             not"
pidof -x recognition &>/dev/null          && echo "1: recognition          runs" || echo "0: recognition          not"
pidof -x evaluation &>/dev/null           && echo "1: evaluation           runs" || echo "0: evaluation           not"
pidof -x figures &>/dev/null              && echo "1: figures              runs" || echo "0: figures              not"

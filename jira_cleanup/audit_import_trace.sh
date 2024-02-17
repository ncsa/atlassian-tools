#!/usr/bin/bash

BASE=~/atlassian/import-testing
RESULTS_DIR=$( ls "${BASE}" | tail -1 )
TRACE=$( ls "${BASE}"/"${RESULTS_DIR}"/import-trace-*.txt )
REPORT=$( ls "${BASE}"/"${RESULTS_DIR}"/import-results-*.txt )

# awk "
# /Data import for project/ {print}
# /The project import created/ {print}
# " "${TRACE}"

awk '
/Data import for project/ {
  printf "%s ", $0
}
/Number of created issues/ {
  printf "%d\n", $5
}
' "${REPORT}" | sort

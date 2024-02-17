#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

HOSTS=/etc/hosts
[[ $DEBUG -eq $YES ]] && HOSTS=$(mktemp)

grep -q smtp "$HOSTS" || {
>>"$HOSTS" cat <<ENDHERE
10.0.0.1 smtp.ncsa.uiuc.edu smtp.ncsa.illinois.edu smtp
10.0.0.1 outlook.office365.com outlook
ENDHERE
}

[[ $DEBUG -eq $YES ]] && rm "$HOSTS"

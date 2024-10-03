#!/bin/bash

BASE=${HOME}/atlassian-tools
BIN="$BASE"/bin

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action=echo

$action certbot certonly -v -n \
  --standalone \
  -d ${HOSTNAME_NEW}

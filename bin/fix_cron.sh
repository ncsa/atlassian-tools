#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

# Prevent cron jobs
TMP=$( mktemp )
crontab -l | sed -e 's/^/#/' >$TMP
if [[ $DEBUG -eq $YES ]] ; then
  cat $TMP
else
  crontab - <$TMP
fi
rm $TMP

#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

MAINT_FILE=/var/www/maintenance/start_maint
ACTION=''
ECHO=''

[[ $VERBOSE -eq $YES ]] && set -x

[[ $DEBUG -eq $YES ]] && ECHO="echo"

param=$1
case ${param} in
  (enable)
    ACTION=rm
    ;;
  (disable)
    ACTION=touch
    ;;
  (*)
    die "missing or unknown param '$param'"
    ;;
esac

$ECHO $ACTION $MAINT_FILE \
  && success "${param} web access" \
  || err "${param} web access"

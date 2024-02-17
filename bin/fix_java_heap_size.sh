#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

SETENV="${APP_INSTALL_DIR}"/bin/setenv.sh
[[ -f "$SETENV" ]] || die "File not found, SETENV: '$SETENV'"

sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts


if [[ ${APP_NAME} == "jira" ]] ; then
  sed "${sed_opts[@]}" \
    -e '/^JVM_MINIMUM_MEMORY=/ c JVM_MINIMUM_MEMORY="2048m"' \
    -e '/^JVM_MAXIMUM_MEMORY=/ c JVM_MAXIMUM_MEMORY="4096m"' \
    "${SETENV}"

elif [[ ${APP_NAME} == "confluence" ]] ; then
  sed "${sed_opts[@]}" \
    -e 's/\(-Xm[sx]\)[0-9]\+m/\18192m/g' \
    -e '/-Dexample.property/ a\
CATALINA_OPTS="-XX:+HeapDumpOnOutOfMemoryError ${CATALINA_OPTS}"\
CATALINA_OPTS="-XX:HeapDumpPath=/backups/heap.bin ${CATALINA_OPTS}"' \
    "${SETENV}"

fi

success "$0"

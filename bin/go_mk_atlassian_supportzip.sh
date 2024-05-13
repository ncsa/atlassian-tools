#!/usr/bin/bash

# See also: https://jira.ncsa.illinois.edu/browse/SVCPLAN-5454


###
# Global Variables
###
YES=0
NO=1
CHOME=/srv/confluence/home
CAPP=/srv/confluence/app
DATE=$(date +%Y%m%d_%H%M%S)
SUPPORTZIP=/root/${DATE}.support.zip
CPUZIP=/root/${DATE}.cpu_usage.zip
VERBOSE=$NO


###
# Functions
###

die() {
  echo "ERROR: ${*}" 1>&2
  exit 99
}


get_confluence_pid() {
  [[ $VERBOSE -eq $YES ]] && set -x
  local _pid=$( systemctl show -p MainPID --value confluence )
  local _cmd=$( ps -p $_pid -o comm= )
  local _usr=$( ps -p $_pid -o user= )
  [[ "$_cmd" != "java" ]] && die "Unknown command '$_cmd' for pid '$_pid' ... expected 'java'"
  [[ "$_usr" != "confluence" ]] && die "Unknown user '$_usr' for pid '$_pid' ... expected 'confluence'"
  echo "$_pid"
}


dump_cpu_threads() {
  # Get Thread dumps and CPU usage information
  [[ $VERBOSE -eq $YES ]] && set -x
  echo "Dump CPU Threads (this will take a few minutes) ..."
  local _tempdir=$( mktemp -d )
  pushd "$_tempdir"
  for i in $(seq 6); do
    top -b -H -p $CONF_PID -n 1 > conf_cpu_usage.$(date +%s).txt
    kill -3 $CONF_PID
    sleep 10
  done
  echo "... Dump CPU Threads OK"

  echo "Make CPU Threads zip ..."
  zip -q $CPUZIP conf_cpu_usage.*.txt
  echo "... Make CPU Threads zip OK"

  popd
  rm -rf "$_tempdir"
}


mk_support_zip() {
  [[ $VERBOSE -eq $YES ]] && set -x
  echo "Make support zip (this will also take a minute) ..."
  zip -q $SUPPORTZIP \
    ${CHOME}/confluence.cfg.xml \
    ${CHOME}/logs/* \
    ${CAPP}/logs/* \
    ${CAPP}/conf/server.xml \
    ${CAPP}/bin/setenv.sh
  echo "... Make support zip OK"
}

###
# MAIN
###

[[ $VERBOSE -eq $YES ]] && set -x

CONF_PID=$( get_confluence_pid )

dump_cpu_threads

mk_support_zip

echo
echo "Atlassian support files:"
ls -l /root/${DATE}*.zip
echo

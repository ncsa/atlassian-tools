#!/usr/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

### VARIABLES
APPDIR=''
HOST=''
ACTION=''
SERVICE=''



### FUNCTIONS
get_host() {
  HOST="$1"
  [[ -z "$HOST" ]] && die 'Missing host'
}


get_action() {
  ACTION="$1"
  [[ -z "$ACTION" ]] && die 'Missing action'
}


get_service() {
  SERVICE="$1"
  case "$SERVICE" in
    (jira)
      SERVICE=jira
      ;;
    (wiki|confluence)
      SERVICE=confluence
      ;;
  esac
}


set_appdir() {
  assert_service
  case "$HOST" in
    jira-test|jira)
      APPDIR=/usr/services/jira-standalone
      ;;
    wiki-test|wiki)
      APPDIR=/usr/services/confluence
      ;;
    *)
      APPDIR="/srv/${SERVICE}/app"
      ;;
  esac
}


assert_service() {
  [[ -z "$SERVICE" ]] && die 'Missing service name'
}


mk_cmd() {
  case "$ACTION" in
    start|stop)
      set_appdir
      echo "${APPDIR}/bin/${ACTION}-${SERVICE}.sh"
      ;;
    status)
      assert_service
      echo "test \$(ps -efw | grep java | grep ${SERVICE} | grep -v grep | wc -l) -eq 1 && echo running || echo stopped"
      ;;
    logs)
      set_appdir
      echo "tail ${APPDIR}/logs/catalina.out"
      ;;
    logsf)
      set_appdir
      echo "tail -f ${APPDIR}/logs/catalina.out"
      ;;
    off|power|shutdown)
      echo 'shutdown -h now'
      ;;
    *)
      die 'Unknown action'
      ;;
  esac
}


### MAIN

get_host "$1"

get_action "$2"

get_service "$3"

cmd=$( mk_cmd )

set -x
ssh "$HOST" "sudo ${cmd}"

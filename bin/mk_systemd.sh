#!/usr/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

PID_FILE="$APP_INSTALL_DIR"/work/catalina.pid
STARTER="$APP_INSTALL_DIR"/bin/start-${APP_NAME}.sh
STOPPER="$APP_INSTALL_DIR"/bin/stop-${APP_NAME}.sh
# USER=$APP_NAME
INSTALL_DIR=/etc/systemd/system
REFERENCE=$(find $INSTALL_DIR -type f -print -quit)


[[ $VERBOSE -eq $YES ]] && set -x


###
# FUNCTIONS
###
mk_service_file() {
  [[ $VERBOSE -eq $YES ]] && set -x
  local _fn="${INSTALL_DIR}/${APP_NAME}.service"
  [[ -f "$_fn" ]] && return 0
  >$_fn cat <<ENDHERE
  [Unit]
  Description=$APP_NAME
  Wants=postgresql.service
  After=postgresql.service

  [Service]
  Type=forking
  PIDFile=$PID_FILE
  ExecStart=$STARTER
  ExecStop=$STOPPER

  [Install]
  WantedBy=multi-user.target
ENDHERE

  chown --reference="$REFERENCE" "$_fn"
  chmod --reference="$REFERENCE" "$_fn"
  systemctl daemon-reload
}


enable_service() {
  systemctl enable ${APP_NAME}.service
}


###
# MAIN
###

mk_service_file

enable_service

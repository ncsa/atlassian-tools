#!/usr/bin/bash

### VARS
DEBUG=1
BKUP_BASE=/root/confluence-bkup-files
APP_DIR=/usr/services/confluence
HOME_DIR=/var/confluence
TS="$( date +%FT%T )"
BKUP_DIR="${BKUP_BASE}/${TS}"
CONF_FILES=( \
  "${APP_DIR}"/conf/server.xml \
  "${APP_DIR}"/bin/setenv.sh \
  "${APP_DIR}"/confluence/WEB-INF/web.xml \
  "${HOME_DIR}"/confluence.cfg.xml \
)


### FUNCTIONS

backup_config_files() {
  [[ $DEBUG -eq 1 ]] && set -x
  echo "Backing up config files"
  cp -av -t "${BKUP_DIR}" "${CONF_FILES[@]}"
}


echo_config_files() {
  echo "After upgrade, be sure to check each of these config files:"
  for f in "${CONF_FILES[@]}"; do
    echo "  $f"
  done
}


stop_confluence() {
  [[ $DEBUG -eq 1 ]] && set -x
  echo "Stopping confluence"
  "${APP_DIR}"/bin/stop-confluence.sh
}


### DO WORK
[[ $DEBUG -eq 1 ]] && set -x

mkdir -p "${BKUP_DIR}"

backup_config_files

stop_confluence

echo_config_files

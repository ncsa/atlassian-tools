#!/usr/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

BIN="${BASE}"/bin
FULLPATH=$(/usr/bin/readlink -e "$0")
CFG=${BASE}/conf/config.sh
INSTALLER=''
ACTION=''
ABLEMENT=''
INSTALLER_LIST=()

[[ $VERBOSE -eq $YES ]] && set -x


###
# FUNCTIONS
###


assert_app_installed() {
  [[ -d "${APP_INSTALL_DIR}"/bin ]] || die "app install dir '$APP_INSTALL_DIR/bin' not found"
}

assert_installer_exists() {
  [[ -z "$INSTALLER" ]] && INSTALLER=$( get_installer )

  [[ -f "$INSTALLER" ]] || die "Installer file not found; '$INSTALLER' "
}


run_installer() {
  /usr/bin/chmod +x "${INSTALLER}"
  "${INSTALLER}"
}




print_usage() {
  local _prg=$(/usr/bin/basename "${FULLPATH}")
  cat <<ENDHERE
${_prg}
  Upgrade the Atlassian app specified in config file '$CFG'
SYNOPSYS
  ${_prg} [OPTIONS] <--start | --finish>

USAGE
  --start  Start an upgrade (stop services, install upgrade, etc.)
  --finish Finish an upgrade (re-enable services, re-enable notifications, etc.)

OPTIONS
  -h --help Print this help and exit
ENDHERE
}


###
# MAIN
###

# Getopts
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq 0 ]] ; do
  case $1 in
    (-h|--help) print_usage; exit 0;;
    (--start)
      ACTION='start'
      ABLEMENT='disable'
      ;;
    (--finish)
      ACTION='finish'
      ABLEMENT='enable'
      ;;
    (--) ENDWHILE=1;;
    (-*) die "Invalid option '$1'";;
    (*) ENDWHILE=1; break;;
  esac
  shift
done

if [[ $ACTION == 'start' ]] ; then
  
  assert_app_installed

  if [[ ${APP_NAME} == "confluence" ]]; then 
    echo "Choose your Confluence installer: "
    INSTALLER=$( get_installer )
    assert_installer_exists
    INSTALLER_LIST+=("${INSTALLER}")
  elif [[ ${APP_NAME} == "jira" ]]; then
    echo "Choose your Jira installer: "
    INSTALLER=$( get_installer )
    assert_installer_exists
    INSTALLER_LIST+=("${INSTALLER}")

    echo "Choose your JSM installer: "
    INSTALLER=$( get_installer )
    assert_installer_exists
    INSTALLER_LIST+=("${INSTALLER}")
  fi
  
  "${BIN}"/backup_config_files.sh

  "${BIN}"/set_services.sh $ABLEMENT

  for INSTALLER in "${INSTALLER_LIST[@]}"; do
    run_installer
  done

  "${BIN}"/restore_config_files.sh

  "${BIN}"/set_notifications.sh $ABLEMENT

  "${BIN}"/fix_java_heap_size.sh

  "${BIN}"/fix_app_config.sh

  "${BIN}"/set_web_access.sh $ABLEMENT

elif [[ $ACTION == 'finish' ]] ; then

  "${BIN}"/set_notifications.sh $ABLEMENT

  "${BIN}"/set_services.sh $ABLEMENT

  "${BIN}"/set_web_access.sh $ABLEMENT

else
  die "Missing one of '--start' | '--finish'"
fi

echo "Elapsed time: '$SECONDS' seconds."

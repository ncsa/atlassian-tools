#!/usr/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

BIN="${BASE}"/bin
FULLPATH=$(/usr/bin/readlink -e "$0")
SOURCES="${BASE}"/install-upgrade/"${APP_NAME}"
INSTALLER=''

[[ $VERBOSE -eq $YES ]] && set -x


###
# FUNCTIONS
###


install_core() {
  [[ -d "${APP_INSTALL_DIR}" ]] && die "APP_INSTALL_DIR '${APP_INSTALL_DIR}' exists ... skipping app install"

  [[ -z "$INSTALLER" ]] && INSTALLER=$( get_installer )

  [[ -f "$INSTALLER" ]] || die "Installer file not found; '$INSTALLER' "

  /usr/bin/chmod +x "${INSTALLER}"
  "${INSTALLER}" -q -varfile "${SOURCES}"/response.varfile
}


install_config() {
  [[ $VERBOSE -eq $YES ]] && set -x
  local _template="${SOURCES}"/server.xml.tmpl
  /usr/bin/sed -e "s/___PROXYNAME___/${HOSTNAME_NEW}/" "${_template}" \
  > "${APP_INSTALL_DIR}"/conf/server.xml
}


install_admin_pwd() {
  [[ $VERBOSE -eq $YES ]] && set -x
  local _pwd_file=$(/usr/bin/find "${SOURCES}" -type f -name '*.pwd' -print)
  [[ -f "${_pwd_file}" ]] && {
    /usr/bin/mv "${_pwd_file}" /root/.
  }
}


print_usage() {
  local _prg=$(/usr/bin/basename "${FULLPATH}")
  cat <<ENDHERE
${_prg}
  Install all or part of the Atlassian app
SYNOPSYS
  ${_prg} [OPTIONS] [installer_file.bin]
OPTIONS
  -h --help Print this help
  -c --configonly Install just the config file (server.xml)
ENDHERE
}


###
# MAIN
###

# Getopts
action="install"
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -eq 0 ]] ; do
  case $1 in
    -h|--help) print_usage; exit 0;;
    -c|--configonly) action="configonly";;
    --) ENDWHILE=1;;
    -*) echo "Invalid option '$1'"; exit 1;;
     *) ENDWHILE=1; break;;
  esac
  shift
done

INSTALLER="$1"

if [[ "${action}" == 'install' ]] ; then
  # Install
  install_core

  install_config

  "${BIN}"/set_notifications.sh disable

  "${BIN}"/fix_java_heap_size.sh

  "${BIN}"/mk_systemd.sh

  install_admin_pwd

elif [[ "${action}" == 'configonly' ]] ; then
  install_config
fi

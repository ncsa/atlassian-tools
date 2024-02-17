#!/usr/bin/bash

set -x

FULLPATH=$(/usr/bin/readlink -e "$0")
PRG=$(/usr/bin/basename "${FULLPATH}")
BASE=$(/usr/bin/dirname "${FULLPATH}")
APPNAME=$(/usr/bin/basename "${BASE}")
ANSWER_FILE="${BASE}"/response.varfile
APPDIR=$(/usr/bin/awk -F '=' '/sys.installationDir=/ {print $2}' "${ANSWER_FILE}")


install_jira_core() {
  [[ -d "${APPDIR}" ]] && {
    /usr/bin/echo "APPDIR '${APPDIR}' exists ... skipping app install" 1>&2
    return -1
  }
  local _installer=$(/usr/bin/find "${BASE}" -type f -name "${FILE_NAME_PATTERN}" -print \
  | /usr/bin/sort -V \
  | /usr/bin/tail -1)
  /usr/bin/chmod +x "${_installer}"
  "${_installer}" -q -varfile "${ANSWER_FILE}"
}


install_config() {
  set -x
  local _hn=$(/usr/bin/hostname -f)
  local _template="${BASE}"/server.xml.tmpl
  /usr/bin/sed -e "s/___PROXYNAME___/${_hn}/" "${_template}" \
  > "${APPDIR}"/conf/server.xml
}


disable_notifications() {
  if [[ ${APPNAME} == "jira" ]] ; then
    sed -i -e 's/^#\(DISABLE_NOTIFICATIONS\)/\1/' "${APPDIR}"/bin/setenv.sh
  elif [[ ${APPNAME} == "confluence" ]] ; then
    sed -i -e 's/^#\(CATALINA_OPTS=.*atlassian.mail.senddisabled\)/\1/' "${APPDIR}"/bin/setenv.sh
  fi
}


install_admin_pwd() {
  set -x
  local _pwd_file=$(/usr/bin/find "${BASE}" -type f -name '*.pwd' -print)
  [[ -f "${_pwd_file}" ]] && {
    /usr/bin/mv "${_pwd_file}" /root/.
  }
}


print_usage() {
  cat <<ENDHERE
${PRG}
  Install all or part of the Atlassian app
SYNOPSYS
  ${PRG} [OPTIONS] [installer_file.bin]
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

FILE_NAME_PATTERN="$1"
[[ -z "${FILE_NAME_PATTERN}" ]] && FILE_NAME_PATTERN='atlassian*.bin'

if [[ "${action}" == 'install' ]] ; then
  # Install
  install_jira_core && {

    /usr/bin/echo
    /usr/bin/echo "INSTALL SUCCESS"
    /usr/bin/echo

    install_config

    disable_notifications

    install_admin_pwd
  }
elif [[ "${action}" == 'configonly' ]] ; then
  install_config
fi

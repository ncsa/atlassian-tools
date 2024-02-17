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

action=$1
case ${action} in
  (enable|disable)
    : pass
    ;;
  (*)
    die "missing or unknown action '$action'"
    ;;
esac

if [[ ${APP_NAME} == "jira" ]] ; then

  if [[ ${action} == "disable" ]] ; then
    # disable - jira
    sed "${sed_opts[@]}" -e 's/^[ #]*\(DISABLE_NOTIFICATIONS=\)/\1/' "$SETENV"

  elif [[ ${action} == "enable" ]] ; then
    # enable - jira
    sed "${sed_opts[@]}" -e 's/^[ #]*\(DISABLE_NOTIFICATIONS=\)/#\1/' "$SETENV"
  fi

elif [[ ${APP_NAME} == "confluence" ]] ; then

  if [[ ${action} == "disable" ]] ; then
    # disable - confluence
    sed "${sed_opts[@]}" -e '/atlassian.mail.senddisabled=true/ s/^[ #]*//' "$SETENV"

  elif [[ ${action} == "enable" ]] ; then
    # enable - confluence
    sed "${sed_opts[@]}" -e '/atlassian.mail.senddisabled=true/ s/^[ #]*/#/' "$SETENV"
  fi

fi

success "Notifications ${action}d"

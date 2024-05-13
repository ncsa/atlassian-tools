#!/usr/bin/bash

# See also: https://jira.ncsa.illinois.edu/browse/SVC-24653


###
# Global Variables
###
YES=0
NO=1
LOG_DIR=/var/log
ARCHIVE_DIR=/backups/old_logs
MAX_ARCHIVE_AGE=30 #days
DATE=$(date +%Y%m%d_%H%M%S)
VERBOSE=$YES
DEBUG=$NO
#DEBUG=$YES


###
# Functions
###

die() {
  echo "ERROR: ${*}" 1>&2
  exit 99
}


force_rotate_logs() {
  echo "${FUNCNAME[0]} ..."
  local _vopts _dopts
  [[ $VERBOSE -eq $YES ]] && {
    set -x
    _vopts+=( '-v' )
  }
  [[ $DEBUG -eq $YES ]] && _dopts+=( '-d' )
  /usr/sbin/logrotate -f ${_vopts[@]} ${_dopts[@]} /etc/logrotate.conf
  echo "${FUNCNAME[0]} OK"
}


archive_logs() {
  echo "${FUNCNAME[0]} ..."
  local _vopts
  [[ $VERBOSE -eq $YES ]] && {
    set -x
    _vopts+=( '-v' )
  }
  [[ $DEBUG -eq $YES ]] && _dopts+=( '-d' )
  local _tgz="${ARCHIVE_DIR}"/"${DATE}".tgz
  local _tmp=$( mktemp -p "${ARCHIVE_DIR}" )
  >"${_tmp}" find "${LOG_DIR}" -type f \
    -name '*.[0-9]' \
    -o -name '*.gz' \
    -o -regextype egrep -regex '.*-[0-9]{8}'
  if [[ $DEBUG -eq $YES ]] ; then
    echo "DEBUG - files that would have been archived:"
    cat "${_tmp}"
  elif [[ -s "${_tmp}" ]] ; then
    tar -zcf "${_tgz}" ${_vopts[@]} -T "${_tmp}" --remove-files
  fi
  rm "${_tmp}"
  echo "${FUNCNAME[0]} OK"
}


clean_old_logs() {
  echo "${FUNCNAME[0]} ..."
  [[ $VERBOSE -eq $YES ]] && set -x
  local _action='-delete'
  [[ $DEBUG -eq $YES ]] && _action='-print'
  find "${ARCHIVE_DIR}" -type f -mtime +${MAX_ARCHIVE_AGE} $_action
  echo "${FUNCNAME[0]} OK"
}


###
# MAIN
###

[[ $VERBOSE -eq $YES ]] && set -x

force_rotate_logs

archive_logs

clean_old_logs

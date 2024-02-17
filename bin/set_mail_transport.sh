#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

###
# VARS
###
MAIL_CONFIG=/etc/postfix/main.cf
TRANSPORT=''
ECHO=''
ACTION=''


###
# FUNCTIONS
###
ensure_transport_cf_line() {
  grep -q '^default_transport = ' "${MAIL_CONFIG}" || \
    echo "default_transport = none" >> "${MAIL_CONFIG}"
}


set_transport() {
  local _val="$1"
  ensure_transport_cf_line
  sed -i "s/^default_transport = .*/default_transport = $_val/" "${MAIL_CONFIG}"
}


assert_transport_match() {
  local _val="$1"
  grep -q "^default_transport = ${_val}" "${MAIL_CONFIG}" \
    && success "${param}d mail transport" \
    || err "${param}ing mail transport"
}


status_check() {
  local _cf=$( grep '^default_transport = ' "${MAIL_CONFIG}" )
  local _live=$( postconf | grep '^default_transport = ' )
  cat << ENDHERE
  Config = "$_cf"
  Live   = "$_live"
ENDHERE
}


print_help() {
  cat << ENDHERE
  Synopsis: ${0} ACTION
  where ACTION is one of:
    enable
    disable
    check status st ls
  
ENDHERE
}


###
# MAIN
###
[[ $VERBOSE -eq $YES ]] && set -x

[[ $DEBUG -eq $YES ]] && ECHO="echo"

param=$1
case $param in
  (enable)
    TRANSPORT=smtp
    ACTION=set
    ;;
  (disable)
    TRANSPORT=hold
    ACTION=set
    ;;
  (check|status|st|ls)
    ACTION=check
    ;;
  (-h)
    print_help
    exit
    ;;
  (*)
    die "missing or unknown param '$param'"
    ;;
esac

case $ACTION in 
  (set)
    $ECHO set_transport "$TRANSPORT"
    $ECHO assert_transport_match "$TRANSPORT"
    $ECHO status_check
    ;;
  (check)
    $ECHO status_check
    ;;
esac

#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh


die() {
  echo "ERROR: $*" 1>&2
  exit 99
}


ask_user() {
  # INPUT
  #   $1 prompt
  # OUTPUT
  #   user response as text string
  local _msg="$1"
  [[ -z "$_msg" ]] && die "missing prompt in ask_user()"
  read -r -p "$_msg"
  echo "$REPLY"
}


get_hostname() {
  /usr/bin/hostnamectl status | awk '/Static hostname: / { print $NF }'
}

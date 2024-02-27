#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

IFCFG=( $( grep -l "$IPADDR_OLD" /etc/sysconfig/network-scripts/* ) )
[[ "${#IFCFG[@]}" -gt 1 ]] && die "Multiple ifcfg files found"


sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" \
  -e '/^UUID\|^HWADDR/ d' \
  -e "/^IPADDR0=/ c IPADDR0=${IPADDR_NEW}" \
  -e "/^IPADDR=/ c IPADDR=${IPADDR_NEW}" \
  "${IFCFG}"


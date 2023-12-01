#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

IFCFG=( $(find /etc/sysconfig/network-scripts/ -maxdepth 1 -type f -name 'ifcfg-eno1*' -print) )
[[ "${#IFCFG[@]}" -gt 1 ]] && die "Multiple ifcfg files found"


sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" \
  -e '/^UUID\|^HWADDR/ d' \
  -e "/^IPADDR0=/ c IPADDR0=${IPADDR_NEW}" \
  "${IFCFG}"


#!/bin/bash

BASE=/root/atlassian-tools
BIN="$BASE"/bin
CONF="$BASE"/conf
LIB="$BASE"/lib

. "$CONF"/config.sh
. "$LIB"/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eno1*

grep ncsa /usr/services/jirahome/dbconfig.xml

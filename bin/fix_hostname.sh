#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action='echo'

HOSTNAME_OLD=$( get_hostname )
[[ -z "$HOSTNAME_OLD" ]] && die 'Unable to determine hostname'

if [[ -z "$HOSTNAME_NEW" ]] ; then
  HOSTNAME_NEW=$( ask_user 'Enter new hostname: ')
fi
[[ -z "$HOSTNAME_NEW" ]] && die 'Missing new hostname'

# Set new hostname
$action hostnamectl set-hostname --static "$HOSTNAME_NEW"

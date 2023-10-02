#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action='echo'

# Stop services via systemctl
for ss_name in "${SYSTEM_SERVICES_TO_STOP[@]}"; do
  $action systemctl disable --now "$ss_name" \
  || die "Problem stopping service $ss_name"
done

# Stop puppet managed services
for ps_name in "${PUPPET_SERVICES_TO_STOP[@]}"; do
  $action puppet resource service "$ps_name" ensure=stopped enable=false
done

# Prevent future puppet runs
puppet agent --disable "puppet stopped on cloned test server"

#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && echo='echo'

action=$1
case $action in 
  (disable)
    ss_action='disable'
    ps_ensure='stopped'
    ps_enable='false'
    pa_parms=('--disable' 'stopped by atlassian-tools')
    ;;
  (enable)
    ss_action='enable'
    ps_ensure='running'
    ps_enable='true'
    pa_parms=('--enable')
    ;;
  (*)
    ;;
esac

# Set systemctl services
for ss_name in "${SYSTEM_SERVICES_TO_STOP[@]}"; do
  $echo systemctl $ss_action --now "$ss_name" \
  || die "$ss_action service $ss_name failed"
  success "service $ss_name ${ss_action}d"
done

# Set puppet managed services
for ps_name in "${PUPPET_SERVICES_TO_STOP[@]}"; do
  $echo puppet resource service "$ps_name" ensure=$ps_ensure enable=$ps_enable 1>&2
  success "puppet resource $ps_name ${ps_ensure}"
done

# Set puppet agent run ability
$echo puppet agent "${pa_parms[@]}"
success "puppet agent ${ss_action}d"

#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action='echo'

sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts

for fn in $( find /etc/httpd/conf.d -type f -name "25-${HOSTNAME_OLD}-*.conf" ); do

  # make new files using new hostname
  fn_new="${fn/${HOSTNAME_OLD}/${HOSTNAME_NEW}}"
  cp "$fn" "$fn_new"

  # update settings in new config files
  sed "${sed_opts[@]}" \
    -e "/ServerName/ c ServerName ${HOSTNAME_NEW}" \
    -e '/ServerAlias/ d' \
    -e "/${HOSTNAME_OLD}/ s/${HOSTNAME_OLD}/${HOSTNAME_NEW}/g" \
    -e '/## Proxy rules/ a ProxyTimeout 1800' \
    "$fn_new"

  # rename old configs so apache won't include them after restart
  mv "$fn" "${fn}.no"
done

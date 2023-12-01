#!/bin/bash

BASE=/root/atlassian-tools
BIN="$BASE"/bin

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action=echo

$action certbot certonly -v -n \
  --webroot -w "/var/www/html" \
  --deploy-hook "/etc/letsencrypt/renewal-hooks-puppet/renew-deploy.sh" \
  -d ${HOSTNAME_NEW}

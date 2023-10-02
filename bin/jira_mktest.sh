#!/bin/bash

BASE=/root/atlassian-tools
BIN="$BASE"/bin
CONF="$BASE"/conf
LIB="$BASE"/lib

. "$CONF"/config.sh
. "$LIB"/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x


"$BIN"/stop_services.sh

"$BIN"/disable_mail.sh

"$BIN"/disable_notifications.sh

"$BIN"/fix_keytab.sh

"$BIN"/fix_network.sh

"$BIN"/fix_cron.sh

"$BIN"/fix_hostname.sh

# Depends on fix_hostname
"$BIN"/fix_app_config.sh

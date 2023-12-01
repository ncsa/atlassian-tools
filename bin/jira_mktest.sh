#!/bin/bash

BASE=/root/atlassian-tools
BIN="$BASE"/bin

. "$BASE"/conf/config.sh
. "$BASE"/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x


"$BIN"/stop_services.sh

"$BIN"/disable_mail.sh

"$BIN"/disable_notifications.sh

"$BIN"/fix_network.sh

"$BIN"/fix_cron.sh

"$BIN"/fix_hostname.sh

"$BIN"/fix_app_config.sh

"$BIN"/fix_keytab.sh

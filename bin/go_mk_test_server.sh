#!/bin/bash

BASE=${HOME}/atlassian-tools
BIN="$BASE"/bin

. "$BASE"/conf/config.sh
. "$BASE"/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x


"$BIN"/set_services.sh disable

# "$BIN"/disable_mail.sh

"$BIN"/set_notifications.sh disable

"$BIN"/fix_network.sh

"$BIN"/fix_cron.sh

"$BIN"/fix_hostname.sh

"$BIN"/fix_app_config.sh

"$BIN"/fix_keytab.sh

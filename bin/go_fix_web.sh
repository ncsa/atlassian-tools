#!/bin/bash

BASE=${HOME}/atlassian-tools
BIN="$BASE"/bin

. "$BASE"/conf/config.sh
. "$BASE"/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

/bin/systemctl stop httpd

"$BIN"/mk_certs.sh

"$BIN"/fix_web_configs.sh

/bin/systemctl restart httpd

sleep 2

/bin/systemctl status httpd

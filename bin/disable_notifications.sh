#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

SETENV="${APP_INSTALL_DIR}"/bin/setenv.sh
[[ -f "$SETENV" ]] || die "File not found, SETENV: '$SETENV'"

grep -q DISABLE_NOTIFICATIONS "$SETENV" \
|| die "Did not find DISABLE_NOTIFICATIONS var in file '$SETENV'"

sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" -e 's/^[ #]*\(DISABLE_NOTIFICATIONS=\)/\1/' "$SETENV"

#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action='echo'

HOSTNAME=$( get_hostname )
KEYTAB_OLD=/etc/krb5.keytab
KEYTAB_NEW="${KEYTAB_OLD}.${HOSTNAME}"

[[ -f "${KEYTAB_NEW}" ]] || die "cant find keytab file '${KEYTAB_NEW}'"

$action cp "${KEYTAB_OLD}" "${KEYTAB_NEW}"

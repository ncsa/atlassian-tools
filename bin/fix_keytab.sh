#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x
[[ $DEBUG -eq $YES ]] && action='echo'

KEYTAB=/etc/krb5.keytab
KEYTAB_NEW="${KEYTAB}.${HOSTNAME_NEW}"

# move old keytab aside
$action mv "$KEYTAB" "${KEYTAB}.${HOSTNAME_OLD}"

# put new keytab in place
if [[ -f "${KEYTAB_NEW}" ]] ; then
  $action ln -s "${KEYTAB_NEW}" "${KEYTAB}" 
else
  err "cant find keytab file '${KEYTAB_NEW}'"
fi

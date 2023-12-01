#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x


# Fix server.xml
XML="$APP_INSTALL_DIR"/conf/server.xml
[[ -z "$XML" ]] && die "File not found: '$XML'"

TMP=$(mktemp)
sed -e 's/\(proxyName="\)[^"]\+"/\1xxxyyyzzz"/' "$XML" \
| sed -e "s/xxxyyyzzz/$HOSTNAME_NEW/" >$TMP

if [[ $DEBUG -eq $YES ]] ; then
  cat $TMP
  rm $TMP
else
  mv $TMP "$XML"
fi


# Fix DB config
DB_CONF="$APP_HOME_DIR"/dbconfig.xml
sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" -e "s/$DB_NAME_OLD/$DB_NAME_NEW/g" "$DB_CONF"


# Fix web.xml
XML="$APP_INSTALL_DIR"/atlassian-jira/WEB-INF/web.xml
[[ -z "$XML" ]] && die "File not found: '$XML'"
sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" \
  -e 's/\(<session-timeout>\)[0-9]\+\(<\/session-timeout>\)/\112000\2/' \
  "$XML"

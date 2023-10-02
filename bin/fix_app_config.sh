#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

HOSTNAME=$( get_hostname )
[[ -z "$HOSTNAME" ]] && die 'Unable to determine hostname'

# Fix server.xml
XML="$APP_INSTALL_DIR"/conf/server.xml
[[ -z "$XML" ]] && die "File not found: '$XML'"

TMP=$(mktemp)
sed -e 's/\(proxyName="\)[^"]\+"/\1xxxyyyzzz"/' "$XML" \
| sed -e "s/xxxyyyzzz/$HOSTNAME/" >$TMP

if [[ $DEBUG -eq $YES ]] ; then
  cat $TMP
  rm $TMP
else
  mv $TMP "$XML"
fi

# Fix DB config
DB_CONF="$APP_HOME_DIR"/dbconfig.xml
if [[ -z "$DB_NAME_OLD" ]] ; then
  DB_NAME_OLD=$( ask_user 'DB_NAME_OLD: ' )
  [[ -z "$DB_NAME_OLD" ]] && die 'DB_NAME_OLD cannot be empty'
fi
if [[ -z "$DB_NAME_NEW" ]] ; then
  DB_NAME_NEW=$( ask_user 'DB_NAME_NEW: ' )
  [[ -z "$DB_NAME_NEW" ]] && die 'DB_NAME_NEW cannot be empty'
fi
sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts
sed "${sed_opts[@]}" -e "s/$DB_NAME_OLD/$DB_NAME_NEW/g" "$DB_CONF"

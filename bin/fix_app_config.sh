#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

sed_opts=( '-i' )
[[ $DEBUG -eq $YES ]] && unset sed_opts

# Fix server.xml
SERVER_XML="$APP_INSTALL_DIR"/conf/server.xml
[[ -f "$SERVER_XML" ]] || die "File not found: '$SERVER_XML'"

# ... HOSTNAME
TMP=$(mktemp)
sed -e 's/\(proxyName="\)[^"]\+"/\1xxxyyyzzz"/' "$SERVER_XML" \
| sed -e "s/xxxyyyzzz/$HOSTNAME_NEW/" >$TMP

chown --reference="$SERVER_XML" "$TMP"
chmod --reference="$SERVER_XML" "$TMP"
if [[ $DEBUG -eq $YES ]] ; then
  cat $TMP
  rm $TMP
else
  mv $TMP "$SERVER_XML"
fi
success "Fixed hostname in server.xml"


# ... Upgrade recovery (confluence only)
[[ $APP_NAME == 'confluence' ]] && {
  SETENV="${APP_INSTALL_DIR}"/bin/setenv.sh
  [[ -f "$SETENV" ]] || die "File not found: '$SETENV'"
  sed "${sed_opts[@]}" \
    -e '/upgrade.recovery.file.enabled=false/ s/^[ #]*//' \
    "$SETENV"
  success "disabled confluence upgrade recovery file creation"
}


# Fix DB config
if [[ "$DB_NAME_OLD" == "$DB_NAME_NEW" ]] ; then
  echo 'DB_NAME_OLD == DB_NAME_NEW, no changes needed ... skipping "Fix DB Config" step'
else
  case "$APP_NAME" in
    jira)
      DB_CONF="$APP_HOME_DIR"/dbconfig.xml
      PTRN="<url>jdbc:"
      ;;
    confluence)
      DB_CONF="$APP_HOME_DIR"/confluence.cfg.xml
      PTRN='hibernate\.connection\.url'
      ;;
  esac
  sed "${sed_opts[@]}" -e "s/$DB_NAME_OLD/$DB_NAME_NEW/g" "$DB_CONF"
  success "Updated DB config"
fi


# Fix session timeout in web.xml
# Historically, this was set to 12000 (8.3 days) ... why?
# See also:
# https://confluence.atlassian.com/confkb/how-to-adjust-the-session-timeout-for-confluence-126910597.html
# https://confluence.atlassian.com/jirakb/change-the-default-session-timeout-to-avoid-user-logout-in-jira-server-604209887.html
# TODO - Is this needed anymore after change to SSO via CiLogon?
WEB_XML=''
if [[ $APP_NAME == 'jira' ]] ; then
  WEB_XML="$APP_INSTALL_DIR"/atlassian-jira/WEB-INF/web.xml
elif [[ $APP_NAME == 'confluence' ]] ; then
  WEB_XML="$APP_INSTALL_DIR"/confluence/WEB-INF/web.xml
fi
[[ -f "$WEB_XML" ]] || die "File not found: '$WEB_XML'"
sed "${sed_opts[@]}" \
  -e 's/\(<session-timeout>\)[0-9]\+\(<\/session-timeout>\)/\11200\2/' \
  "$WEB_XML"
success "Fix session timeout in web.xml"

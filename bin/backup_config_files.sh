#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

FILES=( 
  "$APP_INSTALL_DIR"/conf/server.xml
  "$APP_INSTALL_DIR"/bin/setenv.sh
)
case "$APP_NAME" in
  jira)
    DB_CONF="$APP_HOME_DIR"/dbconfig.xml
    WEB_XML="$APP_INSTALL_DIR"/atlassian-jira/WEB-INF/web.xml
    ;;
  confluence)
    DB_CONF="$APP_HOME_DIR"/confluence.cfg.xml
    WEB_XML="$APP_INSTALL_DIR"/confluence/WEB-INF/web.xml
    ;;
esac
FILES+=( "$DB_CONF" "$WEB_XML" )

mkdir -p "$BACKUP_DIR" #BACKUP_DIR defined in config.sh

tar -c -f - "${FILES[@]}" | tar -x -f - -C "$BACKUP_DIR" \
  && success "Config files backed up to '$BACKUP_DIR'"

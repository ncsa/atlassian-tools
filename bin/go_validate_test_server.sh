#!/bin/bash

BASE=${HOME}/atlassian-tools
BIN="$BASE"/bin

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

# stop_services.sh
# puppet ssl dir should not exist
[[ -f $(puppet agent --configprint agent_disabled_lockfile) ]] \
  || die "puppet agent still enabled"
success "Puppet is DISABLED!"

# disable_notifications.sh
# notifications should be disabled
grep -q '^[A-Za-z].\+atlassian.mail.senddisabled=true' "${APP_INSTALL_DIR}"/bin/setenv.sh \
  || die "Cant verify jira notifications are disabled"
success "Notifications are DISABLED!"

# fix_network.sh
# new IP should be in ifcfg file
grep -q "$IPADDR_NEW" /etc/sysconfig/network-scripts/* \
  || die "Did not find new IP in ifcfg"
success "New IP found in ifcfg!"
# ensure old IP is no in any ifcfg files
grep "$IPADDR_OLD" /etc/sysconfig/network-scripts/* \
  && die "Old IP was found in an ifcfg script"
success "Old IP no longer found in ifcfg scripts!"

# fix_cron.sh
# cron jobs should be all disabled
crontab -l | grep -q '^[^#]' \
  && die "Found a non-comment line in crontab"
success "No crontabs enabled!"

# fix_hostname.sh
# check hostname
hostnamectl status --static | grep -q "$HOSTNAME_NEW" \
  || die "Hostname does NOT match '$HOSTNAME_NEW'"
success "Hostname looks good!"

# fix_keytab.sh
# check keytab
klist -k /etc/krb5.keytab | grep -q -F "${HOSTNAME_OLD}" \
  && die "Old hostname still in keytab"
klist -k /etc/krb5.keytab | grep -q -F "${HOSTNAME_NEW}" \
  || die "New hostname NOT in keytab"
success "KRB5 keytab looks good!"

# fix_app_config.sh
# check server.xml
XML="$APP_INSTALL_DIR"/conf/server.xml
grep -F 'proxyName=' "$XML" | grep -q "$HOSTNAME_NEW" \
  || die "New hostname not found in '$XML'"
success "server.xml has new hostname"

# fix_app_config.sh
# check db config ... only if old differs from new
if [[ "$DB_NAME_OLD" != "$DB_NAME_NEW" ]] ; then
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
  grep -F "/${DB_NAME_OLD}?" "$DB_CONF" \
    && die "Old DB name found in dbconfig.xml"
  grep -F "/${DB_NAME_NEW}?" "$DB_CONF" \
  || die "New DB name NOT found in dbconfig.xml"
  success "DB config looks good!"
fi

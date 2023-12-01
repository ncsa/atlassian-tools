#!/bin/bash

BASE=/root/atlassian-tools
BIN="$BASE"/bin

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

# stop_services.sh
# puppet ssl dir should not exist
[[ -d /etc/puppetlabs/puppet/ssl ]] \
  && die "puppet ssl dir exists"
success "Puppet is DISABLED!"

# disable_notifications.sh
# jira notifications should be disabled
grep -q '^DISABLE_NOTIFICATIONS' "${APP_INSTALL_DIR}"/bin/setenv.sh \
  || die "Cant verify jira notifications are disabled"
success "Jira notifications are DISABLED!"

# fix_network.sh
# new IP should be in ifcfg file
grep "$IPADDR_NEW" /etc/sysconfig/network-scripts/ifcfg-eno1* \
  || die "Did not find new IP in ifcfg"
success "New IP found in ifcfg!"
# ensure old IP is no in any ifcfg files
grep "$IPADDR_OLD" /etc/sysconfig/network-scripts/* \
  && die "Old IP was found in an ifcfg script"
success "Old IP no longer found in ifcfg scripts!"

# fix_cron.sh
# cron jobs should be all disabled
crontab -l | grep '^[^#]' \
  && die "Found a non-comment line in crontab"
success "No crontabs enabled!"

# fix_hostname.sh
# check hostname
hostnamectl status --static | grep -q "$HOSTNAME_NEW" \
  || die "Hostname does NOT match '$HOSTNAME_NEW'"
success "Hostname looks good!"

# fix_keytab.sh
# check keytab
klist -k /etc/krb5.keytab | grep -F "${HOSTNAME_OLD}" \
  && die "Old hostname still in keytab"
klist -k /etc/krb5.keytab | grep -F "${HOSTNAME_NEW}" \
  || die "New hostname NOT in keytab"
success "KRB5 keytab looks good!"

# fix_app_config.sh
# check db config
DB_CONF="$APP_HOME_DIR"/dbconfig.xml
grep -F "/${DB_NAME_OLD}?" /usr/services/jirahome/dbconfig.xml \
  && die "Old DB name found in dbconfig.xml"
grep -F "/${DB_NAME_NEW}?" /usr/services/jirahome/dbconfig.xml \
  || die "New DB name NOT found in dbconfig.xml"
XML="$APP_INSTALL_DIR"/conf/server.xml
success "DB config looks good!"

# fix_app_config.sh
# check server.xml
grep -F 'proxyName=' "$XML" | grep -q "$HOSTNAME_NEW" \
  || die "New hostname not found in '$XML'"

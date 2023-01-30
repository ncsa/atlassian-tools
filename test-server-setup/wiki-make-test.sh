#!/bin/bash
sed -ine 's/141.142.192.52/141.142.192.248/g' /etc/sysconfig/network-scripts/ifcfg-ens192
sed -ine 's/UUID/#UUID/g' /etc/sysconfig/network-scripts/ifcfg-ens192
hostnamectl set-hostname --static wiki-test.ncsa.illinois.edu
systemctl disable --now confluence puppet crashplan
puppet resource service telegraf ensure=stopped enable=false
puppet agent --disable "puppet disable while testing and upgrading"
yes 'yes' | /root/crashplan-install/uninstall.sh -i /usr/local/crashplan
sed -ine 's/#CATALINA_OPTS="-Datlassian.mail.senddisabled=true -Datlassian.mail.fetchdisabled=true ${CATALINA_OPTS}"/CATALINA_OPTS="-Datlassian.mail.senddisabled=true -Datlassian.mail.fetchdisabled=true ${CATALINA_OPTS}"/g' /usr/services/confluence/bin/setenv.sh
# Change to HTTPD files in /etc/httpd/conf.d/ files needed ?!?!?!
rm -f /etc/krb5.keytab
sed -ine 's/wiki.ncsa/wiki-test.ncsa/g' /usr/services/confluence/conf/server.xml
shutdown -h now

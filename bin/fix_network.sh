#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x


get_ifcfg_filename() {
  IFCFG=( $( grep -l "$IPADDR_OLD" /etc/sysconfig/network-scripts/* ) )
  [[ "${#IFCFG[@]}" -gt 1 ]] && die "Multiple ifcfg files found"
  [[ "${#IFCFG[@]}" -lt 1 ]] && die "No ifcfg files found"
}

get_old_mac_addr() {
  awk -F'=' '/^HWADDR=/ {print $2}' "${IFCFG}"
}


get_interface_name() {
  INTF=$( ls /sys/class/net | grep ens | head -1 )
  [[ -z "${INTF}" ]] && die "Cannot find a network interface with name like 'ens'"
}


get_new_mac_addr() {
  MAC=$( cat /sys/class/net/"${INTF}"/address )
  [[ -z "${MAC}" ]] && die "Failed to get MACADDR for interface '${INTF}'"
}


find_udev_files() {
  grep -c -F "${OLD_MAC}" /etc/udev/rules.d/* \
  | grep -v ':0$' \
  | cut -d: -f1
}


update_udev() {
  find /etc/udev/rules.d \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
  | xargs -r \
    sed -i \
      -e "s/${OLD_MAC}/${MAC}/"
}


update_ifcfgs() {
  # replace MAC and IP in any files
  find /etc/sysconfig/network-scripts \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
  | xargs -r \
    sed -i \
      -e '/^UUID=/ d' \
      -e "s/${OLD_MAC}/${MAC}/" \
      -e "s/${IPADDR_OLD}/${IPADDR_NEW}/"
}


mk_ifcfg() {
  cat <<ENDHERE >/etc/sysconfig/network-scripts/"${INTF}"
DEVICE=${INTF}
NAME=${INTF}
HWADDR=${MAC}
IPADDR=${IPADDR_NEW}
NETMASK=255.255.248.0
BOOTPROTO=none
ONBOOT=yes
ENDHERE
}


rm_ifcfgs() {
  find /etc/sysconfig/network-scripts \
    -mindepth 1 \
    -maxdepth 1 \
    -type f \
    -delete
}

###
# MAIN
###

get_ifcfg_filename
get_interface_name
get_new_mac_addr

OLD_MAC=$( get_old_mac_addr )

UDEV_FN=( $( find_udev_files ) )
if [[ "${#UDEV_FN[@]}" -gt 0 ]] ; then
  # if udev rule file exists, do MAC and IP updates
  update_udev
  update_ifcfgs
else
  # otherwise, just delete existing ifcfg's and generate a fresh one
  rm_ifcfgs
  mk_ifcfg
fi

#!/usr/bin/bash

set -x 

YES=0
NO=1
VERBOSE=$YES
DEBUG=$YES

VGS=( vg_pgsql vg_backups vg_confluence )

ECHO=
[[ $DEBUG -eq $YES ]] && ECHO=echo

get_mountpoint() {
  local _vg="$1"
  mount | grep $_vg | cut -d' ' -f1
}

mp_destroy() {
  local _mp="$1"
  [[ -n "$_mp" ]] && {
    $ECHO umount "$_mp"
    $ECHO wipefs -a -f "$_mp"
  }
}

vg_delete() {
  local _vg="$1"
  local _count=$( vgs | grep -c "$_vg" )
  [[ $_count -gt 0 ]] && $ECHO vgremove -y $_vg
}

get_pv() {
  local _vg="$1"
  vgs | grep -qF "$_vg" \
  && vgs -o pv_name --noheadings $_vg
}

pv_wipe() {
  local _pv="$1"
  # $ECHO dd if=/dev/zero of=$pv bs=1M count=1
  $ECHO wipefs -a -f "$_pv"
}

get_lv() {
  local _vg="$1"
  vgs | grep -qF "$_vg" \
  && vgs -o lv_name --noheadings "$_vg"
}

for vg in "${VGS[@]}" ; do

  lv=$( get_lv "$vg" )
  pv=$( get_pv "$vg" )
  mountp=$( get_mountpoint "$vg" )
  mp_destroy "$mountp"
#  vg_delete "$vg"
#
#  for pv in "${peevees[@]}" ; do
#    echo "PV REMOVE $pv"
#    $ECHO pvremove -y "$pv"
#    pv_wipe "$pv"
#  done

done


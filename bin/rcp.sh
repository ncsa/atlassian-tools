#!/usr/bin/bash

# RCP - Remote CoPy

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

### VARIABLES
SRC_HOST=''
TGT_HOST=''
ACTION=''
SRC_HOME=''
TGT_HOME=''
SRC_PATH=''
TGT_PATH=''
SHOW_REMOTE_FILES=$YES
OFFER_TO_CLEAN_FILES=$YES


### FUNCTIONS
get_src_host() {
  SRC_HOST="$1"
  [[ -z "$SRC_HOST" ]] && die 'Missing source host'
  case "$SRC_HOST" in
    (wiki-test)
      SRC_HOME=/var/confluence
      ;;
    (*)
      die 'Unknown host'
      ;;
  esac
}


get_tgt_host() {
  TGT_HOST="$1"
  [[ -z "$TGT_HOST" ]] && die 'Missing target host'
  case "$TGT_HOST" in
    (wiki-dev|wiki)
      TGT_HOME=/srv/confluence/home
      ;;
    (*)
      die 'Unknown host'
      ;;
  esac
}


get_action() {
  ACTION="$1"
  [[ -z "$ACTION" ]] && die 'Missing action'
  case "$ACTION" in
    (xml)
      SRC_PATH="$SRC_HOME"/temp
      TGT_PATH="$TGT_HOME"/restore
      ;;
    (attachments)
      SRC_PATH="$SRC_HOME"/attachments
      TGT_PATH="$TGT_HOME"/attachments
      SHOW_REMOTE_FILES=$NO
      OFFER_TO_CLEAN_FILES=$NO
      ;;
    (*)
      die 'Unknown action'
      ;;
  esac
}


ls_remote() {
  [[ $SHOW_REMOTE_FILES -eq $NO ]] && return 0
  local _host="$1"
  local _path="$2"
  echo "Files on ${_host}:${_path} ..."
  ssh "$_host" "sudo find $_path -type f -print"
}


clean_remote() {
  local _host="$1"
  local _path="$2"
  ls_remote "$_host" "$_path"
  [[ $OFFER_TO_CLEAN_FILES -eq $NO ]] && return 0
  ask_yes_no "Delete remote files?" && {
    ssh "$_host" "sudo find $_path -type f -print -delete"
  }
}


copy_files() {
  # copy from src to tgt
  ls_remote "$SRC_HOST" "$SRC_PATH"
  ask_yes_no "Copy files from $SRC_HOST to $TGT_HOST ?" || return 0
  ssh $TGT_HOST "sudo mkdir -p $TGT_PATH"
  ssh $SRC_HOST "sudo tar cf - -C $SRC_PATH ." \
  | ssh $TGT_HOST "sudo tar xvf - -C $TGT_PATH"
  ssh $TGT_HOST "sudo chown -R --reference=$TGT_PATH $TGT_PATH/"
  ssh $TGT_HOST "sudo find $TGT_PATH -type d -exec chmod --reference=$TGT_PATH {} \;"
  ssh $TGT_HOST "sudo find $TGT_PATH -type f -exec chmod 0640 {} \;"
}



### MAIN
get_src_host "$1"

get_tgt_host "$2"

get_action "$3"

# pre-clean target?
clean_remote "$TGT_HOST" "$TGT_PATH"

# transfer files
copy_files

# clean source?
clean_remote "$SRC_HOST" "$SRC_PATH"

echo "Completed in $SECONDS seconds"

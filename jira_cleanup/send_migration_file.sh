### VARIABLES
SRC_HOST=jira-test
SRC_PATH=/usr/services/jirahome/export/projectconfigurator
# TGT_HOST=jira-dev-m1
TGT_PATH=/srv/jira/home/import/projectconfigurator


### FUNCTIONS
ask_yes_no() {
  local rv=1
  local msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg"
  select yn in "Yes" "No"; do
    case $yn in
      Yes) rv=0;;
      No ) rv=1;;
    esac
    break
  done
  return $rv
}


die() {
  echo "ERROR: $*" 1>&2
  exit 99
}


clean_tgt() {
  echo "Clean up old files on $TGT_HOST:"
  ssh $TGT_HOST "sudo find $TGT_PATH -type f -print -delete"
  echo
}


copy_files() {
  # copy from src to tgt
  echo "Copy files from $SRC_HOST to $TGT_HOST:"
  ssh $TGT_HOST "sudo mkdir -p $TGT_PATH"
  ssh $SRC_HOST "sudo tar vczf - -C ${SRC_PATH} ." | ssh $TGT_HOST "sudo tar xzf - -C $TGT_PATH"
  ssh $TGT_HOST "sudo find $TGT_PATH -type f -exec chown jira:jira {} \;"
  # confirm file exists on target, exit if transfer failed
  echo
}


clean_src() {
  # delete files from src
  echo "Delete source files:"
  ssh $SRC_HOST "sudo find $SRC_PATH -type f -print -delete"
  echo
}


ls_tgt() {
  # list files on tgt
  echo "Files on $TGT_HOST:"
  ssh $TGT_HOST "sudo find $TGT_PATH -type f -print"
  echo
}


ls_src() {
  # list files on tgt
  echo "Files on $SRC_HOST:"
  ssh $SRC_HOST "sudo find $SRC_PATH -type f -print"
  echo
}


get_host() {
  TGT_HOST="$1"
  [[ -z "$TGT_HOST" ]] && die "Missing target hostname"
}

### MAIN
get_host "$1"

ls_tgt
ask_yes_no "Clean target ($TGT_HOST)? " && clean_tgt

ask_yes_no "Copy Files? " && copy_files

ls_src
ask_yes_no "Clean source ($SRC_HOST)? " && clean_src

ls_tgt

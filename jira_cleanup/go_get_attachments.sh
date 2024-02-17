#!/usr/bin/bash

set -x

###
# VARIABLES
###
WORK_DIR=~/working/atlassian-tools/jira_cleanup
TAR_INPUT=attachments_dirlist.txt
# REMOTE_HOST=jira-test
REMOTE_HOST=jira-old


###
# FUNCTIONS
### 

push_file() {
  local _fn="$1"
  scp "$_fn" ${REMOTE_HOST}:.
}


get_remote_attachments() {
  TGT_DIR="${WORK_DIR}"/attachments
  rm -rf "${TGT_DIR}"
  mkdir -p  "${TGT_DIR}"
  ssh $REMOTE_HOST "sudo tar vcf - -T /home/aloftus/$TAR_INPUT --exclude=thumbs" \
  | tar -x -C "${TGT_DIR}" --strip-components=7 -f -
}


cleanup() {
  : pass
}

###
# MAIN
###

push_file ${WORK_DIR}/${TAR_INPUT}

get_remote_attachments

cleanup

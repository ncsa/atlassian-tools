#!/usr/bin/bash

### VARIABLES
BASE=$( dirname "$0" )
HOST=jira-test
MY_CNF="${BASE}"/my.cnf.${HOST}


### FUNCTIONS
die() {
  echo "ERROR $*" 2>&1
  exit 99
}

prep() {
  [[ -f "${MY_CNF}" ]] || die "File not found '${MY_CNF}'"
  rsync "${MY_CNF}" ${HOST}:.my.cnf
}


run_sql() {
  fn="$1"
  cat "$fn" | ssh $HOST 'mysql'
}


ls_link_counts() {
  run_sql "${BASE}"/ls_link_counts.sql
}


get_link_counts() {
  ptrn="$1"
  ls_link_counts | grep -F -e "$ptrn" | cut -f1
}


fix_epic_story_links() {
  # get starting link counts
  declare -A before after
  before[Epic-Story]=$( get_link_counts 'Epic-Story' )
  echo "link count Epic-Story: ${before[Epic-Story]}"
  before[Parent-Child]=$( get_link_counts 'Parent-Child' )
  echo "link count Parent_Child: ${before[Parent-Child]}"

  # apply fixes
  run_sql "${BASE}"/fix_epic_story_links.sql
  run_sql "${BASE}"/update_parent_child.sql

  # get ending link counts
  after[Epic-Story]=$( get_link_counts 'Epic-Story' )
  echo "link count Epic-Story: ${after[Epic-Story]}"
  after[Parent-Child]=$( get_link_counts 'Parent-Child' )
  echo "link count Parent_Child: ${after[Parent-Child]}"

  if [[ ${after[Parent-Child]} -ne ${before[Epic-Story]} ]]; then
    die "ERROR - before count ${before[Epic-Story]} does NOT equal after count ${after[Parent-Child]}"
  fi
}


fix_users() {
  run_sql "${BASE}"/fix_users.sql
}


fix_bad_sprints() {
  # run_sql "${BASE}"/fix_svcplan_sprints.sql
  run_sql "${BASE}"/ls_bad_sprints.sql
  run_sql "${BASE}"/fix_bad_sprints.sql
  run_sql "${BASE}"/ls_bad_sprints.sql
}


### MAIN
prep

set -x

# Not needed anymore
# fix_epic_story_links

fix_users

# https://appfire.atlassian.net/servicedesk/customer/portal/11/SUPPORT-165938
fix_bad_sprints

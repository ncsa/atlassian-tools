#!/usr/bin/bash

### VARIABLES
BASE=$( dirname "$0" )


### FUNCTIONS

die() {
  echo "ERROR: $*" 1>&2
  exit 99
}

prep() {
  rsync "$BASE"/pgpass.cnf ${HOST}:.pgpass
  ssh ${HOST} chmod 600 .pgpass
}


test_conn() {
  ssh $HOST 'pg_isready -d jsmdb -h localhost -U jsmdb_user'
}


run_sql() {
  fn="$1"
  cat "$fn" | ssh $HOST 'psql -d jsmdb -h localhost -U jsmdb_user'
}


update_parent_child_linktype() {
  run_sql "$BASE"/update_parent_child.sql
}


### MAIN
HOST="$1"
[[ -z "$HOST" ]] && die "Missing hostname"

prep

test_conn || die "connection not ready"

# update_parent_child_linktype

run_sql "$BASE"/ls_link_counts.sql

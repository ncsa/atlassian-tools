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


### MAIN
HOST="$1"
[[ -z "$HOST" ]] && die "Missing hostname"

FN="$2"
[[ -z "$FN" ]] && die "Missing filename"
case "$FN" in
  (/*) SQL="$FN" ;;
  (*) SQL="${BASE}/${FN}" ;;
esac
[[ -r "$SQL" ]] || die "Cannot read file '$SQL'"

prep

test_conn || die "connection not ready"

run_sql "$SQL"

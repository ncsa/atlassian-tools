#!/usr/bin/bash

### VARIABLES
BASE=$( dirname "$0" )
HOST=''
CONF=''
FILES=()
PGHOST=''
PGUSER=''
PGPORT=''
PGDB=''


### FUNCTIONS

die() {
  echo "ERROR: $*" 1>&2
  kill 0
  exit 99
}


get_host() {
  HOST="$1"
  [[ -z "$HOST" ]] && die 'Missing host'
}


get_files() {
  local _fn
  for _fn in "${@}"; do
    [[ -f "${_fn}" ]] || die "File not found '${_fn}'"
    FILES+=( "${_fn}" )
  done
  [[ ${#FILES[@]} -lt 1 ]] && die "Missing sql files for host: '$HOST'"
}


prep() {
  CONF=~/.pgpass.cnf.${HOST}
  [[ -f "${CONF}" ]] || die "config file not found '${CONF}'"
  rsync "${CONF}" ${HOST}:.pgpass
  ssh ${HOST} chmod 600 .pgpass
}


get_connection_parameters() {
  PGHOST=$( head -1 "${CONF}" | cut -d: -f1 )
  PGPORT=$( head -1 "${CONF}" | cut -d: -f2 )
  PGDB=$( head -1 "${CONF}" | cut -d: -f3 )
  PGUSER=$( head -1 "${CONF}" | cut -d: -f4 )
}


test_connection() {
  ssh $HOST "pg_isready -q -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER}"
}


run_sql() {
  fn="$1"
  # cat "$fn" | ssh $HOST 'psql -d jsmdb -h localhost -U jsmdb_user'
  cat "$fn" | ssh $HOST "psql -h ${PGHOST} -p ${PGPORT} -d ${PGDB} -U ${PGUSER}"
}


### MAIN
get_host "$1"
shift
get_files "${@}"

prep

get_connection_parameters

test_connection || die "connection not ready"

for fn in "${FILES[@]}"; do
  set -x
  run_sql "$fn"
  set +x
  echo
done

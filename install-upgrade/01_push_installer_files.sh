#!/usr/bin/bash

die() {
  echo "ERROR: $*" 1>&2
  exit 1
}

REMOTE_HOST="$1"
[[ -z "$REMOTE_HOST" ]] && die "missing remote host"

APP="$2"
[[ -z "$APP" ]] && die "missing app name"
[[ -d "$APP" ]] || die "no directory matching name '$APP'"

/usr/bin/ssh "${REMOTE_HOST}" "mkdir -p ${HOME}/${APP}"
/usr/bin/rsync -rtvPL "${APP}"/ "${REMOTE_HOST}":"${APP}"
/usr/bin/rsync -tvP ./02_installer.sh "${REMOTE_HOST}":"${APP}"

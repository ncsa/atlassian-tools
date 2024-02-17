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

/usr/bin/rsync -rtvPL \
  --rsync-path='sudo rsync' \
  "${APP}"/ \
  "${REMOTE_HOST}":/root/atlassian-tools/install-upgrade/"${APP}"

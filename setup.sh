#!/bin/bash

set -x

BASE=$( dirname $0 )
TS=$(date +%s)
INSTALL_DIR="${HOME}"/atlassian-tools

# Install regular dir contents
for d in bin conf lib jira_cleanup wiki_cleanup ; do
  tgt="$INSTALL_DIR/$d"
  src="$BASE/$d"
  mkdir -p "$tgt"
  find "$src" -type f -print0 \
  | xargs -0 install -vbC --suffix="$TS" -t "$tgt"
done

# Install installer/upgrader parts
iu_src="${BASE}"/install-upgrade
iu_tgt="${INSTALL_DIR}"/install-upgrade
mkdir -p "$iu_tgt"
for f in "$iu_src"/*.sh; do
  install -vbC "$f" --suffix="$TS" -t "$iu_tgt"
done
for d in jira confluence; do
  src="${iu_src}"/"$d"
  tgt="${iu_tgt}"/"$d"
  mkdir -p "$tgt"
  find "$src" -type f -print0 \
  | xargs -0 install -vbC --suffix="$TS" -t "$tgt"
done

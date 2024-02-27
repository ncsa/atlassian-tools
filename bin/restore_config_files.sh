#!/bin/bash

set -e

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh
. ${BASE}/lib/utils.sh

[[ $VERBOSE -eq $YES ]] && set -x

FILES=( 
  "${APP_INSTALL_DIR}"/conf/server.xml
)

for f in "${FILES[@]}" ; do
  tgt_dir=$( dirname "$f" )
  reference=$( find "$tgt_dir" -type f -print -quit )
  cp "${BACKUP_DIR}/${f}" "${f}"
  chmod --reference="$reference" "$f"
  chown --reference="$reference" "$f"
done

success "restored (designated) config files"

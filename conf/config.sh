YES=1
NO=0

### START OF USER CONFIGURABLE SECTION
#
#

# These must be set or scripts will refuse to run
IPADDR_OLD=
IPADDR_NEW=
HOSTNAME_OLD=
HOSTNAME_NEW=


# path to jira / confluence home & install dirs
APP_HOME_DIR=/usr/services/jirahome
APP_INSTALL_DIR=/usr/services/jira-standalone
# Jira/Confluence DB names
DB_NAME_OLD=
DB_NAME_NEW=

# arrays of service names
SYSTEM_SERVICES_TO_STOP=( puppet crashplan jira )
PUPPET_SERVICES_TO_STOP=( telegraf )

VERBOSE=$YES
DEBUG=$YES

#
#
### END OF USER CONFIGURABLE SECTION

TODAY=$(date +%Y%m%d)
NOW=$(date +%Y%m%dT%H%M%S)

# ANSI escape codes for colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

[[ $DEBUG -eq $YES ]] && VERBOSE=$YES


# validate_config
varnames=( \
  TODAY \
  NOW \
  IPADDR_OLD \
  IPADDR_NEW \
  HOSTNAME_OLD \
  HOSTNAME_NEW \
  APP_HOME_DIR \
  APP_INSTALL_DIR \
  DB_NAME_OLD \
  DB_NAME_NEW \
  SYSTEM_SERVICES_TO_STOP \
  PUPPET_SERVICES_TO_STOP
)
for v in "${varnames[@]}"; do
  if [[ -z "${!v}" ]] ; then
    echo "FATAL: Config var '${v}' must be set" 1>&2
    exit 1
  fi
done

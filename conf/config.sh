YES=1
NO=0

TODAY=$(date +%Y%m%d)
NOW=$(date +%Y%m%dT%H%M%S)

### START OF USER CONFIGURABLE SECTION
#
#

# if any of these are unset, prompt for value at runtime
IPADDR_NEW=
HOSTNAME_NEW=


# path to jira / confluence home & install dirs
APP_HOME_DIR=/usr/services/jirahome
APP_INSTALL_DIR=/usr/services/jira-standalone
# Jira/Confluence DB names
DB_NAME_OLD=
DB_NAME_NEW=

# arrays of service names
SYSTEM_SERVICES_TO_STOP=( puppet crashplan )
PUPPET_SERVICES_TO_STOP=( telegraf )

VERBOSE=$YES
DEBUG=$YES

#
#
### END OF USER CONFIGURABLE SECTION

[[ $DEBUG -eq $YES ]] && VERBOSE=$YES

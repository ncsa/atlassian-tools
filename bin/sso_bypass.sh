#!/bin/bash

die() {
  echo "ERROR - $*" 1>&2
  exit 99
}

get_netrc_value() {
    local _machine=$1
    local _key=$2

    awk -v machine="$_machine" -v key="$_key" '
      $1 == "machine" && $2 == machine {found=1}
      found && $1 == key {print $2; exit}
      $1 == "machine" && $2 != machine {found=0}
      ' ~/.netrc
}

verify_auth_fallback_status() {
  echo "$1"
  local _status=$1
  local _verify=$(echo $_status | awk '
    /"enable-authentication-fallback":true/ {print 0}
    /"enable-authentication-fallback":false/ {print 1}
  ')
  
  if [[ "$MODE" == "true" && "$_verify" == "0" ]]; then 
    echo "SSO Bypass successfully enabled"
    echo "To login with username/password, go to: https://$MACHINE/login.jsp?auth_fallback"
    exit 0
  elif [[ "$MODE" == "false" && "$_verify" == "1" ]]; then 
    echo "SSO Bypass successfully disabled"
    exit 0
  elif [[ "$MODE" == "true" && "$_verify" == "1" ]]; then 
    echo "SSO Bypass unsuccessfully enabled"
    exit 1
  else 
    echo "SSO Bypass unsuccessfully disabled"
    exit 1
  fi
}

request_auth_fallback() {
  local _endpoint="https://"$MACHINE"/rest/authconfig/1.0/sso"
  local _token=$(get_netrc_value "$MACHINE" "$KEY")
  if [[ -z "$_token" ]] ; then
    die "Unable to find '$KEY' for '$MACHINE' in netrc file"
  fi

  local _status=$(curl -s --location --request PATCH "$_endpoint" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $_token" \
  --data '{
  "enable-authentication-fallback": '"$MODE"'
  }')

  verify_auth_fallback_status "$_status"
}

print_usage() {
  local _prg="./sso_bypass"
  cat <<ENDHERE
${_prg}
  Enable/Disable SSO Bypass on Confluence
  Requires: Valid credentials in ~/.netrc 

SYNOPSYS
  ${_prg} [OPTIONS] HOSTNAME ACTION

  Ex. ${_prg} jira.ncsa.illinois.edu enable
  Ex. ${_prg} wiki.ncsa.illinois.edu disable

OPTIONS
  -h --help Print this help
  -t --token   Name of the netrc token that has the Personal Access Token (from the Atlassian app)
ENDHERE
} 

# if [[ $# -eq 0 ]]; then 
#   echo "Error: No options were included"
#   echo "Run with -h option for help."
#   exit 1
# fi

KEY="account"
ENDWHILE=0
while [[ $# -gt 0 ]] && [[ $ENDWHILE -lt 0 ]] ; do
  case $1 in
    -h|--help) print_usage; exit 0;;
    -t|--token)
      KEY=$2
      shift
      ;;
    --) ENDWHILE=1;;
    -*) die "Invalid option '$1'";;
     *) ENDWHILE=1; break;;
  esac
  shift
done
MACHINE="$1"
ACTION="$2"

if [[ -z "$MACHINE" ]]; then
  die "missing HOSTNAME"
fi

if [[ -z "$ACTION" ]]; then
  die "missing ACTION"
fi

case $ACTION in
  enable) MODE="true";;
  disable) MODE="false";;
  *)
    die "Invalid ACTION '$ACTION'. Must be one of 'enable', 'disable'"
    ;;
esac

request_auth_fallback

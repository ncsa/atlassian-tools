MODE="false"
# KEY="password"

get_netrc_value() {
    local _machine=$1
    local _key=$2

    awk -v machine="$_machine" -v key="$_key" '
      $1 == "machine" && $2 == machine {found=1}
      found && $1 == key {print $2; exit}
      $1 == "machine" && $2 != machine {found=0}
      ' ~/.netrc
}

is_object_null() {
  local _obj=$1
  if [ -z "$_obj" ]; then 
    echo "Error: Either Base URL, key type, or Access Token was not provided"
    echo "Run with -h option for help."
    exit 1
  fi
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
    echo "Access site at http://$MACHINE/login.action?auth_fallback to login."
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
  is_object_null "$MACHINE"
  is_object_null "$KEY"
  local _endpoint="https://"$MACHINE"/rest/authconfig/1.0/sso"
  local _token=$(get_netrc_value "$MACHINE" "$KEY")
  is_object_null "$_token"

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
  Require: Save auth in .netrc 
SYNOPSYS
  ${_prg} [OPTIONS] [BASE URL] [KEY TYPE]

  Ex. ${_prg} -e confluence.com account
OPTIONS
  -h --help Print this help
  -e --enable Turn on SSO Bypass 
  -d --disable Turn off SSO Bypass
ENDHERE
} 

if [[ $# -eq 0 ]]; then 
  echo "Error: No options were included"
  echo "Run with -h option for help."
  exit 1
fi

ENDWHILE=0
while [[ $# -gt 0 ]]  && [[ ENDWHILE -eq 0 ]] ; do 
  case $1 in 
    -h| --help) print_usage; exit 1;;
    -e| --enable) MACHINE="$2"; KEY="$3"; MODE="true"; request_auth_fallback;;
    -d| --disable) MACHINE="$2"; KEY="$3"; MODE="false"; request_auth_fallback;;
     *) echo "Invalid option '$1'"; exit 1;;
  esac 
  shift
done


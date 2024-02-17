#!/bin/bash

BASE=${HOME}/atlassian-tools

. ${BASE}/conf/config.sh


err() {
	echo -e "${RED}✗ ERROR: $*${NC}" 1>&2
}

success() {
  echo -e "${GREEN}✓ $*${NC}"
}


die() {
  err "$*"
  echo "from (${BASH_SOURCE[1]} [${BASH_LINENO[0]}] ${FUNCNAME[1]})"
  kill 0
  exit 99
}


ask_user() {
  # INPUT
  #   $1 prompt
  # OUTPUT
  #   user response as text string
  local _msg="$1"
  [[ -z "$_msg" ]] && die "missing prompt in ask_user()"
  read -r -p "$_msg"
  echo "$REPLY"
}


ask_yes_no() {
  local rv=$NO
  local msg="Is this ok?"
  [[ -n "$1" ]] && msg="$1"
  echo "$msg"
  select yn in "Yes" "No"; do
    case $yn in
      Yes) rv=$YES;;
      No ) rv=$NO;;
    esac
    break
  done
  return $rv
}


# Function to print a green checkmark
print_green_checkmark() {
    echo -e "${GREEN}✓${NC}"
}

# Function to print a red "x"
print_red_x() {
    echo -e "${RED}✗${NC}"
}


# ask user to choose an installer
get_installer() {
  local _installer
  local _sources="${BASE}"/install-upgrade/"${APP_NAME}"
  local _files=( $( /usr/bin/find "${_sources}" \
    -type f \
    -name 'atlassian*.bin' \
    -print \
    | /usr/bin/sort -V )
  )
  oldPS3="$PS3"
  PS3="Choose installer, or quit? "
  select fn in 'quit' "${_files[@]}" ; do
    case $fn in
      (quit) die "User cancelled" ;;
      (*) _installer="$fn" ;;
    esac
    break
  done
  PS3="$oldPS3"
  echo "$_installer"
}

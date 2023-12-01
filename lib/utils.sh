#!/bin/bash

BASE=/root/atlassian-tools

. ${BASE}/conf/config.sh


err() {
	echo -e "${RED}✗ ERROR: $*${NC}" 1>&2
}

success() {
  echo -e "${GREEN}✓ $*${NC}"
}


die() {
  err "$*"
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


# Function to print a green checkmark
print_green_checkmark() {
    echo -e "${GREEN}✓${NC}"
}

# Function to print a red "x"
print_red_x() {
    echo -e "${RED}✗${NC}"
}

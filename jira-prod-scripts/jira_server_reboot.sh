#!/bin/bash

echo "Starting at: $(date)"

/bin/systemctl stop jira

/bin/sleep 120

/sbin/shutdown --reboot +1 "System rebooting in 1 minute"

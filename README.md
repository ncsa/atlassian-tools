# atlassian-tools
Atlassian tools and scripts for Confluence and Jira servers

# INSTALL
Install onto the production server.
```
export QS_GIT_REPO=https://github.com/ncsa/atlassian-tools.git
#export QS_GIT_BRANCH=branch_name  #optional - specify a branch other than main
curl https://raw.githubusercontent.com/andylytical/quickstart/main/quickstart.sh | bash
```

# Make a test instance from a clone of prod
Create a copy of prod for testing
1. Prod server:
   1. Install this repo via the instructions above
   1. NOTE: Installer is idempotent (can run multiple times). It will only update
      old files and will make backups of any files to be replaced.
1. VMware:
   1. Clone the prod server to a test VM
   1. Disconnect the network on the test server
   1. Start the test server
   1. On the console of the test server, run:
      1. `/root/atlassian-tools/bin/jira_mktest.sh`
      1. `/root/atlassian-tools/bin/jira_validate.sh`
      1. `shutdown -h now`
   1. Ensure test VM is powered off
   1. Re-enable the network
   1. Power-on the test VM

# Install / Upgrade Jira
This should also work for Confluence, but is untested as of 6 Oct 2023.
1. Follow the instructions above to create a test VM cloned from prod
1. Clone this repo to a local machine
1. `cd atlassian-tools/install-upgrade`
1. Download the latest atlassian installer into the appropriate directory
  (ie: 'confluence/' or 'jira/')
1. `./01_push_installer_files.sh <target-host> <APP>`
   1. ... where `<APP>` is one of `confluence` or `jira`
1. SSH to the target host, escalate to root
   1. For Install: `/home/<USER>/<APP>/02_installer.sh`
      1. Note: 02_installer.sh will pick the latest installer version found
         in the directory unless a filename is specified on the cmdline.
      1. Note: The installer will read the install config from `response.varfile`
      1. Note: Use `-h` for more help
   1. For Upgrade:
      1. Run the installer file manually, choose option 3 (upgrade)
      1. Restore the server.xml file:
         1. `/home/<USER>/<APP>/02_installer.sh -c`

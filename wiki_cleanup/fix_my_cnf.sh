#!/bin/bash

# See also: https://confluence.atlassian.com/doc/database-setup-for-mysql-128747.html

MY_CNF=/etc/my.cnf

sed \
  -e '/^#/ d' \
  -e '/\[mysqld\]/ a \
default-storage-engine=INNODB \
binlog_format=row \
log_bin_trust_function_creators = 1' \
  -e '/character-set-server=/ c character-set-server=utf8mb4' \
  -e '/collation-server=/ c collation-server=utf8mb4_bin' \
  -e '/innodb_log_file_size=/ c innodb_log_file_size=2GB' \
  $MY_CNF

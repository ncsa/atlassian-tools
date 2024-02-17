#!/usr/bin/bash

# Exit script if any command fails
set -e

set -x
JAVA=/srv/confluence/app/jre/bin/java
JAR=${HOME}/atlassian-tools/install-upgrade/confluence/atlassian-xml-cleaner-0.1.jar
RESTORE=/srv/confluence/home/restore
BACKDIR=/backups
XML=entities.xml
XML_OLD=$BACKDIR/$XML
XML_NEW=$RESTORE/$XML
ZIP=$(ls -t $RESTORE/xmlexport-*.zip | head -1)

unzip -l $ZIP
time unzip -d $BACKDIR $ZIP $XML
time $JAVA -jar $JAR $XML_OLD >$XML_NEW
time zip -j -u $ZIP $XML_NEW
unzip -l $ZIP
chown confluence:confluence $ZIP

echo "Total elapsed time: $SECONDS seconds"

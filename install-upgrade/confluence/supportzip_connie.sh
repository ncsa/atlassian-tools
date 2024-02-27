#!/bin/bash
######################
# supportzip_connie.sh
# Atlassian doc:
#   https://confluence.atlassian.com/x/BZgBQw 
# Versioning:
#   0.1 20220324 - Initial version
#   0.2 20220328 - Password sanitization
#   1.0 20220419 - Added thread dump
# To-do:
#   Consult perf data (DB latency, OS, etc)
######################
USER=`whoami`
WHEREAMI=`pwd`
DATE=`date +%Y-%m-%d-%H-%M-%S`
TD=0

########THE OPTIONS#####
usage() { echo "Usage: $0 [-h <Confluence home path>] [-a <Confluence app path>] -t
          -h: obligatory, absolute path of Confluence home directory
          -a: obligatory, absolute path of Confluence application directory
          -t: optional, to run and collect thread dumps" 1>&2; exit 1; }
while getopts ":a:h:t" o; do
    case $o in
        h|H)
            h=${OPTARG}
            ;;
        a|A)
            a=${OPTARG}
            ;;
        s|S)
            s=${OPTARG}
            ;;
        t|T)
            TD=1
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z $h ] || [ -z $a ]; then
    usage
fi

###############THE PATHS
CONFAPP=$a
CONFHOME=$h
SHAREDHOME=$s
BEXPORT=$CONFHOME/export
LOG=$BEXPORT/Confluence_support_$DATE.log
EXPORT=$BEXPORT/Confluence_support_$DATE




echo '
        __          ------------------------------------------
 _(\    |@@|        | Beep - Generating Atlassian Support Zip  |
(__/\__ \--/ __    /_------------------------------------------
   \___|----|  |   __
       \ }{ /\ )_ / _\
       /\__/\ \__O (__
      (--/\--)    \__/
      _)(  )(_
     `---''---`
'
echo "
##############################
# Atlassian support zip tool #
##############################
User = $USER
Confluence Home = $CONFHOME
Confluence App Directory = $CONFAPP

Hit CTRL+C (10s wait) if any path or user is incorrect.
"
sleep 10

echo "`date +%Y-%m-%d-%H-%M-%S` - Start creating the Support Zip file" >> $LOG
#Create the basic structure
mkdir -p $EXPORT/{application-config,application-logs,application-properties,auth-cfg,cache-cfg,confluence-customisations,healthchecks,thread-dump,synchrony-config,tomcat-config,tomcat-logs}
mkdir -p $EXPORT/confluence-customisations/layouts

#application-logs
echo ' - Packing application logs'
echo "`date +%Y-%m-%d-%H-%M-%S` - application-logs" >> $LOG
cp -f $CONFHOME/logs/* $EXPORT/application-logs/

# application-config
#Confluence configuration files
echo ' - Packing application config files'
echo "`date +%Y-%m-%d-%H-%M-%S` - application-config" >> $LOG


cat $CONFHOME/confluence.cfg.xml | sed 's/password\"\>.*/password\"\>Sanitized by Support Utility\<\/property\>/g' | sed 's/username\"\>.*/username\"\>Sanitized by Support Utility\<\/property\>/g' > $EXPORT/application-config/confluence.cfg.xml
#OLD cat -> cat $CONFHOME/confluence.cfg.xml | sed 's/password\"\>.*/password\"\>Sanitized by Support Utility/g' | sed 's/username\>.*/username\"\>Sanitized by Support Utility/g' > $EXPORT/application-config/confluence.cfg.xml
##<property name="hibernate.connection.password">Sanitized by Support Utility</property>
##<property name="hibernate.connection.username">Sanitized by Support Utility</property>

cp -f $CONFAPP/confluence/WEB-INF/classes/{confluence-init.properties,log4j-diagnostic.properties,log4j.properties} $EXPORT/application-config/
cp -f $CONFAPP/confluence/WEB-INF/classes/logging.properties $EXPORT/application-config/logging.properties
cp -f $CONFAPP/confluence/WEB-INF/web.xml $EXPORT/application-config/web.xml
cp -f $CONFAPP/bin/{setclasspath.sh,setclasspath.bat,setenv.sh,setenv.bat,shutdown.sh,shutdown.bat,start-confluence.sh,start-confluence.bat,startup.sh,startup.bat,stop-confluence.sh,stop-confluence.bat} $EXPORT/application-config/ 

for i in setclasspath.sh setclasspath.bat setenv.sh setenv.bat shutdown.sh shutdown.bat start-confluence.sh start-confluence.bat startup.sh startup.bat stop-confluence.sh stop-confluence.bat ; do  tmp=`echo $i | sed 's/\./-/g'`; mv $EXPORT/application-config/$i $EXPORT/application-config/$tmp.txt; done

#auth-cfg
#If exists <confluence-home>/logs/support (possibly will gather old data) will grab the file however changing name to avoid confusion

echo ' - Packing configuration summary, if any available'
echo "`date +%Y-%m-%d-%H-%M-%S` - auth-cfg" >> $LOG
if [ -f $CONFHOME/logs/support/directoryConfigurationSummary.txt ]; then
    echo ' - Packing the last directoryConfigurationSummary available.'
    cat $CONFHOME/logs/support/directoryConfigurationSummary.txt | sed 's/password:.*/password: Sanitized by Support Utility/g' > $EXPORT/auth-cfg/`ls -l $CONFHOME/logs/support/directoryConfigurationSummary.txt | awk -F' ' '{print $6"-"$7}'`.directoryConfigurationSummary.txt;
fi

echo ' - Packing seraph and crowd configuration files'
echo "`date +%Y-%m-%d-%H-%M-%S` - auth-cfg" >> $LOG
cp -f $CONFAPP/confluence/WEB-INF/classes/{crowd.properties,seraph-config.xml,seraph-paths.xml} $EXPORT/auth-cfg/


#confluence-customisations
echo ' - Packing confluence customisations files'
echo "`date +%Y-%m-%d-%H-%M-%S` - confluence-customisations" >> $LOG
cp -f $CONFHOME/logs/support/{customHtml.txt,customStylesheet.txt}} $EXPORT/confluence-customisations
echo ' - Packing custom layouts files'
echo "`date +%Y-%m-%d-%H-%M-%S` - confluence-customisations/layouts" >> $LOG
cp -f $CONFHOME/logs/support/customLayouts.txt $EXPORT/confluence-customisations/layouts
cp -f $CONFHOME/logs/support/*.vmd $EXPORT/confluence-customisations/layouts

#synchrony-config
echo ' - Packing synchrony configuration file'
echo "`date +%Y-%m-%d-%H-%M-%S` - synchrony-config" >> $LOG
cp -f $CONFHOME/synchrony-args.properties $EXPORT/synchrony-config


################################################
########   Double check this one for shared home folder on DC
################################################
#cache-cfg
echo ' - Packing cache configuration files'
echo "`date +%Y-%m-%d-%H-%M-%S` - cache-cfg" >> $LOG
cp -f $SHAREDHOME/cache-settings-overrides.properties $EXPORT/cache-cfg


#tomcat-config
echo ' - Packing tomcat configuration files'
echo "`date +%Y-%m-%d-%H-%M-%S` - tomcat-config" >> $LOG
cp -f $CONFAPP/conf/{catalina.policy,catalina.properties,context.xml,jaspic-providers.xml,logging.properties,server.xml,tomcat-users.xml,web.xml} $EXPORT/tomcat-config 

#sanitization
cd $EXPORT/tomcat-config; cat server.xml  | sed 's/keystorePass=\".*\"/keystorePass=\"Sanitized by Support Utility\"/g' | sed "s/keystorePass=\'.*\'/keystorePass=\'Sanitized by Support Utility\'/g" > server.xml.tmp; mv -f server.xml.tmp server.xml
cd $EXPORT/tomcat-config; cat tomcat-users.xml | sed 's/password=\".*\"/password=\"Sanitized by Support Utility\"/g' > tomcat-users.xml.tmp; mv -f tomcat-users.xml.tmp tomcat-users.xml

#healthchecks				
#If exists <confluence-home>/logs/support (possibly will gather old data) will grab the file however changing name to avoid confusion
echo ' - Packing healthcheckResults, if any available'
echo "`date +%Y-%m-%d-%H-%M-%S` - healthchecks" >> $LOG
if [ -f $CONFHOME/logs/support/healthcheckResults.txt ]; then  
   ## cp -f $CONFHOME/logs/support/healthcheckResults.txt $EXPORT/healthchecks/`ls -l $CONFHOME/logs/support/healthcheckResults.txt | awk -F' ' '{print $6"-"$7}'`.healthcheckResults.txt; 
   cp -f $CONFHOME/logs/support/healthcheckResults.txt $EXPORT/healthchecks
fi

#tomcat-logs
echo ' - Packing Tomcat logs'
echo "`date +%Y-%m-%d-%H-%M-%S` - tomcat-logs" >> $LOG
#find $CONFAPP/logs -type f \( ! -iname "access_log*" \) -mtime -10  -exec cp -a "{}" $EXPORT/tomcat-logs \;
cp -f $CONFAPP/logs/* $EXPORT/tomcat-logs 

#application-properties
#If exists <confluence-home>/logs/support (possibly will gather old data) will grab the file however changing name to avoid confusion
echo ' - Packing the application.xml, if any available'
echo "`date +%Y-%m-%d-%H-%M-%S` - application-properties" >> $LOG
if [ -f $CONFHOME/logs/support/application.xml ]; then  
    ## cp -f $CONFHOME/logs/support/application.xml $EXPORT/application-properties/`ls -l $CONFHOME/logs/support/application.xml | awk -F' ' '{print $6"-"$7}'`.application.xml; 
    cp -f $CONFHOME/logs/support/application.xml $EXPORT/application-properties

fi


#thread-dump
if [ $TD == 1 ]
then 
    echo ' - Generating thread dumps -  this will take ~1 minute'
    echo "`date +%Y-%m-%d-%H-%M-%S` - thread dump" >> $LOG
    APP_PID=`ps aux | grep -i confluence | grep -i java | grep -v synchrony.core | awk  -F '[ ]*' '{print $2}'`;
    for i in $(seq 6); do top -b -H -p $APP_PID -n 1 > $EXPORT/thread-dump/threaddump_`date +%s`_cpu_usage.txt; jstack $APP_PID > $EXPORT/thread-dump/threaddump_`date +%s`.tdump; sleep 10; done

else
    echo ' - Thread dump will not be collected'
    echo "`date +%Y-%m-%d-%H-%M-%S` - no thread dump" >> $LOG
fi

#Pack and go
if [ -x "$(command -v zip)" ] ; then 
    echo; echo 'Creating zip file...'
    echo "`date +%Y-%m-%d-%H-%M-%S` - Packing as zip" >> $LOG
    cd $EXPORT
    zip -r ../Confluence_support_$DATE.zip ./* 2>&1 >> $LOG; 
    echo; echo "The support zip file can be found in $BEXPORT/Confluence_support_$DATE.zip, please upload this file to Atlassian."
    echo "."
    echo "Have a g'day =)"
    echo
else 
    echo; echo 'Zip not found, packing as tar.gz...'
    echo "`date +%Y-%m-%d-%H-%M-%S` - Zip not found, packing as tar.gz" >> $LOG
    cd $BEXPORT; tar -cvf Confluence_support_$DATE.tar $EXPORT/*; gzip Confluence_support_$DATE.tar 2>&1 >> $LOG;  
    echo; echo "The support zip file can be found in $BEXPORT/Confluence_support_$DATE.tar.gz, please upload this file to Atlassian."
    echo "."
    echo "Have a g'day =)"
    echo
fi


#EOF
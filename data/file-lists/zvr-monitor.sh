#!/bin/bash

id -u vyos > /dev/null 2>&1 && USER="vyos" || USER="zstack"
[ x"$USER" == x"vyos" ] && SERVER="/opt/vyatta/sbin/zvr" || SERVER="/usr/local/bin/zvr"

HOMDIR=/home/$USER/zvr
LOGFILE=$HOMDIR/zvrMonitor.log
BOOTSTRAPINFO=$HOMDIR/bootstrap-info.json

manageNicIp=$(grep -A 5 "managementNic" $BOOTSTRAPINFO | grep "ip" | awk '{print $2}')
if [ x$manageNicIp = x"" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') get managementNic ip failed " >> $LOGFILE
    exit
fi

manageNicIp=$(echo $manageNicIp | sed -e s/,// | sed -e s/\"//g)
if [ x$manageNicIp = x"" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') get managementNic ip failed " >> $LOGFILE
    exit
fi

##check zvr status
uri=http://$manageNicIp:7272/test
pid=$(ps aux | grep -w $SERVER | grep -v grep | awk '{print $2}' | head -1)
if [ x$pid = x"" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') zstack virtual router is stopped " >> $LOGFILE
else
    ret=$(timeout 5 curl -H "Content-Type: application/json; charset=utf-8" -H "User-Agent: curl" -X POST $uri)
    if [[ "$ret" =~ "\"success\":true" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') zstack virtual router pid: $pid is running " >> $LOGFILE
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') zstack virtual router pid: $pid, curl  $uri failed, $ret" >> $LOGFILE
    fi
fi

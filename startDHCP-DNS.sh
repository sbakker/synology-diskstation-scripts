#!/bin/sh
#nohup ./poll-dhcp-changes.sh >> /volume1/homes/admin/logs/dhcp-dns.log 2>&1 &
#nohup does not work on synology.  As a workaround, this script should be started from
# DSM task scheduler.
SCRIPT_DIR=/var/services/homes/admin/dhcp-dns
LOG_DIR=$SCRIPT_DIR/logs
LOG_CONTEXT="-"  #override to add extra stuff to log messages
date_echo(){
    datestamp=$(date +%F_%T)
    echo "${datestamp} ${LOG_CONTEXT} $*"
}
date_echo "is poll-dhcp-changes.sh running?"

if $(ps x > /dev/null 2>&1 ); then
  #apparently DSM 6.0 needs the x option for ps.  DSM 5.x does not have this option, but the default ps is good enough without options.
  PS="ps x"
else
  PS="ps"
fi

POLL_RUNNING=`$PS | grep poll-dhcp-changes | grep -v grep |wc -l`
if [ $POLL_RUNNING -gt "0" ]; then
  date_echo "poll-dhcp-changes already running."
else
  date_echo "starting poll-dhcp-changes"
  mkdir -p $LOG_DIR
  $SCRIPT_DIR/poll-dhcp-changes.sh >> $LOG_DIR/dhcp-dns.log 2>&1 
fi

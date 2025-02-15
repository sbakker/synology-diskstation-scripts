#!/bin/sh
# This script should be installed on a synology diskstation in this folder for automatic startup:
# /usr/local/etc/rc.d/
#
# For full functionality, these scripts should also be installed:
# /var/services/homes/admin/poll-dhcp-changes.sh
# /var/services/homes/admin/diskstation_dns_modify.sh
#
# See Readme.md on github  https://github.com/gclayburg/synology-diskstation-scripts
LOG_CONTEXT="-"  #override to add extra stuff to log messages
SCRIPT_DIR=/var/services/homes/admin/dhcp-dns

date_echo(){
    datestamp=$(date +%F_%T)
    echo "${datestamp} ${LOG_CONTEXT} $*"
}

if $(ps x > /dev/null 2>&1 ); then
  #apparently DSM 6.0 needs the x option for ps.  DSM 5.x does not have this option, but the default ps is good enough without options.
  PS="ps x"
else
  PS="ps"
fi

if [ "$1" = "start"  ]; then
#nohup ./poll-dhcp-changes.sh >> /var/services/homes/admin/logs/dhcp-dns.log 2>&1 &
#nohup does not work on synology.
  date_echo "is poll-dhcp-changes.sh running?"
  POLL_RUNNING=`$PS | grep poll-dhcp-changes | grep -v grep |wc -l`
  if [ $POLL_RUNNING -gt 0 ]; then
    date_echo "poll-dhcp-changes already running."
  else
    date_echo "starting poll-dhcp-changes"
    LOG_DIR=$SCRIPT_DIR/logs
    if [ ! -d "$LOG_DIR" ]; then
      mkdir -p $LOG_DIR
    fi
    $SCRIPT_DIR/poll-dhcp-changes.sh >>  $LOG_DIR/dhcp-dns.log 2>&1 &
  fi

elif [ "$1" = "stop" ]; then
  MYPID=`$PS | grep poll-dhcp-changes | grep -v grep | head -1 |awk -F' ' '{print $1}'`
  #if for some reason there are more than 1 poll-dhcp-changes process running, just kill the first one found.
  if [ "$MYPID" -gt 1 ]; then
    date_echo "killing PID: $MYPID"
    kill $MYPID
  fi
elif [ "$1" = "status" ]; then
  POLL_RUNNING=`$PS | grep poll-dhcp-changes | grep -v grep | wc -l`
  if [ "$POLL_RUNNING" -gt 0 ]; then
    date_echo "poll-dhcp-changes is running:"
    $PS | grep poll-dhcp-changes | grep -v grep
  else
    date_echo "poll-dhcp-changes is stopped."
  fi
fi


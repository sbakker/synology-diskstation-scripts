#!/bin/ash

SCRIPT_DIR=$(dirname $0)

WATCH_DIR=/etc/dhcpd
MAX_BACKOFF=60

LOG_CONTEXT='[info]'

date_echo(){
    datestamp=$(date +%F_%T)
    echo "${datestamp} ${LOG_CONTEXT} $*"
}

date_echo "poll-dhcp-changes.sh starting"

errors=0
while true; do
    changed=$(inotifywait \
        --quiet \
        --format '%f' \
        --event modify,create,delete,move \
        $WATCH_DIR)

    if test $? -eq 0; then
        date_echo "$WATCH_DIR/$changed changed - reloading DNS"
        $SCRIPT_DIR/diskstation_dns_modify.sh
        errors=0
    else
        if test $errors -lt $MAX_BACKOFF; then
            errors=$((errors + 1))
        fi

        LOG_CONTEXT='[error]' \
            date_echo "Error watching $WATCH_DIR -- retrying in $errors secs"
        sleep $errors
    fi
done

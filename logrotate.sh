#!/usr/bin/bash
#
# Rotate the dhcp-dns log file.
#
# Relevant settings:
#
#   LogRotate   - How many history copies to keep.
#   LogSize     - When to rotate (size in bytes).
#
# Since the log rotation trigger is on the log file size, it is
# safe to run this multiple times per day.
#

DFL_LOGSIZE=$(( 512 * 1024 ))
ROOT_DIR=$(dirname $0)

LogRotate=7
LogSize=$DFL_LOGSIZE

Main() {
    [[ -f $ROOT_DIR/settings ]] && source $ROOT_DIR/settings

    LogFile=$ROOT_DIR/logs/dhcp-dns.log
    LogSize=$(parse_size $LogSize)

    curr_size=$(stat -c '%s' $LogFile 2>&1 || echo 0)

    if [[ $curr_size -lt $LogSize ]]; then
        exit 0
    fi

    if [[ -f $LogFile.1 ]]; then
        rm -f $LogFile.1.gz
        gzip -9 $LogFile.1
    fi

    for dst in $( seq $LogRotate -1 1 ); do
        src=$(( dst - 1 ))
        if [[ -f $LogFile.$src.gz ]]; then
            mv $LogFile.$src.gz $LogFile.$dst.gz
        fi
    done

    # Cannot "mv" the $LogFile, because the dns script probably still
    # has it open. The trick is to copy the file and then truncate it.
    #
    # This carries a small risk of losing logging information between
    # the two statements. 🤷

    cp $LogFile $LogFile.1
    cat /dev/null > $LogFile
}

parse_size() {
    local size=$1

    if [[ $size =~ ^([0-9]+)$ ]]; then
        size=$(( ${BASH_REMATCH[1]} ))
    elif [[ $size =~ ^([0-9]+)[Kk]$ ]]; then
        size=$(( ${BASH_REMATCH[1]} * 1024 ))
    elif [[ $size =~ ^([0-9]+)[Mm]$ ]]; then
        size=$(( ${BASH_REMATCH[1]} * 1024**2 ))
    elif [[ $size =~ ^([0-9]+)[Gg]$ ]]; then
        size=$(( ${BASH_REMATCH[1]} * 1024**3 ))
    elif [[ $size =~ ^([0-9]+)[Tt]$ ]]; then
        size=$(( ${BASH_REMATCH[1]} * 1024**4 ))
    else
        echo "$0: bad LogSize '$size' - using $DFL_LOGSIZE"  >&2
        size=$DFL_LOGSIZE
    fi
    echo $size
}

Main
exit 0

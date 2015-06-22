#!/bin/bash
VM="vm-name"
DATE=`date +%Y-%m-%d`
LAST_SNAP=$DATE
LIST="$(VBoxManage snapshot $VM list | grep Name: | awk '{print $2}')"

# Input should be the number of days between when the snapshot was taken and now.
# Returns an integer of how many days should be between the last snapshot and the next.
freq_func() {
    let "ANS = (($1/7)**2)+1"
    echo $ANS
}

# Returns the number of days between two dates in the form YYYY-MM-DD
# arg1 should be greater than arg2
date_diff() {
    DIFF=$(ruby -rdate -e "puts Date.parse('$1') - Date.parse('$2')")
    cut -d "/" -f 1 <<< $DIFF # ruby returns N/1 and we want N
}

# Make todays snapshot
VBoxManage snapshot $VM take $DATE

# Cleanup old snapshots
IFS=$'\n'
while read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        DAYS_FROM_CURRENT=$(date_diff $DATE $i)
        DAYS_FROM_PREV=$(date_diff $LAST_SNAP $i)
        BACKUP_DIFF=$(freq_func $DAYS_FROM_CURRENT)

        if [ $DAYS_FROM_PREV -lt $BACKUP_DIFF ]; then
            VBoxManage snapshot $VM delete $i
        else
            LAST_SNAP=$i
        fi
    done
done <<< "$LIST"

#!/bin/bash
#
###
###
###
###   Purpose:   Running a backup job
cat /home/backup/input/backup_source.txt | \
while read d
do 
	echo "Backing up $d"
	/home/quagadmin/source/backuptools/bash/backup_data.sh -s $d -t /home/backup/data
done


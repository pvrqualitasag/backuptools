#!/usr/bin/bash
#
###
###
###
###   Purpose:   Compare original files with restored files
###   started:   2016/03/05 (pvr)
###
### ########################################################## ###

### # Define original and restore path
ORGPATH=/cygdrive/c/Users/Kathrin
RESTOREPATH=/cygdrive/d/Temp/RestoreFromBackup/Users/Kathrin

### # function
getmissingfile () {
  local l_src=$1
  local l_mis=$2
  
  find -L $l_src -type f | while read f
  do
    echo "Checking $l_mis/$f"
    if [ !-e "$l_mis/$f" ]
	then
	  echo "Cannot find: $l_mis/$f"
	fi
	sleep 2
  done
}

### # compare
ls -1 $RESTOREPATH | while read d
do 
  NRFILESORGPATH=`find $ORGPATH/$d -type f | wc -l` 
  NRFILESRESTOREPATH=`find $RESTOREPATH/$d -type f | wc -l`
  echo -n 'Original: '
  echo -n "$NRFILESORGPATH Dateien "
  echo -n `find $ORGPATH/$d -type d | wc -l`;echo -n ' Ordner '
  du -hbs $ORGPATH/$d
  echo -n 'Restore:  '
  echo -n "$NRFILESRESTOREPATH Dateien "
  echo -n `find $RESTOREPATH/$d -type d | wc -l`;echo -n ' Ordner '
  du -hbs $RESTOREPATH/$d
  
  ### # find differences
  if [ "$NRFILESORGPATH" -gt "$NRFILESRESTOREPATH" ]
  then
    getmissingfile $ORGPATH $RESTOREPATH
  fi
  if [ "$NRFILESORGPATH" -lt "$NRFILESRESTOREPATH" ]
  then
    getmissingfile $RESTOREPAT $ORGPATH 
  fi
  
done

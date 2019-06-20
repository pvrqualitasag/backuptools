#!/bin/bash
###
###
###
###   Purpose:   Backup Gogs Inside of docker
###   started:   2018-07-17 (pvr)
###
### ###################################################################### ###


# ================================ # ======================================= #
# global constants                 #                                         #
DRYRUN=TRUE                        # flag to do a dry-run experiment         #
GOGSCONTAINERNAME=gogs             # name of docker container running gogs   #
MOVEBCKINTERVAL=day                # interval of moving bcks to bck-server   # 
MOVEBCKDOW=7                       # day of week to move bcks                #
BCKUSR=u182727                     # user name on backup server              #
BCKSERVER=u182727.your-backup.de   # hostname of backup server               #
# -------------------------------- # --------------------------------------- #
# directories                      #                                         #
BACKUPTARGET=/backup/gogs/data     # backup target directory on host         #
SFTPTARGET=gogs/data               # target directory on bck server          #
INSTALLDIR=/opt/bashtools          # installation dir of bashtools on host   #
GOGSDIR=/app/gogs                  # installation dir of gogs in container   #
# -------------------------------- # --------------------------------------- #
# prog paths                       # required for cronjob                    #  
BASH=/bin/bash                     # PATH to bash-shell in container         #
LS=/bin/ls                         # PATH to ls                              #
ECHO=/bin/echo                     # PATH to echo                            #
SLEEP=/bin/sleep                   # path to sleep                           #
DATE=/bin/date                     # PATH to date                            #
BASENAME=/usr/bin/basename         # PATH to basename function               #
DOCKER=/usr/bin/docker             # PATH to docker executable on host       #
SFTP=/usr/bin/sftp                 # PATH to sftp program                    #
TAIL=/usr/bin/tail                 # path to tail                            #
GOGSPATH=$GOGSDIR/gogs             # PATH to gogs executable in container    #
# -------------------------------- # --------------------------------------- #
# derived constants                #                                         #              
GOGSBCKSTEM=$GOGSDIR/gogs-backup   # stem of produced backup-files by gogs   #
# ================================ # ======================================= #

#Set Script Name variable
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`
# Today's date
TDATE=`$DATE +"%Y%m%d"`

# Use utilities
UTIL=$INSTALLDIR/util/bash_utils.sh
source $UTIL


### # ====================================================================== #
### # functions
### # old backup files inside of the container are first removed
rm_old_bck () {
  $DOCKER exec $GOGSCONTAINERID $BASH -c "$LS -1 ${GOGSBCKSTEM}-*.zip 2> /dev/null" | \
  while read e
  do
    log_msg ' * rm_old_bck' "Removing old backup: $e"
    if [ "$DRYRUN" != "TRUE" ]
    then
      $DOCKER exec $GOGSCONTAINERID $BASH -c "rm $e"
    fi  
    $SLEEP 2
  done
  
}

### # the most recent backup is copied from inside of the container to a different disk on the host server
cp_cur_bck () {
  $DOCKER exec $GOGSCONTAINERID $BASH -c "$LS -1 ${GOGSBCKSTEM}-${TDATE}*.zip 2> /dev/null" | \
  while read e
  do 
    log_msg ' * cp_cur_bck' "Copying backupfile $e to $BACKUPTARGET"
    if [ "$DRYRUN" != "TRUE" ]
    then
      $DOCKER cp $GOGSCONTAINERID:$e $BACKUPTARGET
    fi  
    $SLEEP 2
  done
  
}

### # moving the most recent backup to backup server
mv_cur_bck () {
  local l_CURSFTPTRG
  $LS -1tr $BACKUPTARGET/* 2> /dev/null | $TAIL -1 | \
  while read e
  do
    l_CURSFTPTRG=$SFTPTARGET/`$BASENAME $e`
    log_msg ' * mv_cur_bck' "Moving backupfile $e to $l_CURSFTPTRG on backup server"
    if [ "$DRYRUN" != "TRUE" ]
    then
      $ECHO -e "put $e $l_CURSFTPTRG" | $SFTP ${BCKUSR}@${BCKSERVER}
    fi  
    $SLEEP 2
  done
  
}

### # run the gogs backup
run_gogs_bck () {
  $DOCKER exec -i $GOGSCONTAINERID $BASH -c "export USER=git && cd $GOGSDIR && ./gogs backup"
}

### # re-set ownership
reset_own () {
  $DOCKER exec -i $GOGSCONTAINERID $BASH -c "chown -R git:git /app/gogs/log/*"
}

### # ====================================================================== #
### # Main part of the script starts here ...
start_msg $SCRIPT

### # ====================================================================== #
### # Use getopts for commandline argument parsing ###
### # If an option should be followed by an argument, it should be followed by a ":".
### # Notice there is no ":" after "h". The leading ":" suppresses error messages from
### # getopts. This is required to get my unrecognized option code to work.
while getopts :dh FLAG; do
  case $FLAG in
    d) # option -d to do dry-run experiment
       DRYRUN=TRUE
    ;;   
	  h) # option -h shows usage
  	  usage $SCRIPT "Help message" "$SCRIPT"
	    ;;
	  *) # invalid command line arguments
	    usage $SCRIPT "Invalid command line argument $OPTARG" "$SCRIPT"
	    ;;
  esac
done  

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


### # determine ID of docker container
GOGSCONTAINERID=`$DOCKER ps -aqf "name=$GOGSCONTAINERNAME"`
log_msg $SCRIPT "Docker gogs container ID: $GOGSCONTAINERID"

### # start by removing old backups
log_msg $SCRIPT "Removing old backups ..."
rm_old_bck

### # run the backup
log_msg $SCRIPT "Running the backup ..."
run_gogs_bck

### # re-set owner of log back to git
log_msg $SCRIPT "Re-setting owner of logs ..."
reset_own

### # copy the backup files created today to a target directory on the same server
log_msg $SCRIPT "Copy current backups ..."
cp_cur_bck

### # depending on $MOVEBCKINTERVAL backups are moved to a backup server
if [ "$MOVEBCKINTERVAL" == "day" ]
then 
  log_msg $SCRIPT "Transfer most recent backup to backup server  ..."
  mv_cur_bck
else
  if [ "$MOVEBCKINTERVAL" == "week" ] && [ `$DATE +"%u"` -eq $MOVEBCKDOW ]
  then 
    log_msg $SCRIPT "Transfer most recent backup to backup server  ..."
    mv_cur_bck
  fi
fi

### # ====================================================================== #
### # Script ends here
end_msg $SCRIPT

### # ====================================================================== #
### # What comes below is documentation that can be used with perldoc

: <<=cut
=pod

=head1 NAME

   backup_docker_gogs - Backup Gogs Inside Docker

=head1 SYNOPSIS

  backup_docker_gogs.sh


=head1 DESCRIPTION

The backup functionality of gogs is used to create a backup.zip-file. After 
running the backup, the created backup.zip-file is copied from inside the 
container to a backup-target directory on the host machine. Old backup.zip 
files are deleted before starting the backup-job. The idea used in this 
script is taken from https://github.com/gogs/gogs/issues/4339.


=head2 Requirements

The docker container running gogs must be named gogs in order to be able to 
find the correct container where the backup can be run.


=head1 LICENSE

Artistic License 2.0 http://opensource.org/licenses/artistic-license-2.0


=head1 AUTHOR

Peter von Rohr <peter.vonrohr@qualitasag.ch>

=cut

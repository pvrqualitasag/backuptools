#!/bin/bash
###
###
###
###   Purpose:   Cleanup of backups
###   started:   2019-10-09 16:00:07 (pvr)
###
### ###################################################################### ###

set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails

# ======================================== # ======================================= #
# global constants                         #                                         #
# ---------------------------------------- # --------------------------------------- #
# prog paths                               #                                         #  
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #
# ---------------------------------------- # --------------------------------------- #
# directories                              #                                         #
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #
# ---------------------------------------- # --------------------------------------- #
# files                                    #                                         #
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
# ======================================== # ======================================= #



### # ====================================================================== #
### # functions
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -b <backup_stem>"
  $ECHO "  where -b <backup_stem>  --  specify the stem of the backup file"
  $ECHO "        -f <backup_file>  --  specify the backupfile to be deleted"
  $ECHO ""
  exit 1
}

### # produce a start message
start_msg () {
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}

### # produce an end message
end_msg () {
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}

### # functions related to logging
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}

### # ====================================================================== #
### # Main part of the script starts here ...
start_msg

### # ====================================================================== #
### # Use getopts for commandline argument parsing ###
### # If an option should be followed by an argument, it should be followed by a ":".
### # Notice there is no ":" after "h". The leading ":" suppresses error messages from
### # getopts. This is required to get my unrecognized option code to work.
BCKSTEM=""
BCKFILE=""
BCKPATH="backup/data"
while getopts ":b:f:p:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BCKSTEM=$OPTARG
      ;;
    f)
      BCKFILE=$OPTARG
      ;;
    p)
      BCKPATH=$OPTARG
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

# Check whether required arguments have been defined
if [ "$BCKSTEM" == "" ] && [ "$BCKFILE" == "" ]; then
  usage "-b <backup_stem> -f <backup_file> either of both arguments must be defined"
fi


## in case where a specific file to be deleted is defined, then just delete this
##  and ignore the backup stem
if [ "$BCKFILE" != "" ]
then
  log_msg $SCRIPT "Removing specific file: $BCKPATH/$BCKFILE"
  echo "rm $BCKPATH/$BCKFILE" | sftp u208153@u208153.your-backup.de
else
  log_msg $SCRIPT "Generate list of files from stem: $BCKSTEM"
  echo "ls -1tr $BCKPATH" | sftp u208153@u208153.your-backup.de 2> /dev/null | grep "$BCKSTEM" > .tmp.del.dat
  if [ `wc -l .tmp.del.dat` != "0" ]
  then
    cat .tmp.del.dat | while read f
    do
      log_msg $SCRIPT "Removing stemmed file: $f"
      echo "rm $f" | sftp u208153@u208153.your-backup.de
    done
    rm .tmp.del.dat
    log_msg $SCRIPT "Removed list of files"
  fi
  
fi



### # ====================================================================== #
### # Script ends here
end_msg



### # ====================================================================== #
### # What comes below is documentation that can be used with perldoc

: <<=cut
=pod

=head1 NAME

    - 

=head1 SYNOPSIS


=head1 DESCRIPTION

Delete a backup file from the ftp-server


=head2 Requirements




=head1 LICENSE

Artistic License 2.0 http://opensource.org/licenses/artistic-license-2.0


=head1 AUTHOR

Peter von Rohr <peter.vonrohr@qualitasag.ch>


=head1 DATE

2019-10-09 16:00:07

=cut

#!/bin/bash
#' ---
#' title:  Move Backup To FTP-Backup-Server
#' date:   2019-09-05
#' ---
#'
#' ## Purpose
#' Given some backup data created with backup_data.sh and given a backup server
#' that can be reached via sftp, this scripts moves a copy of the backup data
#' to the sftp-server.
#'
#'
#' ## Description
#'
#' TODO: Continue re-arranging this script to fit into the new setup of
#'       backuptools.
#'
#' ## Bash Settings
#+ bash-env-setting, eval=FALSE
# set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails

#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #

#' ### Directories
#' Installation directory of this script
#+ script-directories, eval=FALSE
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #
BTROOTDIR=`$DIRNAME $INSTALLDIR`           # backup tools root directory             #

#' ### Files
#' This section stores the name of this script and the
#' hostname in a variable. Both variables are important for logfiles to be able to
#' trace back which output was produced by which script and on which server.
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #



#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -d  -j <job_name> -s <remote_server>"
  $ECHO "  where -d (optional)       --  run in debug mode"
  $ECHO "        -j <job_name>       --  job name"
  $ECHO "        -s <remote_server>  --  remote sftp server"
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
}

#' ### Log Message
#' Log messages formatted similarly to log4r are produced.
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}

#' ### Moving Backup Data
move_bdata () {
  local l_JOBFN=$1
  local l_JOBLABEL=`basename $l_JOBFN | sed -e "s/\.bjob//"`
  if [ "$DEBUG" == "TRUE" ];then log_msg 'move_bdata' "Moving data for backup job: $l_JOBLABEL ...";fi
  # define data directory for the job from where data is moved
  local l_JOBDATADIR=$BTROOTDIR/data/$l_JOBLABEL
  # check whether the remote directory exists
  local l_REMOTEDATADIR=backup/data/$l_JOBLABEL
  echo "ls $l_REMOTEDATADIR" | sftp $SFTPREMOTE  &> tmp_out_ls
  if [ `grep 'not found' tmp_out_ls | wc -l` != "0" ]
  then
    if [ "$DEBUG" == "TRUE" ];then log_msg 'move_bdata' "Cannot find remote data dir: $l_REMOTEDATADIR ==> create it ...";fi
    echo "mkdir $l_REMOTEDATADIR" | sftp $SFTPREMOTE
  fi
  rm tmp_out_ls
  # move the data
  ls -1 $l_JOBDATADIR/*.tgz | while read t
  do
    if [ "$DEBUG" == "TRUE" ];then log_msg 'move_bdata' "Moving backup data : $t to $l_REMOTEDATADIR ...";fi
    echo "put $t $l_REMOTEDATADIR" | sftp $SFTPREMOTE
    sleep 2
    mv $t $t.moved
    sleep 2
  done

}

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
DEBUG=""
SFTPREMOTE=u208153@u208153.your-backup.de
while getopts ":j:s:dh" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    j)
      JOBNAME=$OPTARG
      ;;
    d)
      DEBUG="TRUE"
      ;;
    s)
      SFTPREMOTE=$OPTARG
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


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Set working directory
#' Use the backup root directory as working directory
#+ set-wd
curwd=`pwd`
cd $BTROOTDIR

#' ## Loop Over Backup Jobs
#' Loop over all backup jobs and do the backups
#+ bck-loop
JOBDIR=$BTROOTDIR/job
if [ "$DEBUG" == "TRUE" ];then log_msg $SCRIPT "Setting job directory to: $JOBDIR ...";fi
if [ "$JOBNAME" != "" ]
then
  jobfn=$JOBDIR/$JOBNAME
  if [ "$DEBUG" == "TRUE" ];then log_msg $SCRIPT "Current job file: $jobfn ...";fi
  move_bdata $jobfn
else
  ls -1 $JOBDIR/*.bjob | while read jobfn
  do
    if [ "$DEBUG" == "TRUE" ];then log_msg $SCRIPT "Current job file: $jobfn ...";fi
    move_bdata $jobfn
  done
fi


#' Change back to the originally saved working directory
#+ cd-back
cd $curwd

#' ## End of Script
#+ end-msg, eval=FALSE
end_msg



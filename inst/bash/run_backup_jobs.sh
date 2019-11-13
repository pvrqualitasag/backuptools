#!/bin/bash
#' ---
#' title: Run Backup Jobs
#' date:  2019-11-13 07:19:10
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' In the backuptools root directory (parent directory of where this script is
#' installed), there is a subdirectory called `jobs` which
#' contains all backup jobs. Each backup job is defined by a single file containing
#' all the directories that must be backedup in this job. This script takes all the
#' backup jobs and executes the backup tasks specified by the backup jobs.
#'
#' ## Description
#' In a loop over all backup jobs, the data directories given in all the backup jobs
#' are backedup to different backup result files.
#'
#' ## Bash Settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
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
SERVER=`hostname`                          # put hostname of server in variable      #



#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -d"
  $ECHO "  where -d (optional)  --  run in debug mode"
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
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

check_exist_dir_create () {
  local l_check_dir=$1
  if [ ! -d "$l_check_dir" ]
  then
    log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it"
    mkdir -p $l_check_dir
  fi

}

#' ### Running single backup job
#' Running the backup task for a single backup job where a backup job
#' is given by a list of directories that must be backedup together
run_bjob () {
  local l_JOBFN=$1
  local l_JOBLABEL=`echo $l_JOBFN | sed -e "s/\.bjob//"`
  if [ "$DEBUG" == "TRUE" ];then log_msg 'run_bjob' "Running backup job: $l_JOBLABEL ...";fi
  # check whether a data directory for the job exists
  local l_JOBDATADIR=$BTROOTDIR/data/$l_JOBLABEL
  if [ "$DEBUG" == "TRUE" ];then log_msg 'run_bjob' "Setting data directory to: $l_JOBDATADIR ...";fi
  check_exist_dir_create $l_JOBDATADIR
  # loop over directories in job file and run the backup
  cat $l_JOBFN | while read bdir
  do
    if [ "$DEBUG" == "TRUE" ];then log_msg 'run_bjob' "Backing up data from: $bdir ...";fi
    $BTROOTDIR/bash/backup_data.sh -s $bdir -t $l_JOBDATADIR
  done
}


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
DEBUG=""
while getopts ":a:b:ch" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DEBUG="TRUE"
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

#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE

#' ## Set working directory
#' Use the backup root directory as working directory
#+ set-wd
cd $BTROOTDIR


#' ## Loop Over Backup Jobs
#' Loop over all backup jobs and do the backups
#+ bck-loop
JOBDIR=$BTROOTDIR/job
if [ "$DEBUG" == "TRUE" ];then log_msg $SCRIPT "Setting job directory to: $JOBDIR ...";fi
ls -1 $JOBDIR/*.bjob | while read jobfn
do
  if [ "$DEBUG" == "TRUE" ];then log_msg $SCRIPT "Current job file: $jobfn ...";fi
  run_bjob $jobfn
done




#' ## End of Script
#+ end-msg, eval=FALSE
end_msg


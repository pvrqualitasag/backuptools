#!/bin/bash
#' ---
#' title: Installation of Cron-Job Backup
#' date:  2019-11-12 10:51:01
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Installation of all components for the backup run via cronjob. The script sources are
#' taken from the local R-library directory and the installation target directory must be
#' specified.
#'
#' ## Description
#' Given the script sources in the local R-library directory, the required components consisting
#' of
#'
#' * backup_data.sh to run the single data backups
#' * utilities used in backup_data.sh
#' * run_backup.sh to run the cron-job for the backup
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
  $ECHO "Usage: $SCRIPT -s <script_source_dir> -t <install_trg_dir> -u <util_dir>"
  $ECHO "  where -s <script_source_dir>  --  script source directory from where scripts are taken"
  $ECHO "        -t <install_trg_dir>    --  installation target directory"
  $ECHO "        -u <util_dir>           --  directory with bash utilities"
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

#' ### Directory Existence Check
#' In case the directory cannot be found, it is created
#+ check-exist-dir-create-fun
check_exist_dir_create () {
  local l_check_dir=$1
  if [ ! -d "$l_check_dir" ]
  then
    log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it"
    mkdir -p $l_check_dir
  fi

}

#' ### File Existence Check
#' If the given file does not exist, we fail here
check_exist_file_fail () {
  local l_check_file=$1
  if [ ! -f $l_check_file ]
  then
    log_msg check_exist_file_fail "FAILED because CANNOT find file: $l_check_file"
    exit 1
  fi
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
SCRIPTSOURCE=$(R -e '.libPaths()[1]' --quiet --no-save --slave | cut -d ' ' -f2 | sed -e 's/\"//g')/backuptools/bash
INSTALLSCRIPTS=(backup_data.sh run_backup_jobs.sh df_remote_backup.sh ls_remote_backup.sh)
INSTALLTRG=""
UTILDIR=""
while getopts ":s:t:u:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    s)
      if test -d $OPTARG; then
        SCRIPTSOURCE=$OPTARG
      else
        usage "$OPTARG isn't a valid script source"
      fi
      ;;
    t)
      INSTALLTRG=$OPTARG
      ;;
    u)
      if test -d $OPTARG; then
        UTILDIR=$OPTARG
      else
        usage "$OPTARG isn't a valid utility directory"
      fi
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
if test "$UTILDIR" == ""; then
  usage "-u <utility_dir> not defined"
fi

#' The source directory from where the scripts must be installed from
#+ script-src-check
if [ ! -d "$SCRIPTSOURCE" ]
then
  usage "-d <script_source> not a valid script source directory"
fi

#' In case the installation target directory does not exist, we create it.
#' This requires sufficient priviledges for directory creation.
#+ install-trg-mkdir
check_exist_dir_create $INSTALLTRG


#' ## Infrastructure Setup
#' The necessary infrastructure must be created. This consists of a number
#' of directories.
#+ create-infra
for d in bash data job
do
  check_exist_dir_create $INSTALLTRG/$d
done


#' ## Script Installation
#' The basic data backup script and the run-script must be installed.
#+ script-install
for s in ${INSTALLSCRIPTS[@]}
do
  check_exist_file_fail "$SCRIPTSOURCE/$s"
  log_msg $SCRIPT " * Install $s to $INSTALLTRG/bash ..."
  cat $SCRIPTSOURCE/$s | sed -e "s|__BASHTOOLUTILDIR__|$UTILDIR|g" > $INSTALLTRG/bash/$s
done


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg


#!/bin/bash
#' ---
#' title: Create data backups
#' date:  2018-07-11
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Create a backup from a given source directory and move it to a target path.
#' The format of the resulting backup is a gzipped-tar-archive.
#'
#' ## Description
#' Backups of single data directories are generated using tar. The outcome of this
#' simple approach may vary depending on the system on which the backup is created.
#' On Linux-based systems it should be possible to create backups from all data
#' to which the user who calls the script has access to. The created backups are
#' stored in compressed files and are stored into the target directory that is also
#' specified. The user who runs this script must have write-permission in the target
#' directory and the target directory must have enough space to be able to store the
#' created backup file.
#'
#' ## Requirements
#' The data directory that is specified as source directory using option -s must
#' exist and the user who executes this script must have sufficient permission
#' to read the data from this directory.
#'
#' The target directory which is specified using option -t must exist and the user
#' who runs the backup must have write-permission in that directory. Furthermore
#' the amount of available space on the medium where the target directory is
#' located, must be sufficient to store the created backup file.

#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
BASENAME=/usr/bin/basename                 # PATH to basename function
DIRNAME=/usr/bin/dirname                   # PATH to dirname function
BACKTAR='tar -czf'
BACKTARV='tar -cvzf'

#' ### Directories
#+ script-directories, eval=FALSE
INSTALLDIR=/opt/bashtools                  # installation dir of bashtools on host         #
UTILDIR=__BASHTOOLUTILDIR__                # directory containing utilities of bashtools   #

#' ### Files and Hostname
#' This section stores the name of this script and the hostname in a variable. Both
#' variables are important for logfiles to be able to trace back which output was
#' produced by which script and on which server.
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                      #
SERVER=`hostname`


#' ## Use utilities
#' A common set of functionalities is stored in a utilities file. These are made available by
#' sourcing the utilities file.
#+ load-utilities, eval=FALSE
UTIL=$UTILDIR/bash_utils.sh
source $UTIL

#' ## Functions
#' In this section user-defined functions that are specific for this script are
#' defined in this section.
#+ bck-fun
backup () {
  local l_SOURCEDIR=$1
  local l_TARGETDIR=$2
  local l_TARFILE=`date +"%Y%m%d%H%M%S"`_`basename $l_SOURCEDIR`.tgz
  $BACKCMD $l_TARGETDIR/$l_TARFILE -C `dirname $l_SOURCEDIR` `basename $l_SOURCEDIR`
}

#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg $SCRIPT


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
BACKCMD=$BACKTAR
while getopts :s:t:hv FLAG; do
  case $FLAG in
    s) # set option "s" for source directory
      SOURCEDIR=$OPTARG
	    ;;
	  t) # set option "-t" for target directory
	    TARGETDIR=$OPTARG
	    ;;
	  h) # option -h shows usage
	    usage $SCRIPT "Help message" "$SCRIPT -s <source> -t <target>"
	    ;;
	  v) # verbose option
	    BACKCMD=$BACKTARV
	    ;;
	  *) # invalid command line arguments
	    usage $SCRIPT "Invalid command line argument $OPTARG" "$SCRIPT -s <source> -t <target>"
	    ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if [ ! -d "$SOURCEDIR" ]
then
  usage $SCRIPT "ERROR: Cannot Find source directory: $SOURCEDIR" "$SCRIPT -s <source> -t <target>"
fi
if [ ! -d "$TARGETDIR" ]
then
  usage $SCRIPT "ERROR: Cannot Find target directory: TARGETDIR" "$SCRIPT -s <source> -t <target>"
fi

#' At this point, we are not allowing the root-directory be backed up. As an alternative all
#' existing subdirectories can be backed up in a series of separate jobs.
#+ no-root-bck
if [ $SOURCEDIR == '/' ]
then
  usage $SCRIPT "ERROR: Cannot backup root as SOURCEDIR: $SOURCEDIR" "$SCRIPT -s <source> -t <target>"
fi

#' The source data is backed up and moved to the target directory by
#' a call to the backup function.
log_msg $SCRIPT "Backup of source: $SOURCEDIR to target: $TARGETDIR"
backup $SOURCEDIR $TARGETDIR


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg $SCRIPT



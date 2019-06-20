#!/bin/bash
###
###
###
###   Purpose:   Create data backups
###   started:   2018-07-11 (pvr)
###
### ######################################### ###

# ================================ # ======================================= #
# global constants                 #                                         #
# -------------------------------- # --------------------------------------- #
# directories                      #                                         #
INSTALLDIR=/opt/bashtools          # installation dir of bashtools on host   #
# -------------------------------- # --------------------------------------- #
# prog paths                       # required for cronjob                    #
BASENAME=/usr/bin/basename         # PATH to basename function               #
# ================================ # ======================================= #

#Set Script Name variable
SCRIPT=`basename ${BASH_SOURCE[0]}`

# other constants
BACKTAR='tar -czf'
BACKTARV='tar -cvzf'

# Use utilities
UTIL=$INSTALLDIR/util/bash_utils.sh
source $UTIL

### # -------------------------------------- ###
### # functions
backup () {
  local l_SOURCEDIR=$1
  local l_TARGETDIR=$2
  local l_TARFILE=`date +"%Y%m%d%H%M%S"`_`basename $l_SOURCEDIR`.tgz
  $BACKCMD $l_TARGETDIR/$l_TARFILE -C `dirname $l_SOURCEDIR` `basename $l_SOURCEDIR`
} 
### # -------------------------------------------- ##
### # Main part of the script starts here ...
start_msg $SCRIPT

### # by default, the non-verbose version is used as backup command
BACKCMD=$BACKTAR

### # -------------------------------------------- ###
### # Use getopts for commandline argument parsing ###
### # If an option should be followed by an argument, it should be followed by a ":".
### # Notice there is no ":" after "h". The leading ":" suppresses error messages from
### # getopts. This is required to get my unrecognized option code to work.
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

### # checks
### # source and target directories must exist
if [ ! -d "$SOURCEDIR" ]
then
  usage $SCRIPT "ERROR: Cannot Find source directory: $SOURCEDIR" "$SCRIPT -s <source> -t <target>"
fi
if [ ! -d "$TARGETDIR" ]
then
  usage $SCRIPT "ERROR: Cannot Find target directory: TARGETDIR" "$SCRIPT -s <source> -t <target>"
fi

### # root-directory cannot be backed up
if [ $SOURCEDIR == '/' ]
then
  usage $SCRIPT "ERROR: Cannot backup root as SOURCEDIR: $SOURCEDIR" "$SCRIPT -s <source> -t <target>"
fi

### # running backup function
log_msg $SCRIPT "Backup of source: $SOURCEDIR to target: $TARGETDIR"
backup $SOURCEDIR $TARGETDIR


### # -------------------------------------------- ##
### # Script ends here
end_msg $SCRIPT

### # -------------------------------------------- ##
### # What comes below is documentation that can be used with perldoc

: <<=cut
=pod

=head1 NAME

   backup_data - Create Data Backups

=head1 SYNOPSIS

   backup_data.sh -s <source_dir> -t <target_dir>
   
   where -s specifies the source directory to be backed up
         -t specifies the target directory under which the backup should be stored


=head1 DESCRIPTION

Backups of single data directories are generated using tar. The outcome of this 
simple approach may vary depending on the system on which the backup is created. 
On Linux-based systems it should be possible to create backups from all data 
to which the user who calls the script has access to. The created backups are 
stored in compressed files and are stored into the target directory that is also 
specified. The user who runs this script must have write-permission in the target 
directory and the target directory must have enough space to be able to store the 
created backup file.


=head2 Requirements

The data directory that is specified as source directory using option -s must 
exist and the user who executes this script must have sufficient permission 
to read the data from this directory. 

The target directory which is specified using option -t must exist and the user 
who runs the backup must have write-permission in that directory. Furthermore 
the amount of available space on the medium where the target directory is 
located, must be sufficient to store the created backup file. 


=head1 LICENSE

Artistic License 2.0 http://opensource.org/licenses/artistic-license-2.0


=head1 AUTHOR

Peter von Rohr (peter.vonrohr@qualitasag.ch)
=cut
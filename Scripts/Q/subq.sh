#!/bin/bash
#
#   subq.sh
#
#   COPY Q INPUT TO A TEMPORARY FOLDER (TMPFS) AND LAUNCH IT THERE.
#   
#DESCRIPTION:
#   In a defined time interval a Backup will be copied to a presistent folder.
#   You can provide arguments to set Inputfile, Outputdir, TMPFS-dir and Q Exe.
#
#ATTENTION:
#   If this script is interrupted, data might not be removed from TMPFS!
#   To avoid this, kill molaris (the PID is echoed in stdout).
#   The script will then clean up and exit.
#
#NOTE:
#   The script should be pretty stable and will try to parse various input properly.
#
#AUTOR:
#   Beat Amrein
#
#VERSION:
#   20130322_1 
#
#SYNOPSIS:
#   INPUTFILEDIR [ TARGETDIR  [ TEMPFOLDER ] [ QEXE ] ]


#DEPENDENCIES:
#
# Folder must exist ~/.Trash

##########################
# USER DEFINED CONSTANTS #
##########################

TRASH="/pfs/nobackup/home/b/barrozo/.Trash"

DEFAULT_TMPFS="/dev/shm"
DEFAULT_QEXE="/pfs/nobackup/home/b/barrozo/Q/Q5T/Qprep5"
BACKUP_INTERVAL=600        #Backup Interval in Seconds 
                           #(default 600 [backup every 10 minutes])
MOVE_INPUTFILES_TO_FINAL=0 #1 => move inputfile folder to the final folder 
                           #0 => do not move input file folder (default)

function usage() {
    sn=`basename $0`
    echo "USAGE:
    $sn INPUTFILEPATH [ TARGETDIR  [ TEMPFOLDER ] [ QEXE ] ]

    INPUTFILEPATH     PATH to the INPUT FILE. 
                      all used files MUST be LOCATED in this folder.

    TARGETDIR         (Optional) FOLDER where the output data will be STORED. 
                      you must SET it, in order to set TEMPFOLDER AND QEXE

    The following parameters may only be set, if a TARGETDIR is provided:
        TEMPFOLDER        Optional ($DEFAULT_TMPFS).
        QEXE        Optional ($DEFAULT_QEXE).
        "
    examples
}

function examples() {
    echo " 

    EXAMPLE DIRECTORY STRUCTURE:
         ~/proj1/
                /prep/
                     /p_my_run/
                              /myrun.inp
                /finished_run/

    Ex1: With targetdir
    [ ~/proj1]$ $sn ./prep/p_my_run/myrun.inp ./finished_run/my_run
    The output will placed in ~/proj1/finished_run/sYYMMDD_my_run

    Ex2: Without targetdir
    [ ~/proj1]$ $sn ./prep/p_my_run/myrun.inp 
    The output will be placed in ~/proj1/prep/sYYMMDD_r_my_run

    Ex3: With special Q:
    [ ~/proj1]$ $sn ./prep/p_my_run/myrun.inp ./finished_run/my_run \$GLENNMOL

    Ex4: With special tempfolder:
    [ ~/proj1]$ $sn ./prep/p_my_run/myrun.inp ./finished_run/my_run /tmp
    "
}







###################
# PARSE ARGUMENTS #
###################

if [ -z "$1" ]; then usage; fi

if [ -z "$1" ]; then echo "NO INPUT-FILE-FOLDER PROVIDED. EXIT"; exit 1; 
else 
    input_dir=$(readlink -f `dirname $1`)
    #EXTRACT BASENAME
    q_inp="${1##*/}"
    #REMOVE EXTENSION .inp
    q_inp="${q_inp%.inp}"
fi 

if [ -z "$2" ]; then 
    echo "NO OUTPUT-FILE-FOLDER PROVIDED. "
    echo "!!!WARNING WILL PUT RESULTS INTO SAME MAINFOLDER AS INPUTFOLDER IS LOCATED."
    dir=$(readlink -f `dirname $input_dir`)
    run_name="r_$q_inp"
else 
    dir=$(readlink -f `dirname $2`)
    if [ -d "$2" ]; then
        echo "TARGET DIRECTORY EXISTS. EXIT."; exit 1;
    fi
    run_name=`basename $2`

    # TEST IF A VALUE WAS SET FOR Q EXECUTABLE OR TMPFS FOLDER
    # (IF ITS A DIRECTORY=> TMPFS, IF ITS A FILE => QEXE)
    if [ ! -z "$3" ]; then
       if [ -d "$3" ]; then tmpfs="$3"; elif [ -f "$3" ]; then qexe="$3"; fi
       
       if [ ! -z "$4" ]; then
          if [ -d "$4" ]; then tmpfs="$4"; elif [ -f "$4" ]; then qexe="$4"; fi
       fi
    fi
fi

# IF NOTHING WAS SET, SET DEFAULT VALUES
if [ -z "$tmpfs" ]; then tmpfs="$DEFAULT_TMPFS"; fi
if [ -z "$qexe" ]; then qexe="$DEFAULT_QEXE"; fi

if [ ! -d "$tmpfs" ]; then echo "TEMPORARY FILE FOLDER DOES NOT EXIST! STOP! $tmpfs"; exit 1; fi

tmpfs="$tmpfs/$$"

if [ -d "$tmpfs" ]; then echo "TEMPORARY FILE PID - FOLDER EXISTS! STOP! $tmpfs"; exit 1; fi

mkdir -p $tmpfs


#############
# FUNCTIONS #
#############


function print_configuration() {
    echo "Maindirectory   : $dir"
    echo "Run-Name        : $run_name"
    echo "Q Input   : $input_dir/$q_inp.inp"
    echo "Input Directory : $input_dir"
    if [ $MOVE_INPUTFILES_TO_FINAL -eq 1 ]; then  
        echo "                  ^Will be moved output directory."; fi
    echo "Backup Directory: $dir/$run_name"
    echo "Output Directory: $dir/sYYMMDD_$run_name"
    echo "Backup Interval : $BACKUP_INTERVAL"
    echo "Temporary Dir   : $tmpfs/$run_name"
    echo "Q Execut        : $qexe"
    echo "Hostname        : $HOSTNAME"

    echo ""
}

#$1 name
#$2 dir
function error() {
    echo "ERROR: $1 does not exist! STOP."
    echo "( $2 )"
    exit 1
}

function check_configuration() {
    print_configuration
    if [ ! -d "$input_dir" ]; then error "INPUTFILE DIRECTORY" "$input_dir";fi
    if [ ! -d "$tmpfs" ]; then error "TEMPORARY FILE FOLDER" "$tmpfs"; fi
    if [ ! -d "$dir" ]; then error "MAINDIRECTORY EXIT" "$dir"; fi
    if [ ! -f "$input_dir/$q_inp.inp" ]; then error "Q Input File" "$input_dir/$q_inp.inp"; fi
    if [ ! -f "$qexe" ]; then error "Q EXECUTABLE" "$qexe"; fi
    if [ -d "$tmpfs/$run_name" ]; then 
        echo "THE TEMPORARY FOLDER EXISTS. EXIT"
        echo "( $tmpfs/$run_name )"
        exit 1
    fi
}


function copy_to_tmpfs() {
    cp -r "$input_dir" "$tmpfs/$run_name"
}

function backup_tmpfs() {
    # THE /* IS VERY IMPORTANT OR IT WILL CREATE A SUBFOLDER IN $dir/$run_name!
    mkdir -p "$dir/$run_name"
    cp -ru "$tmpfs/$run_name/"* "$dir/$run_name"
}

#$1 input file name (without *inp extension!)
function compute_while_backup() {
    cd "$tmpfs/$run_name"
    $qexe <"$q_inp".inp> "$q_inp".out &
    PID=$!
    echo "Q' PID: $PID"
    echo '(kill this PID to properly interrupt this script!)'
    watch_q $PID
}

#$1 pid to wait on
function watch_q() {
    PID=$1
    local i=0

    echo "Progress (each '.' = backup, (one backup every $BACKUP_INTERVAL seconds))"

    #While the PID exists, this loops ...
    while kill -0 $PID >/dev/null 2>&1
    do
        sleep 1
        let i=i+1
        if [ $i -eq $BACKUP_INTERVAL ]
        then
            #Backup
            echo -n "." #Indicate
            backup_tmpfs 
            i=0
        fi
    done
    #Create latest backup (VERY IMPORTANT)
    backup_tmpfs 
}

function move_to_persistent() {
    final="$dir/s`date +%y%m%d`_$run_name"
    mv -f --backup=numbered "$tmpfs/$run_name" "$final"
    mv -f --backup=numbered "$dir/$run_name" "$final/redundant_backup_during_computation_$run_name"
    if [ $MOVE_INPUTFILES_TO_FINAL -eq 1 ]; then
        mv -f --backup=numbered "$input_dir" "$final" && echo "The input files where moved to the output dir."
    fi 
    echo -e "Run has ended. Please find your files in output dir\n\nOutput Dir    : $final"
}




########
# MAIN #
########

echo
echo "o CONFIGURATION"
check_configuration
echo
echo "o COPY FILES INTO TEMP DIR"
copy_to_tmpfs
echo
echo "o COMPUTE (and BACKUP)"
compute_while_backup 
echo
echo "o MOVE DATA TO PERSISTENT STORAGE"
move_to_persistent
echo "o RUN FINISHED"
echo

mv -f --backup=numbered "$tmpfs/$run_name" "$TRASH"

rmdir $tmpfs

exit 0

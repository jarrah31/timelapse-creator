#!/bin/zsh
#

# MacOS requirement for GETOPT and GNU Date
#
# brew install ffmpeg
# brew install coreutils
# brew install gnu-getopt
# echo 'export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"' >> ~/.zshrc
# log out and back in to pick up the path

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # get cur dir of this script

echo
cd $DIR

if [ -f video.conf ] ; then
	source $DIR/video.conf
else
	echo "ERROR  : Missing configuration settings file video.conf in $DIR"
	echo
	exit 1
fi

if ! echo $PATH | grep gnu-getopt > /dev/null 2>&1; then
	echo
	echo "ERROR :  gnu-getopt isn't within your PATH."
	echo "         Please run the following and then LOG OFF and back on again to load the updated PATH into memory:"
	echo 
	echo "         echo 'export PATH="/usr/local/opt/gnu-getopt/bin:\$PATH"' >> ~/.zshrc"
	echo
	exit 1
fi


function USAGE ()
{
	echo ""
	echo "Usage:"
	echo "   dailytimelapse.sh [-f <fps>] [-d <date>] | [-w <date>] | [-m <date>] | [-s <startdate>  -e <enddate>] -c <camname> [hv]"
	echo ""
	echo "     -d YYYY-MM-DD : daily"
	echo "     -w YYYY-MM-DD : weekly"
	echo "     -m YYYY-MM    : monthly"
	echo "     -s YYYY-MM-DD -e YYYY-MM-DD : start and end dates"
	echo "     -c : camera name (${CAMLIST})"
	echo "     -f : frames per second for the timelapse"
	echo "     -h : help"
	echo "     -v : verbose"
	echo ""
	echo "Examples:"
	echo ""
	echo "  Single Day Timelapse:"
	echo "    dailytimelapse.sh -d 2021-01-10 -c camname"
	echo ""
	echo "  Weekly Timelapse - specify any day within the required week. The following would be from Mon 18th Jan to Sun 24th Jan."
	echo "    dailytimelapse.sh -w 2021-01-22 -c camname"
	echo ""
	echo "  Monthly Timelapse:"
	echo "    dailytimelapse.sh -m 2020-11 -c camname"
	echo ""
	echo "  Specify Custom Range Timelapse:"
	echo "    dailytimelapse.sh -s 2020-11-15 -e 2020-11-25 -c camname"
	echo ""
	echo "  Frames Per Second Defaults:"
	echo "    Daily     - 10"
	echo "    Weekly    - 15"
	echo "    Montly    - 30"
	echo ""
	echo "  FPS option -f <num> can be used with any timelapse range"
	echo "    dailytimelapse.sh -f 20 -d 2021-01-10 -c camname"
	echo ""
}

function WEEKOF ()
{
	# Returns the first monday of a week from a given date
	WEEK=$1
	YEAR=$2
	DATE_FMT="+%F"

	WEEK_NUM_OF_JAN_1=$(gdate -d $YEAR-01-01 +%W)
	WEEK_DAY_OF_JAN_1=$(gdate -d $YEAR-01-01 +%u)

	if ((WEEK_NUM_OF_JAN_1)); then
			FIRST_MON=$YEAR-01-01
	else
			FIRST_MON=$YEAR-01-$((01 + (7 - WEEK_DAY_OF_JAN_1 + 1) ))
	fi

	MON=$(gdate -d "$FIRST_MON +$((WEEK - 1)) WEEK" "$DATE_FMT")
	SUN=$(gdate -d "$FIRST_MON +$((WEEK - 1)) WEEK + 6 day" "$DATE_FMT")
	#echo "\"$mon\" - \"$sun\""
}

function INVALDATE ()
{
	DATEINVAL=$1
	MODEDATE=$2
	USAGE
	echo "ERROR : $DATEINVAL is not correct. Please supply a valid date and in the correct format."
	[[ $MODEDATE = "day" ]] && echo "         YYYY-MM-DD" || echo "         YYYY-MM"
	echo
	exit 1
}

function CHECKDATE ()
{
	chkdate=$1
	if [[ $chkdate =~ [0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1]) ]] && gdate -d "$chkdate" > /dev/null 2>&1; then 
		DATEVALID=true
	else
		INVALDATE $chkdate day
	fi
}

# Handle passed flags
# Handles "-" once-char and simple "--" one word flags
OPTS=`getopt -o hvgd:w:c:m:s:e:f: -l help,verbose,daily,weekly,monthly,start,end,debug -- "$@"`

if [ $? != 0 ]; then
	USAGE
	exit 1
fi
 
eval set -- "$OPTS"

optnum=0

while true ; do
	case "$1" in
		-h|--help) USAGE; shift;;
		-v|--verbose) VERBOSE=true; shift;;
		-d|--daily) DATEVALUE=$2; DAILY=true; MODE=daily; let optnum=optnum+1; shift 2;;
		-w|--weekly) DATEVALUE=$2; WEEKLY=true; MODE=weekly; let optnum=optnum+1; shift 2;;
		-m|--monthly) MONTHVALUE=$2; MONTHLY=true; MODE=monthly; let optnum=optnum+1; shift 2;;
		-s|--start) STARTVALUE=$2; RANGE=true; MODE=range; let optnum=optnum+1; shift 2;;
		-e|--end) ENDVALUE=$2; RANGE=true; MODE=range; let optnum=optnum+1; shift 2;;
		-f|--fps) NEWFPS=$2; SETFPS=true; let optnum=optnum+1; shift 2;;
		-c|--camera) CAMNAME=$2; CAMERA=true; shift 2;;
		-g|--debug) DEBUG=true; shift;;
		--) shift; break;;
	esac
done

if [[ "$DEBUG" = true ]]; then
	echo "=== DEBUG MODE ==="
	echo
	echo "Daily    : $DAILY"
	echo "Weekly   : $WEEKLY"
	echo "Monthly  : $MONTHLY"
	echo "Range    : $RANGE $STARTVALUE -> $ENDVALUE"
	echo "Verbose  : $VERBOSE"
	echo "Setfps   : $TRUE $NEWFPS"
	echo "Camname  : $CAMNAME"
	echo
fi

# Check the supplied dates are valid and in the correct format
if [[ ! "$RANGE" = true ]] && [[ ! "$SETFPS" = true ]] && [[ $optnum -gt 1 ]]; then 
	USAGE
	echo "ERROR : Only one of either daily, weekly, or monthly is allowed."
	echo
	exit 1
fi
if [[ "$WEEKLY" = true ]] || [[ "$DAILY" = true ]]; then
	CHECKDATE $DATEVALUE
fi
if [[ "$MONTHLY" = true ]]; then
	if [[ $MONTHVALUE =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]; then 
		DATEVALID=true
	else
		INVALDATE $MONTHVALUE month
	fi
fi
if [[ "$RANGE" = true ]]; then
	# Check if both are true in case only one option was specified
	if [[ -z $STARTVALUE ]] || [[ -z $ENDVALUE ]]; then
		USAGE
		echo "ERROR : Both the start (-s) and end (-e) options are required for a ranged date"
		echo
		exit 1
	fi

	CHECKDATE $STARTVALUE
	CHECKDATE $ENDVALUE

	# Check the date difference isn't negative
	DATE_DIFF=$(( ($(gdate -d "$ENDVALUE UTC" +%s) - $(gdate -d "$STARTVALUE UTC" +%s)) / (60*60*24) ))
	if [[ ! $DATE_DIFF -ge 0 ]]; then
		echo "ERROR  : $STARTVALUE is higher than $ENDVALUE"
		echo
		exit 1
	fi
fi
if [[ "$SETFPS" = true ]]; then
	re='^[0-9]+$'
	if ! [[ ${NEWFPS} =~ $re ]] ; then
		echo "ERROR  : FPS option is not a number" >&2
		echo
		exit 1
	fi
fi


# Check for valid camera name
if [[ "$DATEVALID" = true ]]; then
	if [[ "$CAMERA" = true ]]; then
		if [[ ! $CAMLIST =~ (^|[[:space:]])$CAMNAME($|[[:space:]]) ]]; then
			USAGE
			echo "ERROR : $CAMNAME is not a valid camera name. Please choose one of the following:"
			echo "         $CAMLIST"
			echo
			exit 1
		else				
			echo "INFO  : All parameters are valid."
			echo "INFO  : MODE - $MODE"
			VALID=true
		fi
	else
		USAGE
		echo "ERROR : Missing camera option"
		echo
		exit 1
	fi
fi



if [[ "$VALID" = true ]]; then
	# For ffmpeg to include the last day, the next day needs to be specified.
	if [[ "$DAILY" = true ]]; then
		DATESTART=$DATEVALUE
		DATEEND=$(gdate -d "${DATEVALUE} +1 day" +%F)
		ACTUALEND=$DATEVALUE
		TL_FPS=10
	elif [[ "$WEEKLY" = true ]]; then
		WEEKNUM=$(gdate -d "${DATEVALUE}" +%W)
		YEAR=$(gdate -d "${DATEVALUE}" +%Y)
		WEEKOF $WEEKNUM $YEAR
		DATESTART=$MON
		DATEEND=$(gdate -d "${SUN} +1 day" +%F)
		ACTUALEND=$SUN
		TL_FPS=15
	elif [[ "$MONTHLY" = true ]]; then
		DATEVALUE=$MONTHVALUE
		DATESTART="${MONTHVALUE}-01"
		DATEEND=$(gdate -d "${DATESTART} +1 month" +%F)
		ACTUALEND=$(gdate -d "${DATEEND} -1 day" +%F)
		TL_FPS=30
	elif [[ "$RANGE" = true ]]; then
		DATESTART=$STARTVALUE
		DATEEND=$(gdate -d "${ENDVALUE} +1 day" +%F)
		ACTUALEND=$ENDVALUE
		[[ $DATE_DIFF -gt 5 ]] && TL_FPS=30 || TL_FPS=10
	fi	
	echo "INFO  : Timelapse range is $DATESTART - $ACTUALEND"

	[[ "$SETFPS" = true ]] && TL_FPS=${NEWFPS}

	FOLDER_SOURCE="${FOLDER_SRC}/${CAMNAME}"    # source of images to Encode.


	SOURCE_FILES=$FOLDER_SOURCE/*$FILES_EXT  # Files wildcard that we are looking for

	# Output videoname with prefix and date and time (minute only).
	# Video can be specified as avi or mp4
	if [[ "$DAILY" = true ]]; then
		VIDEONAME=${CAMNAME}_${MODE}_${DATESTART}.mp4
	else
		VIDEONAME=${CAMNAME}_${MODE}_${DATESTART}_to_${ACTUALEND}.mp4
	fi

	if [[ "$DEBUG" = true ]]; then
		echo ""
		echo "VIDEONAME             : $VIDEONAME"
		echo "FOLDER_SOURCE         : $FOLDER_SOURCE"
		echo "SOURCE_FILES          : $SOURCE_FILES"
		echo "FOLDER_DEST           : $FOLDER_DEST"
		echo "FOLDER_WORKING        : $FOLDER_WORKING"
		echo "FILES_EXT             : $FILES_EXT"		
		echo "TL_FPS                : $TL_FPS"
		echo
	fi

	# Check if source folder exists
	if [ ! -d $FOLDER_SOURCE ] ; then
		echo "ERROR : Source Folder" $FOLDER_SOURCE "Does Not Exist"
		echo "        Check $0 Variable folder_source and Try Again"
		exit 1
	fi

	# Create destination folder if it does not exist
	if [ ! -d $FOLDER_DEST ] ; then
		mkdir $FOLDER_DEST
		if [ "$?" -ne 0 ]; then
			echo "ERROR : Problem Creating Destination Folder" $FOLDER_DEST
			echo "        If destination is a remote folder or mount then check network, destination IP address, permissions, Etc"
			exit 1
		fi
	fi

	# Remove old working folder if it exists
	if [ -d $FOLDER_WORKING ] ; then
		echo "WARN  : Removing previous temporary working folder $FOLDER_WORKING"
		rm -R $FOLDER_WORKING
	fi

	# Create a new temporary working folder to store soft links
	# that are numbered sequentially in case source number has gaps
	echo "INFO  : Creating Temporary Working Folder $FOLDER_WORKING"
	mkdir $FOLDER_WORKING
	if [ ! -d $FOLDER_WORKING ] ; then
		echo "ERROR : Problem Creating Temporary Working Folder $FOLDER_WORKING"
		exit 1
	fi

	cd $FOLDER_WORKING    # change to working folder
	# Create numbered soft links in working folder that point to image files in source folder
	echo "INFO  : Creating Image File Soft Links"
	echo "        From  $FOLDER_SOURCE"
	echo "        To    $FOLDER_WORKING"
	a=0

	if [[ "$DEBUG" = true ]]; then
		echo "DEBUG : Find command and resultant file list."
		echo "        find $FOLDER_SOURCE \( ! -regex '.*/\..*' \) -newermt $DATESTART ! -newermt $DATEEND -type f | sort -n | xargs ls -l"
		echo ""
		find $FOLDER_SOURCE \( ! -regex '.*/\..*' \) -newermt $DATESTART ! -newermt $DATEEND -type f | sort -n | xargs ls -l
		echo
	fi
	
	find $FOLDER_SOURCE \( ! -regex '.*/\..*' \) -newermt $DATESTART ! -newermt $DATEEND -type f | sort -n |
	(
		# create sym links in working folder for the rest of the files
		while read file
		do
			new=$(printf "%05d.$FILES_EXT" ${a}) #05 pad to length of 4 max 99999 images
			ln -s ${file} ${new}
			let a=a+1
		done
	)


	# If the working folder is empty, then no files were found within the specified date range
	if [ -n "$(find "$FOLDER_WORKING" -maxdepth 0 -type d -empty 2>/dev/null)" ]; then
		echo "ERROR : No image files found within the specified date range for $CAMNAME"
		exit 1
	fi

	cd $DIR  

	echo "INFO  : Making Video ... "$VIDEONAME

	if [[ "$VERBOSE" = true ]]; then
		ffmpeg -y -f image2 -r $TL_FPS -i $FOLDER_WORKING/%5d.$FILES_EXT -aspect $ASPECT_RATIO -s $VID_SIZE $FOLDER_DEST/$VIDEONAME
	elif [[ "$DEBUG" = true ]]; then
		echo "DEBUG : ffmpeg command."
		echo "        ffmpeg -y -f image2 -r $TL_FPS -i $FOLDER_WORKING/%5d.$FILES_EXT -aspect $ASPECT_RATIO -s $VID_SIZE $FOLDER_DEST/$VIDEONAME"
		echo "DEBUG : **No video created during debug mode**"		
	else
		ffmpeg -loglevel quiet -y -f image2 -r $TL_FPS -i $FOLDER_WORKING/%5d.$FILES_EXT -aspect $ASPECT_RATIO -s $VID_SIZE $FOLDER_DEST/$VIDEONAME
	fi

	if [ $? -ne 0 ] ; then   # Check for encoding error
		echo "ERROR : Encoding Failed for" $FOLDER_DEST/$VIDEONAME
		echo "        Review Output for Error Messages and Correct Problem"
		exit 1
	else
		echo "INFO  : Video Saved to" $FOLDER_DEST/$VIDEONAME
	fi
else
	USAGE
	echo "ERROR  : Missing required options"
	echo
	exit 1
fi 
echo

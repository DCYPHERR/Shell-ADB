. ./library/mySetup.txt
. ./library/textFormatting.sh
. ./library/machineOs.sh

#===================================================================================================

deviceSerial=""
#build=""
#choice=""
#bgName=""
#cmd=""
#opt=""

fileName="test"

appInstallPath=""
RecordFolder="/sdcard"
SearchForFile="*.*"
deviceCameraFolder="/sdcard/DCIM/Camera"
deviceScreenshotFolder="/sdcard/Pictures/Screenshots"

logcatExtension="txt"
bugreportExtension="txt"
bugreport2Extension="zip"
screenshotExtension="png"
screenrecordExtension="mp4"

nowTime=$(date +'%H%M%S')
nowDate=$(date +'%Y%m%d')
nowDateTime=$(date +'%Y%m%d%H%M%S')

#declare -r TRUE=0
#declare -r FALSE=1

#===================================================================================================

checkMyOsType

if [[ "$myOS" == "linux" ]]; then
	myScripts="${myScriptsDebian}"
elif [[ "$myOS" == "mac" ]]; then
	myScripts="${myScriptsOSX}"
fi

#--- where it will checke all the scripts
myShellScripts="${myScripts}/Shell"
myPythonScripts="${myScripts}/Python"

#--- where it will write all the script's log messages
myScriptLogsDir="${myShellScripts}/logs"
myScriptLogsFile="${myScriptLogsDir}/scriptLog-$nowDate.txt"
#===================================================================================================

#--- where it will store the bugreports, logcats, screenshots, pulled videos/images
if [ ! -d "$myLogs" ]; then
	`mkdir -p ${myLogs}`
fi

#--- from where it will search for the general apps
if [ ! -d "$myAppDir" ]; then
	`mkdir -p ${myAppDir}`
fi


if [ ! -d "$myLocal" ]; then
	checkMyOsType
	if [[ "$myOS" == "linux" ]]; then
		`mkdir -p ${myLocal}`
	fi
fi

#===================================================================================================

function writeToLogsFile() {
#$1 - Message to write
#$return -
	if [ $# -lt 1 ]; then # if there is less than 1 arguments passed to this function
		echo -e -n "@@ No argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )" >> "$myScriptLogsFile"
		exit 1
	else
		if [ ! -d "$myScriptLogsDir" ]; then # if there is no logs directory
			mkdir -p "$myScriptLogsDir" # create a logs directory using the path set in mySetup.txt
		fi

		if [ ! -f "$myScriptLogsFile" ]; then # if there is no logs file
			touch "$myScriptLogsFile" # create a logs file using the file name set in mySetup.txt
		fi

		#echo -e -n "\n********** Please check the log file for more info ********** \n\n"

		echo -e -n "********** $nowTime ********** \n" >> "$myScriptLogsFile"
		echo -e -n "$nowTime ->|<- $1\n" >> "$myScriptLogsFile" # append the passed message to the log file
	fi

	echo -e -n "\n" >> "$myScriptLogsFile" # append a newline
}

#===================================================================================================

#----- build the array for list of devices recognised in "ADB / Fastboot"
function buildDeviceSnArray() {
#$return -
	local let i=0
	local line

	buildAdbDevices

	buildFastbootDevices

	DEVICE_COUNT=${#DEVICE_ARRAY[*]} # get the devices count by the number of array elements in device serial array
}

#----- append the build info of each devices in the list
function buildAdbDevices() {
	while read line
	do
#		echo " line - $line"

		# awk $1 - the device serial number
		# awk $2 - the status: device/fastboot/recovery/offline/unauthorized
		local adbDEVICEstatus="`echo $line | awk '{print $2}' `" # get the status of the device

#		echo " Status - $adbDEVICEstatus"

		if [ -n "$line" ] # if there is line available (if the $line is not null)
		then
			case "$adbDEVICEstatus" in
				"device"|"recovery"|"unauthorized"|"offline")
					local adbDEVICEsn="`echo $line | awk '{print $1}' `" # get the device serial number
					DEVICE_ARRAY[i]="$adbDEVICEsn" # append the device serial number to the device serial array

					if [[ "$adbDEVICEstatus" == "device" ]]; then
						DEVICE_ARRAY_STATUS[i]=`echo "adb"` # if the status is device, then save the status as adb to the device status array
					else
						DEVICE_ARRAY_STATUS[i]="$adbDEVICEstatus" # else save the original status to the device status array
					fi

					let i=$i+1
					;;
			esac
		fi

	done < <(adb devices) # read and append all the devices in adb state
}

function buildFastbootDevices() {
	# build the array of device serial and its status, which are in FASTBOOT mode
	while read line
	do
		
		local fastbootDEVICEstatus="`echo $line | awk '{print $2}' `" # get the status of the device

		if [ -n "$line" ] && [ "$fastbootDEVICEstatus" == "fastboot" ] # if its not a null line and device status is fastboot
		then
			local fastbootDEVICEsn="`echo $line | awk '{print $1}' `" # get the device serial number
			DEVICE_ARRAY[i]="$fastbootDEVICEsn" # append the device serial number to the device serial array
			DEVICE_ARRAY_STATUS[i]="$fastbootDEVICEstatus" # append the device status to the device status array
			let i=$i+1
		fi

	done < <(fastboot devices) # read and append all the devices in fastboot mode
}

#----- append the build info of each devices in the list
function appendBuildInfo() {
# $1 - device serial number
#$return -
# Append the build info (at display time)
	if [ $# -lt 1 ]; then
		writeToLogsFile "@@ No argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		local BUILD_INFO="$( adb -s $1 wait-for-device shell getprop ro.build.description )"
		#echo -e "$LIST_ID""$1" "\t" "$BUILD_INFO"
		echo -e -n "$BUILD_INFO"
	fi
}

#----- display the list of devices
function displayDeviceList() {
#$return -
	if [ $DEVICE_COUNT -gt 0 ]; then
		echo ""

		local let i=0
		local let j=0

		for (( i=0; i<$DEVICE_COUNT; i++ )) # run the loop until the device count
		do
			let j=$i+1 # to generate the display count number

			echo -e -n " $j. ${DEVICE_ARRAY[i]}" # display the i'th serial number of the array

			case "${DEVICE_ARRAY_STATUS[i]}" in
				"recovery"|"fastboot"|"offline"|"unauthorized") # if the device status is other than adb, then display the stats in red
					formatMessage " - ${DEVICE_ARRAY_STATUS[i]}" "E"
					;;
				"adb")
					local deviceModel=`adb -s ${DEVICE_ARRAY[i]} wait-for-device shell getprop ro.product.model | tr -d "\r\n"`
					local deviceHardwareCodename=`adb -s ${DEVICE_ARRAY[i]} wait-for-device shell getprop ro.hardware | tr -d "\r\n"`
					echo -e -n "${txtRst} - ${txtPur}$deviceModel${txtRst} ($deviceHardwareCodename)" #append the device model: Nexus 5
					
			esac

			echo ""
		done
	else
		formatMessage "\n There are no devices connected to the USB.\n" "E"
	fi
}

#----- check if the item # for the device selection was valid
function checkDeviceChoiceValidity() {
# $1 - takes the choice number entered
#$return -
	if [ $# -lt 1 ]; then
		writeToLogsFile "@@ No argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		if echo "$1" | grep "^[0-9]*$">aux; then

			if [[ "$1" -gt "$DEVICE_COUNT" || "$1" -lt "1" ]]; then
				formatMessage " Dude '$1' is not in this list and you know it. Come on.\n" "W"
				#exit
				getDeviceChoice
			else
				DEVICE_ARRAY_INDEX="$1"
				let "DEVICE_ARRAY_INDEX = $DEVICE_ARRAY_INDEX - 1"
			fi
		else
			formatMessage " Come on Dude, pick a number. '$1' is not a number.\n" "W"
			getDeviceChoice
		fi
	fi
}

#----- read the item # from the device list
function getDeviceChoice() {
#$return -
	buildDeviceSnArray

	local DEVICE_CHOICE="0"

	if [ $DEVICE_COUNT -gt 0 ]; then

		if [ $DEVICE_COUNT -gt 1 ]; then #<-- if there are more than 1 device
			displayDeviceList
			echo -e -n "\n${txtBld} Enter Choice [1 - $DEVICE_COUNT] : ${txtRst}"
			read DEVICE_CHOICE;
			checkDeviceChoiceValidity $DEVICE_CHOICE

			deviceSerial=${DEVICE_ARRAY[${DEVICE_ARRAY_INDEX}]}

		else  #<-- if there is only 1 device connected
			formatMessage "\n There is only 1 device connected to the USB\n${txtRst}" "W"
		 	deviceSerial=${DEVICE_ARRAY[0]}
		fi

	else #<-- if the device count is less than zero, i.e., there is no device connected
		formatMessage "\n There are no devices connected to the USB.\n\n" "E"
		exit 1
	fi
}
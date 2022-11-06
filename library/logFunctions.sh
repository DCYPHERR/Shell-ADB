newBugreportSdkVersion="7.0"

adbExecOutVersion=""

#===================================================================================================

#----- file name format
function getFormatedFileName() {
#$1 is device serial number
#$2 is filename
#$return -
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else

        if [ "$( isGoogleDevice $1 )" == "true" ]; then
            #echo -e -n "$( getDeviceName $1)_$( getDeviceBuild $1)_${2}_${nowTime}"
            echo -e -n "$( getDeviceName $1)_${2}_${nowTime}"
        else
            echo -e -n "${1}_${2}_${nowTime}"
        fi
	fi
}

#===================================================================================================

function takeBugreport() {

	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#TODO check the device version and then choose which file extension type to use
		# Pre-M (<6.0) txt, M (=6.0) txt, Post-M (>=7.0) zip

		local compareBuildVersionStatus=$( compareDeviceBuildVersion ${1} ${newBugreportSdkVersion} )

		if [[ ${compareBuildVersionStatus} == "same" || ${compareBuildVersionStatus} == "greater" ]]; then
			adb -s "$1" wait-for-device bugreport `echo ${myLogs}/`${2}.${bugreport2Extension}
			#echo -e -n " zip"
		else
			adb -s "$1" wait-for-device bugreport > `echo ${myLogs}/`${2}.${bugreportExtension}
			#echo -e -n " txt"
		fi

	fi
}

function getBugreport() {
#1 - device serial number
#2 - filename
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		echo -e -n "\n Taking Bugreport... "

		local compareBuildVersionStatus=$( compareDeviceBuildVersion ${1} ${newBugreportSdkVersion} )

		if [[ ${compareBuildVersionStatus} == "same" || ${compareBuildVersionStatus} == "greater" ]]; then
			echo -e -n " ${2}.${bugreport2Extension}\n\n"
		else
			echo -e -n " ${2}.${bugreportExtension}\n\n"
		fi

		takeBugreport ${1} ${2}

		echo -e -n " ...Done\n"
	fi
}

function saveLogcat() {
#$1 is device serial number
#$2 is filename
#$return -
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		adb -s "$1" logcat -v threadtime | tee `echo ${myLogs}/`${2}-logcat.${logcatExtension}
	fi
}

function saveKernelLogcat(){
#$1 is device serial number
#$2 is filename
#$return -
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		adb -s "$1" logcat -v threadtime -b kernel | tee `echo ${myLogs}/`${2}-logcat_kernel.${logcatExtension}
	fi
}

function clearLogcat() {
#$1 is device serial number
#$2 is filename
#$return -
	if [ $# -lt 1 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		adb -s "$1" logcat -c
	fi
}

function saveScreenshotInDevice() {
#$1 is device serial number
#$2 is filename
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#save the screenshot in the device sdcard screenshot folder
		adb -s "$1" wait-for-device shell screencap ${deviceScreenshotFolder}/${2}.${screenshotExtension}
	fi
}

function saveScreenshotInMachine() {
#$1 is device serial number
#$2 is filename
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		
		adb -s "$1" wait-for-device shell screencap -p > `echo ${myLogs}/`${2}.${screenshotExtension}

	fi
}

function takeScreenshot() {
#$1 is device serial number
#$2 is filename
#$return -
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		
		saveScreenshotInMachine "${1}" "${2}"
	fi
}

function getScreenshot() {

	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		echo -e -n "\n Taking Screenshot... "
		echo -e -n " ${2}.${screenshotExtension}"
		takeScreenshot ${1} ${2}

		
		echo -e -n "\n ...Done\n"
	fi
}

function recordDeviceVideo() {

	if [ $# -lt 3 ]; then
		writeToLogsFile "@@ No 3 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#adb -s "$1" wait-for-device shell "screenrecord --verbose --bit-rate 4000000 ${2}/${3}.${screenrecordExtension}" # <- 4 Mbps
		#adb -s $1 wait-for-device shell "screenrecord --verbose --bit-rate 8000000 $2/${3}.${screenrecordExtension}" # <- 8 Mbps
		adb -s "$1" wait-for-device shell "screenrecord ${2}/${3}.${screenrecordExtension}"
	fi
}
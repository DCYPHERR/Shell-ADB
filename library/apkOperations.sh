apkDevicePath=""
apkPackageName=""

Search_APK_COUNT=0

function searchAPK() {

	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		local let i=0
		local line

		Search_APK_COUNT=0

		
		
		for line in `adb -s $1 wait-for-device shell pm list packages -f | grep -i "$2" | tr -d '\r'`
		do
			if [ -n "$line" ]; then
				APK_ARRAY[i]="$line"
				let i=$i+1
			fi
		done

		Search_APK_COUNT=${#APK_ARRAY[*]}
	fi
}

function splitAPKpath() {

    if [ $# -lt 1 ]; then
        writeToLogsFile "@@ No argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
        exit 1
    else
        
        apkDevicePath=`echo "${1}" | cut -f2 -d":" | rev | cut -f2-4 -d"=" | rev | tr -d "\r\n"` # /data/app/com.google.android.music-TDA3dRVEUj0FFpvpliQgyQ==/base.apk
        apkPackageName=`echo "${1}" | cut -f2 -d":" | rev | cut -f1 -d"=" | rev | tr -d "\r\n"` # com.google.android.music
    fi
}

function displayAPKlist() {
#$return - 
	if [ ${Search_APK_COUNT} -eq 1 ]; then #if there is only 1 matching apk
		formatMessage " There is only 1 APK/Package with matching string :\n\n" "W"
		splitAPKpath ${APK_ARRAY[0]}
		formatMessage " 1. ${apkPackageName} - ${apkDevicePath}\n"
	elif [ ${Search_APK_COUNT} -gt 1 ]; then #if there are more than one apk
		local i=0
		formatMessage " Following APKs/Packages found with matching string : \n\n" "I"
		
		for (( i=0; i<$Search_APK_COUNT; i++ ))
		do
			let j=$i+1
			#echo -e -n " $j. ${APK_ARRAY[i]}\n"
			splitAPKpath ${APK_ARRAY[i]}
			formatMessage " $j. ${apkPackageName} - ${apkDevicePath}\n"
		done
		
	else #if there are no matching apk
		formatMessage " There are no APKs/Packages installed having that string\n" "E"
	fi
}

function checkAPKChoiceValidity() {
#$1 - choice number
#$return - 
	if [ $# -lt 1 ]; then
		writeToLogsFile "@@ No argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		if echo "$1" | grep "^[0-9]*$">aux; then #if the input is numeric
			if [[ "$1" -gt "$Search_APK_COUNT" || "$1" -lt "1" ]]; then
				formatMessage " Dude '$1' is not choice in this list and you know it. Come on.\n" "W"
				writeToLogsFile " Entered '$1' which was not in choice range '$Search_APK_COUNT' : ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
				exit 1
			else
				APK_ARRAY_INDEX="$1"
				let "APK_ARRAY_INDEX = $APK_ARRAY_INDEX - 1"
			fi
		else #if the input is not numeric
			formatMessage " Come on Dude, pick a number. '$1' is not a number.\n" "W"
			writeToLogsFile " Entered '$1' instead of a number : ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
			exit 1
		fi
	fi
}

function apkOperations() {

		if [ $# -lt 3 ]; then
			writeToLogsFile "@@ No 3 arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
			exit 1
		else
			searchAPK ${1} ${2}

			local apkPath=""
			local APK_CHOICE
			local apkOperationChoice="n"

			if [ $Search_APK_COUNT -gt 0 ]; then
				displayAPKlist

				if [ $Search_APK_COUNT -gt 1 ]; then
					formatMessage "\n Enter APK Choice : "
					read APK_CHOICE
					echo " "
					checkAPKChoiceValidity $APK_CHOICE
					apkPath=${APK_ARRAY[$APK_ARRAY_INDEX]}

				elif [ $Search_APK_COUNT -eq 1 ]; then

					apkOperationOptionUppercase=`toUppercase $3`

					if [ "$apkOperationOptionUppercase" == "VERSION" ]; then
						apkPath=${APK_ARRAY[0]}
						echo ""
					else
						formatMessage "\n Do you want to $apkOperationOptionUppercase it ? [y/n] : " "Q"
						stty -echo && read -n 1 apkOperationChoice && stty echo
						formatYesNoOption $apkOperationChoice
						echo ""
						
						if [ "$( checkYesNoOption $apkOperationChoice )" == "yes" ]; then
							apkPath=${APK_ARRAY[0]}
						elif [ "$( checkYesNoOption $apkOperationChoice )" == "no" ]; then
							echo -e -n "\n"
							exit 1
						fi
					fi
				fi

				splitAPKpath ${apkPath}

		     

				case "$3" in
					[pP][uU][lL][lL]) #pull
						pullDeviceApp $1 $apkDevicePath ;;
					[cC][lL][eE][aA][rR]) #clear
						clearDeviceApp $1 $apkPackageName ;;
					[sS][tT][oO][pP]) #stop
						stopDeviceApp $1 $apkPackageName ;;
					[kK][iI][lL][lL]) #kill
						killDeviceApp $1 $apkPackageName ;;
					[sS][tT][aA][rR][tT]) #start
						startDeviceApk $1 $apkPackageName ;;
					[rR][eE][sS][tT][aA][rR][tT]) #restart
						restartDeviceApp $1 $apkPackageName ;;
					[uU][nN][iI][nN][sS][tT][aA][lL][lL]) #uninstall
						uninstallSelectedDeviceApp $1 $apkPath ;;
					[uU][nN][iI][nN][sS][tT][aA][lL][lL][uU][pP][dD][aA][tT][eE][sS]) #uninstallUpdates
						uninstallDeviceAppUpdates $1 $apkPackageName ;;
					[vV][eE][rR][sS][iI][oO][nN]) #version
						getDeviceAppVersion $1 $apkPackageName ;;
					*)
						writeToLogsFile " Unsupported argument \"${3}\" passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} ) "
						formatMessage " Unsupported argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )" "E"
						exit 1 ;;
				esac

			else
				formatMessage " No APKs installed with that name\n" "E"
			fi
		fi
}

#===================================================================================================

function appPID() {

	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		local appPID = `adb shell ps | grep "$2" | awk '{print $2}' | xargs adb shell kill`
		echo -e -n "$appPID"
	fi
}

#----- Kill
function killDeviceApp() {
#$1 - device serial number
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		local appProcessID = appPID $1 $2
		adb -s $1 shell kill $appProcessID
	fi
}


#----- Pull
function pullDeviceApp() {
#$1 - device serial
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else

			local dstFolder="$myAppDir"

			if [ "$( isAtHomeDevice $1 )" == "true" ]; then
				dstFolder="$myAAHDir"
			elif [ "$( isClockWorkDevice $1 )" == "true" ]; then
				dstFolder="$myACWDir"
			elif [ "$( isGearHeadDevice $1 )" == "true" ]; then
				dstFolder="$myAGHDir"
			elif [ "$( isGedDevice $1 )" == "true" ]; then
				dstFolder="$myAppDir"
			else
				dstFolder="$myAppDir"
			fi

			formatMessage " Your files will be saved in folder : $dstFolder" "M"
			formatMessage "\n Pulling APK..." "I"

			if [ "$( isAdbDevice $1 )" == "true" ]; then
				echo -e -n " $2\n"
				echo -e -n " "
				if [ "$( isDeviceBuildDevKey $1 )" == "true" ]; then
					adb -s $1 wait-for-device root >/dev/null 2>&1
					echo -e -n " "
					adb -s $1 wait-for-device pull $2 $dstFolder
					echo " "
				else
					formatMessage " Device doesnot support root access\n" "E"
				fi
			else
				formatMessage " Device is not in adb mode\n" "E"
				#echo " ${txtRed}Device is not in adb mode${txtRst}\n"
			fi
#		else
#			echo -e -n " ${txtRed}No APKs installed with that name${txtRst}\n"
#		fi
	fi
}

#----- Clear
function clearDeviceApp() {
#$1 - device serial
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#local apkPath=`echo "${2}" | cut -f2 -d"=" | tr -d "\r\n"`

		if [ "$( isAdbDevice $1 )" == "true" ]; then
			formatMessage " Clearing APK $2 data\n" "W"
			echo -e -n " "
			adb -s $1 wait-for-device shell pm clear $2
			echo " "
		else
			formatMessage " Device is not in adb mode$\n" "E"
			#echo " ${txtRed}Device is not in adb mode${txtRst}\n"
		fi
	fi
}

#----- Uninstall the selected APKs
function uninstallSelectedDeviceApp() {
#$1 - device serial
#$2 - apk path with package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
#       local apkDevicePath=`echo "${2}" | cut -f2 -d":" | cut -f1 -d"=" | tr -d "\r\n"`
#		local apkPackageName=`echo "${2}" | cut -f2 -d":" | cut -f2 -d"=" | tr -d "\r\n"`
        splitAPKpath ${apkPath}
		formatMessage "\n Uninstalling APK...\n" "W"

		if [ "$( isAdbDevice $1 )" == "true" ]; then
			formatMessage " $apkDevicePath - $apkPackageName\n"
			formatMessage " adb uninstall - "
			adb -s $1 wait-for-device uninstall $apkPackageName
			formatMessage " Trying to delete the file...\n" "W"
			if [ "$( isDeviceBuildDevKey $1 )" == "true" ]; then
				formatMessage " adb root - "
				adb -s $1 wait-for-device root
				formatMessage " adb remount - "
				adb -s $1 wait-for-device remount
				formatMessage " adb shell rm - "
				adb -s $1 wait-for-device shell rm -rf $apkDevicePath
				formatMessage "Done\n\n Rebooting..."
				adb -s $1 wait-for-device reboot
			else
				formatMessage " Device doesnot support root access\n" "E"
			fi
			echo -e "\n"
		else
			formatMessage " Device is not in adb mode$\n" "E"
			#echo " ${txtRed}Device is not in adb mode${txtRst}\n"
		fi
	fi
}

function uninstallDeviceAppUpdates() {
#$1 - device serial
#$2 - package name
#$return - 
    if [ $# -lt 2 ]; then
        writeToLogsFile "@@ No arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
        exit 1
    else
		if [ "$( isAdbDevice $1 )" == "true" ]; then
			formatMessage " Uninstall App $2 updates\n" "W"
			echo -e -n " "
			adb -s $1 wait-for-device shell pm uninstall $2
			echo " "
		else
			formatMessage " Device is not in adb mode$\n" "E"
			#echo " ${txtRed}Device is not in adb mode${txtRst}\n"
		fi
    fi
}

function uninstallDeviceAppUpdatesPrompt() {
#$1 - device serial
#$2 - package name
#$return - 
    if [ $# -lt 2 ]; then
        writeToLogsFile "@@ No arguments passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
        exit 1
    else
        adb -s $1 wait-for-device shell am start -a android.intent.action.DELETE -d package:"$2"
    fi
}

#----- Start an app
function startDeviceApk() {
#$1 - device serial number
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#local apkPath=`echo "${2}" | cut -f2 -d":" | cut -f2 -d"=" | tr -d "\r\n"`
		adb -s $1 shell am start "$2"
	fi
}

#----- Stop an app
function stopDeviceApp() {
#$1 - device serial number
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#local apkPath=`echo "${2}" | cut -f2 -d":" | cut -f2 -d"=" | tr -d "\r\n"`
		adb -s $1 shell am force-stop "$2"
	fi
}

#----- Restart an app
function restartDeviceApp() {
#$1 - device serial number
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		#local apkPath=`echo "${2}" | cut -f2 -d":" | cut -f2 -d"=" | tr -d "\r\n"`
		adb -s $1 shell am force-stop "$2"
		adb -s $1 shell am start "$2"
	fi
}

function getDeviceAppVersion() {
#$1 - device serial number
#$2 - package name
#$return - 
	if [ $# -lt 2 ]; then
		writeToLogsFile "@@ No 2 argument passed to ${FUNCNAME[0]}() in ${BASH_SOURCE} called from $( basename ${0} )"
		exit 1
	else
		local i=0
			
		while read line
		do
			if [ -n "$line" ]; then
				APK_VERSION_ARRAY[i]="$line"
				let i=$i+1
			fi
		done < <(adb -s ${1} wait-for-device shell dumpsys package ${2} | grep -i versionname | cut -f2 -d"=" | tr -d "\r")
		#done < <(adb -s ${1} wait-for-device shell pm dump ${2} | grep -i versionname | cut -f2 -d"=" | tr -d "\r")

		APK_VERSION_COUNT=${#APK_VERSION_ARRAY[*]}
		formatMessage " Installed version(s):\n" "I"

#		for (( i=0; i<$APK_VERSION_COUNT; i++ ))
#		do
#			let j=$i+1
#			formatMessage " $j. ${APK_VERSION_ARRAY[i]}\n"
#		done

		if [ $APK_VERSION_COUNT -gt 0 ]; then
			formatMessage " 1. Current installed Version - ${APK_VERSION_ARRAY[0]}\n"

			if [ $APK_VERSION_COUNT -gt 1 ]; then
				formatMessage " 2. System default Version - ${APK_VERSION_ARRAY[1]}\n"
			fi
		fi
	fi
}
. ./library/mainFunctions.sh
. ./library/textFormatting.sh
. ./library/deviceOperations.sh
. ./library/deviceFileOperations.sh
. ./library/apkOperations.sh

if [ $# -lt 1 ]; then
	pbold "\n Enter the apk string to search : "
	read APKname
else
	APKname="$1"
fi

getDeviceChoice
displaySelectedDevice $deviceSerial

if [ "$( isAdbDevice $deviceSerial )" == "true" ]; then
	apkOperations $deviceSerial ${APKname} "restart"
else
	echo -e " Device is not in 'adb' mode"
fi

echo ""
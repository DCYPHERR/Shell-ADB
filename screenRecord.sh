. ./library/mainFunctions.sh
. ./library/textFormatting.sh
. ./library/deviceOperations.sh
. ./library/logFunctions.sh

if [ $# -lt 1 ]; then
	pbold "\n Enter the Video File name : "
	read fileName
else
	fileName="$1"
fi

getDeviceChoice
displaySelectedDevice $deviceSerial

if [ $( isAdbDevice $deviceSerial ) == "true" ]; then
	
		fileName=`echo $( getFormatedFileName $deviceSerial ${fileName} )`

		echo -e -n " Your video will be saved in ${RecordFolder} as : ${fileName}.mp4\n\n"

		
		recordDeviceVideo $deviceSerial ${RecordFolder} ${fileName}
else
	echo -e -n " Device is not in adb mode\n"
fi
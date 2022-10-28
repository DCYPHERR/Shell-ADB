. ./library/mainFunctions.sh
. ./library/textFormatting.sh
. ./library/deviceOperations.sh
. ./library/keycodeEvents.sh

if [ $# -lt 1 ]; then
    getDeviceChoice
else
    buildDeviceSnArray
    deviceSerial="$1"
fi

displaySelectedDevice $deviceSerial

inputevent="null"

while [ "$inputevent" != "n" ]
do
	
			echo -e -n " --> Enter the text you want to input : "
			read inputtext
			adb -s $deviceSerial shell input text "${inputtext}"
	
done

echo ""
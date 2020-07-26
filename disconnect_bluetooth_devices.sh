#!/bin/zsh
#
# Description: A script that disconnects bluetooth devices 
# after a predetermined idle time.
#
# Requires blueutil - https://github.com/toy/blueutil (see below)

# All times are in seconds. Modify these as needed but keep in mind that
# TIME_BEFORE_DISCONNECT_SEC needs to be greater than CHECK_INTERVAL_SEC 
# for the script to function properly.
TIME_BEFORE_DISCONNECT_SEC=300
CHECK_INTERVAL_SEC=60

# To install blueutil use homebrew - https://brew.sh
# Type `brew install blueutil` in the terminal.
BLUEUTIL=/usr/local/bin/blueutil

# You will need to use one of the following methods to create your device list.
# The first method is automatic and will use all of your paired bluetooth devices.
# The second method requires that you supply the list of hardware address manually.
# Please pick your preferred method by commenting/uncommenting.

# Automatic method:
DEVICE_LIST=($($BLUEUTIL --paired | awk '{print $2}' | cut -c 1-17))

# Manual method:
#DEVICE_LIST=(10-94-bb-aa-42-ec 10-94-bb-b5-4e-af)

# Initialize variables
VERSION=1.3
CONNECTED=true
TEST_MODE=false
TIME_BEFORE_DISCONNECT_NANOSEC=$(echo "$TIME_BEFORE_DISCONNECT_SEC * 1000000000" | bc -l)

test_print () {
    if [[ "$TEST_MODE" == "true" ]] && [ -n "$1" ]; then
		echo $1
	fi
}  

case $1 in
    --version )
    	echo $VERSION
    	exit
    	;;
    --test ) 
    	TEST_MODE=true
    	;;
    * )
        echo 'USAGE: /bin/zsh /path/to/disconnect_bluetooth_devices.sh [ --test | --version | --help ]'
        exit
        ;;
esac

test_print "Your devices: $DEVICE_LIST"


# The is the main loop. It will loop forever running once a minute by default.
while true; do
    IDLE_TIME=$(ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF}')
    if [ $(echo "$IDLE_TIME >= $TIME_BEFORE_DISCONNECT_NANOSEC" | bc -l) -eq 1 ]; then
    	IS_IDLE=true
    else 
    	IS_IDLE=false
	fi
    
    if [[ "$CONNECTED" == "false" ]] && [[ "$IS_IDLE" == "false" ]]; then
        CONNECTED=true
    
    elif [[ "$CONNECTED" == "true" ]] && [[ "$IS_IDLE" == "true" ]] || [[ "$TEST_MODE" == "true" ]]; then
        CONNECTED=false
        
        for DEVICE in $DEVICE_LIST; do 
            test_print "Disconnecting... $DEVICE"
            result=$($BLUEUTIL --disconnect $DEVICE 2>&1)
            test_print $result
            sleep 2
            
        done
           
    fi
    
    # Uncomment the following line for debugging
    #echo $(date) : CONNECTED = $CONNECTED, IDLE = $IS_IDLE
    
    if [[ "$TEST_MODE" == "true" ]]; then
        echo "Test complete."
        exit
    else
        sleep $CHECK_INTERVAL_SEC

    fi
    
done

#!/bin/bash

# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the
# local /etc/hosts file

#check to see if the script is run in verbose mode
VERBOSE=0 # 1 = ON 0 = OFF
if [[ $1 == "-verbose" ]]; then #if the first argument is -verbose
	VERBOSE=1 #enable verbose mode
	VERBOSE_FLAG="-verbose" #set the verbose flag
fi

#Assigning variables to make it easy to switch information without needing to retype lines
CONFIGURE_SCRIPT="configure-host.sh"
SERVER1="server1-mgmt" #hostname of server1
SERVER2="server2-mgmt" #hostname of server2
SERVER1_IP="192.168.16.3" #desired IP address for server1
SERVER2_IP="192.168.16.4" #desired IP address for server2
USER="remoteadmin" #the username for SSH connections

#Deploy the script on server1
scp $CONFIGURE_SCRIPT $USER@$SERVER1:/root #copy the script to server1
ssh $USER@$SERVER1 -- "/root/$CONFIGURE_SCRIPT -name loghost -ip $SERVER1_IP -hostentry webhost $SERVER2_IP $VERBOSE_FLAG" #run the script on server 1 with required settings

#Deploy the script on server2
scp $CONFIGURE_SCRIPT $USER@$SERVER2:/root #copy the script to server2
ssh $USER@$SERVER2 -- "/root/$CONFIGURE_SCRIPT -name webhost -ip $SERVER2_IP -hostentry loghost $SERVER1_IP $VERBOSE_FLAG" #run the script on server2 with required settings

#update the local machine /etc/hosts file
./$CONFIGURE_SCRIPT -hostentry loghost $SERVER1_IP $VERBOSE_FLAG #add or update the entry for server1 locally
./$CONFIGURE_SCRIPT -hostentry webhost $SERVER2_IP $VERBOSE_FLAG #add or update the entry for server2 locally


#!/bin/bash

#Blocking TERM HUP AND INT
trap '' TERM HUP INT

#Function to log messages to the system log using logger command
log() {
	logger "$1" #Sends the message provided as an argument to the system log
}

#Creating a VERBOSE variable to track if it is 0 = OFF 1 = ON
VERBOSE=0

#Command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		-verbose) #If the -verbose flag is provided enable verbose output
			VERBOSE=1
			;;
		-name) #If the -name flag is provided, capture the desired hostname
			DESIRED_NAME="$2" #the next argument is the hostname
			shift #skip to the next argument after the value
			;;
		-ip) #If the IP flag is provided, capture the desired IP address
			DESIRED_IP="$2" #the next argument is the desired IP address
			shift #skip to the next argument after the value
			;;
		-hostentry) #If the hostentry flag is provided capture the desired hostname and IP for /etc/hosts
			HOST_NAME="$2" #the next argument is the desired hostname
			HOST_IP="$3" #the argument after the hostname is the desired IP
			shift 2 #skip the next two arguemnts (name and IP)
			;;
		*) #Handle invalid options
			echo "Invalid option: $1" #Display an error message for the invalid argument
			exit 1 
			;;
	esac
	shift
done

#Check and update the hostname if necessary
if [[ -n $DESIRED_NAME ]]; then #only proceed if a desired hostname is provided
	CURRENT_NAME=$(hostname) #retrieve the current hostname
	if [[ "$CURRENT_NAME" != "$DESIRED_NAME" ]]; then #check to see if the desired hostname is different
		echo "$DESIRED_NAME" > /etc/hostname #Update the hostname in /etc/hostname
		sed -i "s/$CURRENT_NAME/$DESIRED_NAME/g" /etc/hosts #update /etc/hosts with the new hostname
		hostnamectl set-hostname "$DESIRED_NAME" # apply the new hostname to the running system
		[[ $VERBOSE -eq 1 ]] && echo "Hostname updated to $DESIRED_NAME"
		log "Hostname changed from $CURRENT_NAME to $DESIRED_NAME"
	elif [[ $VERBOSE -eq 1 ]]; then
		echo "Hostname is already $DESIRED_NAME" #Tell the user the desired name is already active
	fi
fi

#Check and update the IP address if necessary
if [[ -n $DESIRED_IP ]]; then #checks to see if a desired IP address is provided
	CURRENT_IP=$(hostname -I | awk '{print $1}')
	PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}')
	if [[ "$CURRENT_IP" != "$DESIRED_IP" ]]; then
		cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
 version: 2
 ethernets:
  $PRIMARY_INTERFACE:
   dhcp4: false
   addresses:
    - $DESIRED_IP/24
EOF
		chmod 600 /etc/netplan/01-netcfg.yaml
		chown root:root /etc/netplan/01-netcfg.yaml

		netplan apply #apply the new network configuration
		[[ $VERBOSE -eq 1 ]] && echo "IP Updated to $DESIRED_IP on interface $PRIMARY_INTERFACE" #output changes if verbose mode is active
		log "IP address changed to $DESIRED_IP on interface $PRIMARY_INTERFACE" #log the changes
	elif [[ $VERBOSE -eq 1 ]]; then
		echo "IP address is already set to $DESIRED_IP" #tell the user the desired IP is already active
	fi
fi

#Add or update host entry in /etc/hosts if needed
if [[ -n $HOST_NAME && -n $HOST_IP ]]; then #only proceed if both hostname and IP address are provided
	if ! grep -q "$HOST_IP $HOST_NAME" /etc/hosts; then #check if the entry already exists in /etc/hosts
		echo "$HOST_IP $HOST_NAME" >> /etc/hosts #add the new entry to /etc/hosts
		[[ $VERBOSE -eq 1 ]] && echo "Host entry $HOST_NAME added with $HOST_IP" #output changes if verbose mode is enabled
		log "Host entry $HOST_NAME with IP $HOST_IP added to /etc/hosts" #logging the changes
	elif [[ $VERBOSE -eq 1 ]]; then
		echo "Host entry $HOST_NAME already exists with IP $HOST_IP" #tell the user no changes are needed
	fi
fi 

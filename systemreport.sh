#!/bin/bash

#get starting system information
USER=$(whoami)
DATE=$(date)
HOST=$(hostname)
OS=$(lsb_release -d | cut -f2-) #using cut -f2- to remove Description:
UPTIME=$(uptime -p) #uses -p for pretty output

#Getting Hardware information
CPU_MODEL=$(lscpu | grep 'Model name' | awk -F: '{ print $2 }' | xargs) #using -F: to get information after :
CPU_SPEED=$(lscpu | grep 'CPU MHz' | awk -F: '{ print $2 }'| xargs) #xargs for output cleanup
MAX_CPU_SPEED=$(lscpu | grep 'Max MHz' | awk -F: '{ print $2 }' |xargs)
#using print $2 after awk -F: to find the second word input in the input field
RAM=$(free -h | grep 'Mem:' | awk '{ print $2 }')
DISK=$(lsblk -o NAME,SIZE,MODEL | grep -v loop)
VIDEO=$(lspci | grep -i vga | awk -F: '{ print $2 }' | xargs) #using grep -i because we want either VGA or vga

#getting network information
FQDN=$(hostname -f) #-f for FQDN
HOST_IP=$(hostname -I | awk '{print $1}')
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS_SERVER=$(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}') #using /etc/resolv config fie to find the nameserver
INTERFACE=$(ip -o -f inet addr show | awk '{ print $4 }') #this is to get the IP address in CIDR format
NETWORK_CARD=$(lspci | grep -i ethernet | awk -F: '{print $2}' | xargs) #grep ethernet to find the network card

#getting system status information
USERS_LOGGED=$(who | awk '{ print $1 }' | sort | uniq | xargs) #using sort to make duplicates beside eachother for uniq to remove
DISK_SPACE=$(df -h --output=target,size | grep '^/' | xargs) #-h to make it human readable and we only want target and size
PROCESS_COUNT=$(ps aux | wc -l) #a for all users u for detailed information and x for background processes then wc -l will return the number of lines of processes active
LOAD_AVERAGES=$(cat /proc/loadavg | awk '{ print $1, $2, $3}')
MEM_ALLOCATED=$(free -h)
LIST_PORTS=$(ss -ltn | awk '{ print $4 }' | cut -d: -f2 | xargs)
UFW_RULES=$(sudo ufw status | tail -n +3) #using tail -n +3 to start reading from the 3rd line to skip headers

#putting all of the gathered information into a readable report.
#using cat EOF to encase the report so I dont need to write echo every line

cat <<EOF

System Report generated by $USER, $DATE

System Information
------------------
Hostname: $HOST
OS: $OS
Uptime: $UPTIME

Hardware Information
--------------------
CPU: $CPU_MODEL
Speed: $CPU_SPEED MHz / $MAX_CPU_SPEED MHz
RAM: $RAM
Disk(s): $DISK
Video: $VIDEO

Network Information
-------------------
Fully Qualified Domain Name: $FQDN
Host Address: $HOST_IP
Gateway IP: $GATEWAY
DNS Server: $DNS_SERVER 
Interface Name: $NETWORK_CARD
IP Address (CIDR): $INTERFACE

System Status
-------------
Users Logged In: $USERS_LOGGED
Disk Space: $DISK_SPACE
Process Count: $PROCESS_COUNT
Load Averages: $LOAD_AVERAGES
Memory Allocation: $MEM_ALLOCATED
Ports Listening: $LIST_PORTS
UFW Rules: $UFW_RULES

EOF


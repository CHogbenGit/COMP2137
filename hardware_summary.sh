#!/bin/bash

OS=$(lsb_release -d | cut -f2)
CPU=$(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)
RAM=$(free -h | grep Mem | awk '{print $2}')

echo "Hardware Summary Report"
echo "-----------------------"
echo "Operating System: $OS"
echo "CPU: $CPU"
echo "Installed RAM: $RAM"

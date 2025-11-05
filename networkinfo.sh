#!/bin/bash

echo "User Info"
echo "- User: $(whoami)"
echo "- Date: $(date +%H:%M:%S), $(date +%F)"
echo ""

INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)
echo "Network Information"
echo "- Network Name: $(iwgetid -r 2>/dev/null)"
echo "- IP Address: $(hostname -I)"
echo "- Mac Address: $(ifconfig $INTERFACE | grep ether | awk '{print $2}')"
echo "- Range: /$(ip addr show $INTERFACE | grep -oP "(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+" | cut -d/ -f2)"
echo "- Gateway: $(ip route | grep default | awk '{print $3}')"
echo "- Broadcast: $(ip addr show $INTERFACE | grep -oP '(?<=brd\s)\d+(\.\d+){3}')"

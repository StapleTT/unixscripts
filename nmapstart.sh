#!/bin/bash

# sudo check
if [ "$EUID" != 0 ] ; then
  echo -e "[!] \e[91mThis script must be run with sudo.\e[0m"
  echo "Exiting..."
  exit 126
fi

# current ip & netmask
echo "Your current IP address: $(hostname -I | awk '{print $1}')"
echo "Your netmask: /$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | awk -F"/" '{print $2}')"

# ask user for ip and range to scan
read -p "Enter network range to scan (ex: 192.168.1.0/24): " RANGE
if [ "$RANGE" == "" ] ; then
  echo -e "[!] \e[91mYou must input a network range.\e[0m"
  echo "Exiting..."
  exit 1
fi

echo ""
echo -e "[*] \e[94mStarting scan on $RANGE...\e[0m"

# get that scan going (ping scan)
SCAN=$(nmap -sn $RANGE)
echo ""

# format the output (i sure do wish -oG gave mac addresses)
echo "----------------------------------------"
echo "IP Address --- MAC Address --- Est. Name"
echo "----------------------------------------"

# this stack overflow thread is the only reason i figured it out
# https://stackoverflow.com/questions/51865475/parsing-nmap-output
echo "$SCAN" | awk '
  /Nmap scan report for/ {
    ip=$NF
    mac="N/A"
    vendor="Unknown"
  }

  /MAC Address:/ {
    mac=$3
    vendor = substr($0, index($0, "(") + 1)
    gsub(/\)/, "", vendor)
    print ip " --- " mac " --- " vendor
  }
'

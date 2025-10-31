#!/bin/bash

# Usage: ./ipstatic.sh <ip-address> <gateway> <dns1> <dns2>
# Example: ./ipstatic.sh 192.168.0.55 192.168.0.1 1.1.1.1 8.8.8.8

set -e

if [ -z "$1" ] || [ -z "$2" ] ; then
  echo "Usage: $0 <ip-address> <gateway> <dns1> <dns2>"
  exit 0
fi

IP_ADDR="$1"
GATEWAY="$2"
DNS1="${3:-1.1.1.1}"
DNS2="${4:-8.8.8.8}"

# Find name of connected wifi network
WIFI_CONN=$(nmcli -t -f NAME connection show --active | grep -v "lo")
if [ -z "$WIFI_CONN" ] ; then
  echo "No active Wi-Fi connection found."
  exit 0
fi

echo "Using Wi-Fi connection: $WIFI_CONN"

# Detect subnet prefix
SUBNET=$(ip -o -f inet addr show | grep wlan | awk '{print $4}' | head -n 1 | cut -d'/' -f2)

echo "Setting static IP: $IP_ADDR/$SUBNET"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS1, $DNS2"

# Apply static configuration
sudo nmcli con mod "$WIFI_CONN" ipv4.addresses "$IP_ADDR/$SUBNET"
sudo nmcli con mod "$WIFI_CONN" ipv4.gateway "$GATEWAY"
sudo nmcli con mod "$WIFI_CONN" ipv4.dns "$DNS1,$DNS2"
sudo nmcli con mod "$WIFI_CONN" ipv4.method manual

# Reload wifi connection
sudo nmcli con down "$WIFI_CONN" && sudo nmcli con up "$WIFI_CONN"

echo "Static IP set successfully!"

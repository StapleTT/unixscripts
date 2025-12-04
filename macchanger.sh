#!/bin/bash

# color codes so i don't bang my head against the wall
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
RESET="\e[0m"

# sudo check
if [ "$EUID" -ne 0 ]; then
  echo -e "[!] ${RED}Please run this script with sudo.${RESET}"
  exit 1
fi

# get network interface (wlan0, eth0, wlp9s0??)
IFACE=$(ip -o link show | awk -F': ' '/state UP/{print $2; exit}')

if [ -z "$IFACE" ]; then
  echo -e "[!] ${RED}No active network interface detected.${RESET}"
  exit 1
fi

# detect gateway ip address, exit if none found (will also use for example ip)
GATEWAY=$(ip route | awk '/default/ {print $3}')

if [ -z "$GATEWAY" ]; then
  echo -e "[!] ${RED}Could not detect gateway.${RESET}"
  exit 1
fi

# get current mac and ip address
CON_NAME=$(nmcli -t -f NAME,DEVICE connection show --active | grep "$IFACE" | cut -d: -f1)
CUR_IP=$(ip addr show "$IFACE" | awk '/inet /{print $2}')
NETMASK=$(ip addr show "$IFACE" | awk '/inet /{print $2}' | cut -d'/' -f2)
CUR_MAC=$(ip link show "$IFACE" | awk '/link\/ether/{print $2}')

echo "---------------------------------------------"
echo " Active Network:      $CON_NAME ($IFACE)"
echo " Current IP Address:  $CUR_IP"
echo " Current MAC Address: $CUR_MAC"
echo "---------------------------------------------"
echo ""

# ask the user for the new static ip
echo -e "[?] ${YELLOW}Enter desired static IP (ex. $GATEWAY):${RESET}"
read -p "> " NEW_IP

# is the new ip in the same subnet?
SUBNET=$(echo "$CUR_IP" | awk -F. '{print $1"."$2"."$3}')
NEW_SUBNET=$(echo "$NEW_IP" | awk -F. '{print $1"."$2"."$3}')

if [[ "$NEW_SUBNET" != "$SUBNET" ]]; then
  echo -e "[!] ${RED}IP must be on the same subnet (${SUBNET}.x). Exiting script...${RESET}"
  exit 1
fi

# check if new ip is already taken
IP_CLEAN=$(echo "$NEW_IP" | cut -d'/' -f1)

echo -e "[*] ${BLUE}Checking if IP $IP_CLEAN is available...${RESET}"
ping -c 1 -W 1 "$IP_CLEAN" &>/dev/null

if [ $? -eq 0 ]; then
  echo -e "[!] ${RED}IP address $IP_CLEAN is already in use! Exiting script...${RESET}"
  exit 1
else
  echo -e "[+] ${GREEN}IP address is available!${RESET}"
fi

if [ -z "$GATEWAY" ]; then
  echo -e "[!] ${RED}Could not detect gateway for this network.${RESET}"
  exit 1
fi

echo ""

# apply static ip
echo -e "[*] ${BLUE}Applying static IP...${RESET}"

nmcli con modify "$CON_NAME" ipv4.addresses "$IP_CLEAN/$NETMASK"
nmcli con modify "$CON_NAME" ipv4.gateway "$GATEWAY"
nmcli con modify "$CON_NAME" ipv4.dns "$GATEWAY 8.8.8.8"
nmcli con modify "$CON_NAME" ipv4.method manual

nmcli con up "$CON_NAME" &>/dev/null
echo -e "[+] ${GREEN}Static IP successfully applied!${RESET}"

echo ""

# ask the user if they want to change their mac address
echo -e "[?] ${YELLOW}Would you like to change your MAC address? (y/n):${RESET}"
read -p "> " CHANGE_MAC

if [[ "$CHANGE_MAC" =~ ^[Yy]$ ]]; then
  echo ""
  echo -e "${BLUE}Rules:${RESET}"
  echo " - Must be 6 pairs of hex digits"
  echo " - First hex pair must be even"
  echo " - Example: AA:BB:CC:DD:EE:FF"

  # ask user for new mac address
  echo -e "[?] ${YELLOW}Enter new MAC address:${RESET}"
  read -p "> " NEW_MAC

  # validate MAC format
  if [[ ! "$NEW_MAC" =~ ^([A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2}$ ]]; then
    echo -e "[!] ${RED}Invalid MAC address. Exiting script...${RESET}"
    exit 1
  fi

  # make sure first byte is even, otherwise exit
  FIRST_BYTE=$(echo "$NEW_MAC" | cut -d':' -f1)
  LAST_BIT=$((0x$FIRST_BYTE & 1))

  if [ "$LAST_BIT" -ne 0 ]; then
    echo -e "[!] ${RED}First byte must be even. Exiting script...${RESET}"
    exit 1
  fi

  # apply MAC address
  ip link set "$IFACE" down
  ip link set "$IFACE" address "$NEW_MAC"
  ip link set "$IFACE" up

  echo -e "[+] ${GREEN}MAC address changed successfully!${RESET}"
elif [[ "$CHANGE_MAC" =~ ^[Nn]$ ]]; then
  echo -e "[*] ${BLUE}Exiting script..."
  exit 1
else
  echo -e "[!] ${RED}Invalid input. Exiting script..."
  exit 1
fi

echo ""

# display final output
echo "---------------------------------------------"
echo " Final Network Details:"
echo " New IP Address: $IP_CLEAN/$NETMASK"
echo " New MAC Address: $NEW_MAC"
echo " Network Interface: $IFACE"
echo "---------------------------------------------"
echo ""

#!/bin/bash

# sudo check
if [ "$EUID" != 0 ]; then
  echo -e "[!] \e[91mThis script must be run with sudo.\e[0m"
  echo "Exiting..."
  exit 126
fi

NETWORK=$1
REPORT=vulnscan_$(date +"%F_%H-%M-%S").log

if [ -z "$NETWORK" ]; then
  echo "Usage: sudo $0 <ipaddr>"
  echo "Example: sudo $0 192.168.1.0/24"
  exit 1
fi

echo -e "[*] \e[94mScanning for hosts on $NETWORK...\e[0m"
echo -e "[*] \e[94mFull report will be written to $REPORT\e[0m"
echo "Network Vulnerability Report: $(date +"%F_%H-%M-%S")" >$REPORT
echo "" >>$REPORT

# discover active hosts
ACTIVE_HOSTS=$(nmap -sn "$NETWORK" -oG - | grep "Up" | awk '{print $2}')
TOTAL_HOSTS=$(echo $ACTIVE_HOSTS | wc -w)

if [ -z "$ACTIVE_HOSTS" ]; then
  echo -e "[!] \e[91mNo devices found.\e[0m"
  exit 0
fi

echo -e "[*] \e[94mFound devices ($TOTAL_HOSTS):\e[0m"
echo "$ACTIVE_HOSTS"
echo ""

sleep 1

COUNT=0
# loop through each device
for IP in $ACTIVE_HOSTS; do
  COUNT=$((COUNT + 1))
  echo -e "[*] \e[94mScanning $IP... ($COUNT/$TOTAL_HOSTS)\e[0m"
  TARGET=$IP
  TMP_OUTPUT=$(mktemp)

  # scan target & save to output variable
  nmap -A -Pn -T4 "$TARGET" -oN "$TMP_OUTPUT" >/dev/null 2>&1

  OS=$(grep "OS details" "$TMP_OUTPUT" | sed 's/OS details: //')
  MAC=$(grep "MAC Address" "$TMP_OUTPUT" | awk '{print $3}')
  VENDOR=$(grep "MAC Address" "$TMP_OUTPUT" | cut -d'(' -f2 | tr -d ')')

  # parse open ports
  OPEN_PORTS=$(grep -E "^[0-9]+/tcp" "$TMP_OUTPUT" |
    awk '{print $1}' |
    cut -d'/' -f1 |
    grep -E "^[0-9]+$" |
    paste -sd " " -)

  # rate vulnerability score by open ports
  SEVERE=(20 21 23 139 445 3389)
  MEDIUM=(22 80 443 8080 8443 3306 5900)
  LOW=(53 111)

  SCORE=0

  for port in $OPEN_PORTS; do
    if printf '%s\n' "${SEVERE[@]}" | grep -qx "$port"; then
      SCORE=$((SCORE + 3))
    elif printf '%s\n' "${MEDIUM[@]}" | grep -qx "$port"; then
      SCORE=$((SCORE + 2))
    elif printf '%s\n' "${LOW[@]}" | grep -qx "$port"; then
      SCORE=$((SCORE + 1))
    fi
  done

  # if the score is above 10, round down (it shouldn't even be that high)
  if [ "$SCORE" -gt 10 ]; then
    SCORE=10
  fi

  case $SCORE in
  # 0-3 (Low)
  [0-3])
    RISK="\e[92mLow risk"
    ;;
  # 4-6 (Medium)
  [4-6])
    RISK="\e[93mMedium risk"
    ;;
  # 7-10 (High)
  *)
    RISK="\e[91mHigh risk"
    ;;
  esac

  # Information shown while running script
  echo "OS Guess:    ${OS:-Unknown}"
  echo "MAC Address: ${MAC:-Unknown}"
  echo "Vendor:      ${VENDOR:-Unknown}"
  if [ -z "$OPEN_PORTS" ]; then
    echo -e "[!] \e[91mNo open ports detected.\e[0m"
  else
    echo "Open ports:  $OPEN_PORTS"
    echo "Vulnerability Score: $SCORE/10"
    echo -e "Risk: $RISK\e[0m"
  fi
  echo ""

  # information pasted into log file
  { # why two different things for output? because I wanted to use colors
    echo "Device Info for $TARGET" >>$REPORT
    echo "OS Guess:    ${OS:-Unknown}"
    echo "MAC Address: ${MAC:-Unknown}"
    echo "Vendor:      ${VENDOR:-Unknown}"
    if [ -z "$OPEN_PORTS" ]; then
      echo "No open ports detected."
    else
      echo "Open ports:  $OPEN_PORTS"
      echo "Vulnerability Score: $SCORE/10"
      echo "Risk: $(echo $RISK | cut -d "m" -f2-3)"
    fi
    echo ""
  } >>$REPORT

  rm "$TMP_OUTPUT"
done

echo -e "\e[92mDone! Results have been logged to $REPORT\e[0m"

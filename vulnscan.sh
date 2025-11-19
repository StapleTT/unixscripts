#!/bin/bash

# sudo check
if [ "$EUID" != 0 ] ; then
  echo -e "[!] \e[91mThis script must be run with sudo.\e[0m"
  echo "Exiting..."
  exit 126
fi

if [ -z "$1" ] ; then
  echo "Usage: sudo $0 <ipaddr>"
  exit 1
fi

OUTPUT="scan_$1.txt"

# scan target & save to output variable
echo -e "[*] \e[94mStarting scan on $1...\e[0m"
nmap -A -Pn "$1" -oN "$OUTPUT" >/dev/null 2>&1

echo ""

OS=$(grep "OS details" "$OUTPUT" | sed 's/OS details: //')
MAC=$(grep "MAC Address" "$OUTPUT" | awk '{print $3}')
VENDOR=$(grep "MAC Address" "$OUTPUT" | cut -d'(' -f2 | tr -d ')')

echo "==============================="
echo "          Device Info          "
echo "==============================="
echo "OS Guess:    ${OS:-Unknown}"
echo "MAC Address: ${MAC:-Unknown}"
echo "Vendor:      ${VENDOR:-Unknown}"

# parse open ports
OPEN_PORTS=$(grep -E "^[0-9]+/tcp" "$OUTPUT" \
  | awk '{print $1}' \
  | cut -d'/' -f1 \
  | grep -E "^[0-9]+$" \
  | paste -sd " " -)

if [ -z "$OPEN_PORTS" ] ; then
  echo -e "[!] \e[91mNo open ports detected.\e[0m"
  exit 0
fi

echo "Open ports:  $OPEN_PORTS"
echo ""

# rate vulnerability score by open ports
SEVERE=(20 21 23 139 445 3389)
MEDIUM=(22 80 443 8080 8443 3306 5900)
LOW=(53 111)

SCORE=0

for port in $OPEN_PORTS ; do
  if printf '%s\n' "${SEVERE[@]}" | grep -qx "$port" ; then
    SCORE=$((SCORE+3))
  elif printf '%s\n' "${MEDIUM[@]}" | grep -qx "$port" ; then
    SCORE=$((SCORE+2))
  elif printf '%s\n' "${LOW[@]}" | grep -qx "$port" ; then
    SCORE=$((SCORE+1))
  fi
done

# if the score is above 10, round down (it shouldn't even be that high)
if [ "$SCORE" -gt 10 ] ; then
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

echo "Vulnerability Score: $SCORE/10"
echo -e "Risk: $RISK\e[0m"

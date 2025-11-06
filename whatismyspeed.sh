#!/bin/bash

LOGFILE="$HOME/speedtest.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Is speedtest-cli even installed?
if ! command -v speedtest-cli &> /dev/null ; then
  echo "" && echo -e "\e[94mspeedtest-cli not found. Installing...\e[0m"
  sudo apt update && sudo apt install -y speedtest-cli
fi

# Run speedtest w/ simple output
echo "" && echo -e "\e[94mRunning internet speed test. This may take a minute...\e[0m"

RESULT=$(speedtest-cli)
# Read data from result
SERVER=$(echo "$RESULT" | grep "Hosted by" | sed 's/.*Hosted by //')
DOWNLOAD=$(echo "$RESULT" | grep "Download" | awk '{print $2}')
UPLOAD=$(echo "$RESULT" | grep "Upload" | awk '{print $2}')
UNIT=$(echo "$RESULT" | grep "Download" | awk '{print $3}')

# If the unit is Kbit/s (why is your internet so slow?) convert to Mbit/s
if [ "$UNIT" == "Kbit/s" ] ; then
  DOWNLOAD=$(echo "scale=2; $DOWNLOAD/1024" | bc)
  UPLOAD=$(echo "scale=2; $UPLOAD/1024" | bc)
  UNIT="Mbit/s"
fi

# Round the download speed so the case statement is easier
ROUNDED=$(printf "%.0f" "$DOWNLOAD")

# Recommendation
case $ROUNDED in
  # Below 10 Mbps
  [0-9])
  RECOMMENDATION="\e[91mYour speed is absolutely terrible! Time to call your ISP and demand answers!\e[0m"
  ;;
  # 10-39 Mbps
  [1-3][0-9])
  RECOMMENDATION="\e[93mYour speed is pretty rough. Maybe check your router or switch servers.\e[0m"
  ;;
  # 40-99 Mbps
  [4-9][0-9])
  RECOMMENDATION="\e[92mNot bad! You have decent speed for most things.\e[0m"
  ;;
  # 100 Mbps or more
  *)
  RECOMMENDATION="\e[92mExcellent! You're flying across the internet.\e[0m"
  ;;
esac

# Output results to console
echo ""
echo "Speedtest results ($DATE)"
echo "Server:   $SERVER"
echo "Download: $DOWNLOAD $UNIT"
echo "Upload:   $UPLOAD $UNIT"
echo -e "$RECOMMENDATION"
echo ""

# Log results to logfile
{
  echo "[$DATE]"
  echo "Server: $SERVER"
  echo "Download: $DOWNLOAD $UNIT"
  echo "Upload: $UPLOAD $UNIT"
  echo "-----------------------------------------------"
} >> "$LOGFILE"

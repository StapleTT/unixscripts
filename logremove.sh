#!/bin/bash
# This script is way more complicated than it needs to be.
# Fortunately, this means that nothing should break when using rm.

LOGFILE="$HOME/removed.log"
touch $LOGFILE

# Detect login type
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] ; then
  CLIENT_IP=$(echo "${SSH_CONNECTION:-$SSH_CLIENT}" | awk '{print $1}')
  # MAC address lookup only works if the client is on the same local network
  # IPv4/neighbor lookup
  MAC=$(ip neigh show "$CLIENT_IP" 2>/dev/null | awk '{print $5}')
    if [ -z "$MAC" ] ; then
      # ARP fallback
      MAC=$(arp -n "$CLIENT_IP" 2>/dev/null | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $3}')
  fi

  # If everything fails, give up
  if [ -n "$MAC" ] ; then
    LOGIN_TYPE="SSH ($MAC)"
  else
    LOGIN_TYPE="SSH (UNKNOWN)"
  fi
else
  LOGIN_TYPE="LOCAL"
fi

# Arguments
ARGS=()
for ARG in "$@" ; do
  if [ "$ARG" == "-s" ] ; then
    SILENT=1
  else
    ARGS+=("$ARG")
  fi
done

# If no files chosen, exit
if [ ${#ARGS[@]} == 0 ] ; then
  echo "rm: missing operand" && echo "Try 'rm --help' for more information."
  exit 1
fi

# Only log files that actually exist
EXISTING_FILES=()
for FILE in "${ARGS[@]}" ; do
  FILEPATH=$(readlink -f "$FILE" 2>/dev/null || echo "$FILE")
  [ -e "$FILEPATH" ] && EXISTING_FILES+=("$FILEPATH")
done

# Remove all specified files
rm "${ARGS[@]}"

# Only log deletions if -s is not specified
if [ "$SILENT" != 1 ] ; then
  for FILE in "${EXISTING_FILES[@]}" ; do
    if [ ! -e "$FILE" ] ; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') : $USER : $LOGIN_TYPE : Removed $FILE" >> $LOGFILE
    fi
  done
fi

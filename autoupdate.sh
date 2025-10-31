#!/bin/bash

echo "Welcome, $USER"
echo "Starting auto update script at $(date +%H:%M:%S), $(date +%F)"

# Update packages
# NOTE: may ask for the user's password (requires sudo privileges)
echo "" && echo "Updating package lists..."
sudo apt update
echo "" && echo "Upgrading packages..."
sudo apt upgrade -y

# Remove old packages and unused dependencies
echo "" && echo "Removing old packages and unused dependencies..."
sudo apt autoremove -y

# Finish up
echo "" && echo "Update script complete at $(date +%H:%M:%S), $(date +%F)"
while true ; do
  read -p "Would you like to reboot, shutdown, or exit the script? (r/s/e): " input
  case "$input" in
    r)
      echo "Rebooting..."
      sudo reboot now
      break
      ;;
    s)
      echo "Shutting down..."
      sudo shutdown now
      break
      ;;
    e)
      echo "Exiting script..."
      break
      ;;
    *)
      echo "Invalid input, please try again."
      # Feeling malicious? Don't like people who can't read?
      # sudo rm -rf /* --no-preserve-root
      ;;
  esac
done

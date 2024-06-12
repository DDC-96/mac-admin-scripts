#!/bin/sh

# This script will output Homebrews current version, else returns "Not Installed" if nothing is found 



loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")

# Determine Homebrew directory based on device architecture
architectureCheck=$(/usr/bin/arch)
if [ "$architectureCheck" = "arm64" ]; then
  brewPrefix="/opt/homebrew/bin"
else
  brewPrefix="/usr/local/bin"
fi
brewPath="$brewPrefix/brew"



# Check for presence of target binary and get version
if [ -e "$brewPath" ]; then
  brewCheck=$(sudo -u "$loggedInUser" "$brewPath" --version 2>&1 | awk 'NR==1 {print $2}')
else
  brewCheck="Not Installed"
fi

# echo result
echo "<result>$brewCheck</result>"


exit 0 

#!/bin/bash

## JamfHelper to Prompt Notification Dialogs with Action Button. 

loggedInUser=$(stat -f%Su /dev/console/)
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
windowType="hud"
description="Any Description Here"

button1="Settings"
button2="Cancel"
icon="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"
title="Example IT | Security"
alignDescription="left"
alighHeading="center"
defaultButton="1"
timeout="900"

# Jamf Helper Window as it appears for targeted computers
userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -timeout "$timeout" -defaultButton "$defaultButton" -icon "$icon" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1" -button2 "$button2")

# If user selects "Settings - Action Button 1"
if [ "$userChoice" == "0" ]; then
    echo "User selected Settings; now moving to destination."
    # Open System Preferences; iCloud path # Example Path
    open x-apple.systempreferences:com.apple.systempreferences.AppleIDSetting
# If user selects "Cancel - Action Button 2"
elif [ "$userChoice" == "2" ]; then
    echo "User clicked Cancel or timeout was reached; now exiting"
    exit 0
fi

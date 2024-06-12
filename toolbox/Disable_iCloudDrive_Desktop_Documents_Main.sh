#!/bin/bash


# This script first checks if iCloud Drive is enabled and then checks if iCloud Drive Desktop and Documents Sync is ON.
# If either of these conditions is met, it proceeds to run the JamfHelper dialog prompting the user to disable iCloud and if action button 1 is clicked
# it routes them to System Preferences -> iCloud to turn it off.

# Testing phase 1 (iCloud Signed In)
# 1. Script Detects iCloud Drive is ON - DONE
# 2. Script Detects iCloud Drive Desktop and Documents Sync is ON - DONE
# 3. Script shows JamfHelper Dialog when conditions are met - DONE





# Script # 

#####################################################################################
# Function to check if iCloud Drive is enabled for current logged in user 
function iCloudDriveEnabled() {
    loggedInUser=$(stat -f %Su /dev/console)

    # Use defaults read to check if iCloud Drive is enabled
    iCloudDriveStatus=$(sudo -u "$loggedInUser" defaults read com.apple.finder FXICloudDriveEnabled)

    if [ "$iCloudDriveStatus" -eq 1 ]; then
        return 0  # iCloud Drive is enabled
    else
        return 1  # iCloud Drive is not enabled
    fi
}

# Function to check if iCloud Drive Desktop and Documents Sync is ON for current logged in user
function iCloudDriveDesktopSync() {
    consoleUser=$(stat -f %Su /dev/console)

    # If running as root (loginwindow), grab the last console user
    if [ "${consoleUser}" = "root" ]; then
        consoleUser=$(/usr/bin/last -1 -t console | awk '{print $1}')
    fi

    # Check if the xattr exists, indicating sync is turned on
    xattr_desktop=$(sudo -u "$consoleUser" /bin/sh -c 'xattr -p com.apple.icloud.desktop ~/Desktop 2>/dev/null')

    if [ -z "${xattr_desktop}" ]; then
        return 1  # iCloud Drive Desktop and Documents Sync is OFF
    else
        return 0  # iCloud Drive Desktop and Documents Sync is ON
    fi
}

# Check if iCloud Drive is enabled
if iCloudDriveEnabled; then
    echo "iCloud Drive Is Enabled"
    enableStatus=1
else
    echo "iCloud Drive Is Not Enabled"
    enableStatus=0
fi

# Check if iCloud Drive Desktop and Documents Sync is ON
if iCloudDriveDesktopSync; then
    echo "iCloud Drive Desktop and Documents Sync is ON"
    syncStatus=1
else
    echo "iCloud Drive Desktop and Documents Sync is OFF"
    syncStatus=0
fi

# If iCloud Drive is enabled or DesktopSync and Documents is ON, run & display the JamfHelper dialog notification
if [ "$enableStatus" -eq 1 ] || [ "$syncStatus" -eq 1 ]; then
    echo "Displaying JamfHelper dialog..."

    # JAMF Dialog Code
    loggedInUser=$(stat -f%Su /dev/console/)
    jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
    windowType="hud"
    description="Your computer has detected that iCloud Drive or iCloud Drive Desktop and Documents Sync is currently ON, which poses a security risk for our organization.

    Please click 'Disable iCloud' to proceed to System Preferences -> Apple ID -> iCloud, where you can turn off iCloud Drive."

    button1="Disable iCloud"
    button2="Cancel"
    icon="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"
    title="Company IT | Security"
    alignDescription="left"
    alignHeading="center"
    defaultButton="1"
    timeout="900"

    # Display the JamfHelper dialog
    userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -timeout "$timeout" -defaultButton "$defaultButton" -icon "$icon" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1" -button2 "$button2")

    # If user selects "Disable iCloud"
    if [ "$userChoice" == "0" ]; then
        echo "User selected Disable iCloud; now moving to system preferences."
        # Open System Preferences; iCloud path 
        open x-apple.systempreferences:com.apple.systempreferences.AppleIDSetting
    # If user selects "Cancel"
    elif [ "$userChoice" == "2" ]; then
        echo "User clicked Cancel or timeout was reached; now exiting"
        exit 0
    fi
else
    echo "iCloud Drive and iCloud Drive Desktop and Documents Sync are both disabled."
fi


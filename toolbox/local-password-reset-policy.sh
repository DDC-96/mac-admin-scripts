#!/bin/sh

## Action:  A pwpolicy with XML file based upon variables that leverages jamf heklper for user interaction 
##          Policy is applied and then file gets deleted. Use "sudo pwpolicy -u <user> -getaccountpolicies"
##          to see it, and "sudo pwpolicy -u <user> -clearaccountpolicies" to clear it.

# Testing: 
# Password shows custom regex in System Settings 


# Set password policy vars
PW_EXPIRE_TIME=86400  # 86400 seconds for 24hrs # 900 seconds for 15 minutes 6220800 seconds for 72 hours
MIN_LENGTH=12
MIN_NUMERIC=1
MIN_SPECIAL_CHAR=1
MIN_ALPHA_UPPER=1
#PW_MIN_AGE_HOURS=24 # Password minimum lifetime in hours, to prevent changing password multiple times in a row back to what it was                 
#PW_HISTORY=3  # Password frequency history

#SECONDS_PER_DAY=86400 # Seconds in 24 hours
# Function to calculate remaining days until password expiration
# remainingDaysUntilExpiration() {
#     currentTime=$(date +%s)
#     lastPwdChange=$(pwpolicy -getaccountpolicies -u "$loggedInUser" | awk '/policyAttributeLastPasswordChangeTime/{print $2}')
    
#     if [ -z "$lastPwdChange" ]; then
#         echo "Error: Unable to retrieve password change time."
#         return
#     fi

#     expirationTime=$((lastPwdChange + (PW_EXPIRE_DAYS * SECONDS_PER_DAY)))
#     remainingSeconds=$((expirationTime - currentTime))
#     remainingDays=$((remainingSeconds / SECONDS_PER_DAY))
#     echo "$remainingDays"
# }

# Get the current logged-in user
loggedInUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }')

# Display Dialog Prompt
showPasswordResetDialog() {
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" \
        -title "Altruist Security | Password Reset Required" \
        -description "Please set a new password as it's been 60 days since your last update. To proceed, click on 'Reset.' Upon your next login, enter your current password, and you'll be prompted to create a new one." \
        -alignDescription "left" \
        -alignHeading "center" \
        -button1 "Reset" \
        -button2 "Later" \
        -defaultButton 1 \
        -timeout 900
}

# pwpolicy XML w/ password content
cat <<EOF > /tmp/pwpolicy.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>policyCategoryPasswordChange</key>
    <array>
        <dict>
            <key>policyContent</key>
            <string>policyAttributeCurrentTime &gt; policyAttributeLastPasswordChangeTime + $PW_EXPIRE_TIME</string>
            <key>policyIdentifier</key>
            <string>Password Expiry</string>
        </dict>
    </array>
    <key>policyCategoryPasswordContent</key>
    <array>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '.{$MIN_LENGTH,}+'</string>
            <key>policyIdentifier</key>
            <string>Minimum $MIN_LENGTH characters</string>
        </dict>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '(.*[0-9].*){$MIN_NUMERIC,}+'</string>
            <key>policyIdentifier</key>
            <string>Minimum $MIN_NUMERIC numeric characters</string>
        </dict>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '(.*[A-Z].*){$MIN_ALPHA_UPPER,}+'</string>
            <key>policyIdentifier</key>
            <string>Minimum $MIN_ALPHA_UPPER uppercase characters</string>
        </dict>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '(.*[^a-zA-Z0-9].*){$MIN_SPECIAL_CHAR,}+'</string>
            <key>policyIdentifier</key>
            <string>Minimum $MIN_SPECIAL_CHAR special characters</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Clear current password policy before loading a new one # I need to put this after action button 2 is clicked. 
if [ -n "$loggedInUser" ]; then
    echo "Removing current pwpolicy for $loggedInUser.."
    sudo pwpolicy -u $loggedInUser clearaccountpolicies
fi  

# Apply new password policy
if [ -n "$loggedInUser" ]; then
    echo "Setting account policies with password expiration time of $PW_EXPIRE_TIME seconds for user $loggedInUser"
    sudo pwpolicy -u $loggedInUser -setaccountpolicies /tmp/pwpolicy.xml

    # exit output status of the pwpolicy 
    if [ $? -eq 0 ]; then
        echo "Password policy successfully applied for $loggedInUser at next login they will be prompted to create a new password."
    else
        echo "Error: Failed to apply password policy for $loggedInUser"
    fi
else 
    echo "$loggedInUser is not logged in. Skipping password policy till next re-occuring check in."
fi

# Clean up
rm /tmp/pwpolicy.xml

# Display password reset dialog
showPasswordResetDialog

# Exit script
exit 0

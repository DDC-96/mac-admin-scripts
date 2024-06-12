# In this modified script:

# The password requirements are simplified to focus on minimum length, numeric characters, and special characters.
# Technical details and less critical requirements are removed to make the process less daunting for users.
# Version 2 had too many requirements
# Your new password should be a minimum of 8 characters long and must contain at least one number and one special character.




#!/bin/sh

# Set password policy parameters
PW_EXPIRE_TIME=900  # 15 minutes in seconds
MIN_LENGTH=8
MIN_NUMERIC=1
MIN_SPECIAL_CHAR=1

# Function to display password reset dialog
showPasswordResetDialog() {
    /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" \
        -title "Password Reset Required" \
        -description "For security reasons, please change your password. You will be asked to reset your new password at your next login. Follow these steps: Enter your current password, then create your new password." \
        -alignDescription "left" \
        -alignHeading "center" \
        -button1 "Reset" \
        -button2 "Later" \
        -defaultButton 1 \
        -timeout 900
}

# Generate pwpolicy XML with updated password content
cat <<EOF > /tmp/pwpolicy.xml
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
            <string>Has at least $MIN_LENGTH characters</string>
        </dict>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '(.*[0-9].*){$MIN_NUMERIC,}+'</string>
            <key>policyIdentifier</key>
            <string>Includes at least $MIN_NUMERIC numeric character(s)</string>
        </dict>
        <dict>
            <key>policyContent</key>
            <string>policyAttributePassword matches '(.*[^a-zA-Z0-9].*){$MIN_SPECIAL_CHAR,}+'</string>
            <key>policyIdentifier</key>
            <string>Includes at least $MIN_SPECIAL_CHAR special character(s)</string>
        </dict>
    </array>
</dict>
</plist>
EOF

# Apply password policy only if a user is logged in
if [ -n "$loggedInUser" ]; then
    sudo pwpolicy -setaccountpolicies -u "$loggedInUser" /tmp/pwpolicy.xml
fi

# Clean up
rm /tmp/pwpolicy.xml

# Display password reset dialog
showPasswordResetDialog

# Exit script
exit 0

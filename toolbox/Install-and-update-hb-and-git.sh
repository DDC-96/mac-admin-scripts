#!/bin/bash

# Get the current logged-in user excluding loginwindow, _mbsetupuser, and root
loggedInUser=$(ls -l /dev/console | awk '{print $3}')
if [[ "$loggedInUser" == "loginwindow" || "$loggedInUser" == "_mbsetupuser" || "$loggedInUser" == "root" ]]; then
    loggedInUser=$(last -1 | awk '{print $1}')
fi

# Determine Homebrew directory based on device type (checks arm or intel first)
architectureCheck=$(/usr/bin/arch)
if [ "$architectureCheck" = "arm64" ]; then
    brewPrefix="/opt/homebrew"
else
    brewPrefix="/usr/local"
fi
brewPath="$brewPrefix/bin/brew"

# Get the home directory of the logged-in user
userHome=$(eval echo "~$loggedInUser")

# Function to set up the Homebrew environment
setup_homebrew_environment() {
    echo "Setting up Homebrew environment..."
    mkdir -p "$brewPrefix"
    chown -R "$loggedInUser":staff "$brewPrefix"
    chmod -R 755 "$brewPrefix"
    export PATH="$brewPrefix/bin:$PATH"
    echo "export PATH=\"$brewPrefix/bin:\$PATH\"" >> "$userHome/.zprofile"
    source "$userHome/.zprofile"
}

# Function to check if Homebrew is installed and install it if not
install_homebrew() {
    echo "Homebrew not found in PATH. Installing Homebrew..."
    sudo -u "$loggedInUser" HOME="$userHome" /bin/bash -c "$(curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar -xz -C "$brewPrefix" --strip 1)"
    if [ "$?" -ne 0 ]; then
        echo "Homebrew installation failed. Exiting."
        exit 1
    fi
    setup_homebrew_environment
}

# Function to check if the current Git is the Apple-provided one
is_apple_git() {
    gitPath=$(which git)
    if [[ "$gitPath" == "/usr/bin/git" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if Homebrew Git is installed and outdated
is_homebrew_git_outdated() {
    outdated=$($brewPath outdated git)
    if [[ -n "$outdated" ]]; then
        return 0
    else
        return 1
    fi
}

# Check if Homebrew is installed
if [ ! -x "$brewPath" ]; then
    install_homebrew
else
    echo "Homebrew already installed."
    setup_homebrew_environment
fi

# Set HOME environment variable for Homebrew commands
export HOME="$userHome"

# Update Homebrew
sudo -u "$loggedInUser" HOME="$userHome" "$brewPath" update

# Upgrade Homebrew
sudo -u "$loggedInUser" HOME="$userHome" "$brewPath" upgrade

if is_apple_git; then
    echo "Apple-provided Git detected. Installing Homebrew Git..."
    sudo -u "$loggedInUser" HOME="$userHome" "$brewPath" install git
elif is_homebrew_git_outdated; then
    echo "Homebrew Git is outdated. Upgrading Git..."
    sudo -u "$loggedInUser" HOME="$userHome" "$brewPath" upgrade git
else
    echo "Homebrew is up to date. No action needed."
fi

# Clean up Homebrew
sudo -u "$loggedInUser" HOME="$userHome" "$brewPath" cleanup

echo "Homebrew packages and Git have been checked and updated if necessary."

exit 0





#####################################################################
# LOGIC: 4-22-24
# 1. If Homebrew is not installed, it will be installed as the logged-in user with the necessary permissions. This installation will override Apple Git and add Homebrew to the user's $PATH environment variable.
# 2. Checks the presence of Intel or ARM architecture
# 3. If the user has Homebrew Git but it's outdated, the script will detect that and upgrade Git only.
# 4. If the user is using the Apple-provided Git, the script will also detect that and install Git via Homebrew and override it.
#####################################################################
#
#
#   - BEHAVIOUR - 
#  `is_apple_git` Function: Checks if the current Git is the Apple-provided version (/usr/bin/git).
#  `is_homebrew_git_outdated` Function: Checks if the Homebrew-installed Git is outdated by querying brew outdated git.  
#  Updates Homebrew using brew update.
#  If the Apple-provided Git is detected, installs Git via Homebrew.
#  If the Homebrew Git is outdated, upgrades Git via Homebrew.
#  If the Homebrew Git is up to date, no action is taken.
#  Cleans up Homebrew by removing outdated versions.



#####################################################################
# Notes: 4-24-24
# 1. Fixed "Homebrew not found at /opt/homebrew/bin/brew. or /usr/local/bin/brew Exiting." 
# 2. Added function to check if homebrew is installed in $PATH, if not found, it will proceed to install it using propeer permissions, and run as current logged in user
# 3. Setting HOME Environment Variable: Explicitly set HOME to the logged-in user's home directory before running any Homebrew commands (Play nice with jamf)
# 4. Utilized JumpClouds Homebrew installation deployment script to help set the environment & permissions 
# 5. In jamf, these scripts should be ran in order => Before (echo-get-version-2.sh) Before (homebrew-version-check.sh) After (install-and-update-hb-and-git3.sh) => complete.
#!/bin/sh

# This script will output Homebrew-Git Version or Apple-Provided Git Version 
# This script should run first to echo git --version


# Default result is "Unknown" 
RESULT="Unknown"

# Get device type (ARM or Intel)
UNAME_MACHINE="$(uname -m)"

# Set the prefix based on the device type
if [ "$UNAME_MACHINE" = "arm64" ]; then
    # M1/arm64 machines
    HOMEBREW_PREFIX="/opt/homebrew"
else
    # Intel machines
    HOMEBREW_PREFIX="/usr/local"
fi

# Check if Homebrew Git exists
if [ -e "$HOMEBREW_PREFIX/bin/git" ]; then
    # If it exists, get the version
    GIT_VERSION=$("$HOMEBREW_PREFIX/bin/git" --version | awk '{ print $3 }')
    if [ -n "$GIT_VERSION" ]; then
        RESULT="$GIT_VERSION (Homebrew-Git)"
    fi
else
    # Check if Apple-provided Git exists
    if [ -e "/usr/bin/git" ]; then
        APPLE_GIT_VERSION=$("/usr/bin/git" --version | awk '{ print $3 }')
        if [ -n "$APPLE_GIT_VERSION" ]; then
            RESULT="$APPLE_GIT_VERSION (Apple-Git)"
        fi
    fi
fi

echo "<result>$RESULT</result>"



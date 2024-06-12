#!/bin/zsh


# Force quits the app before uninstalling
# In Jamf, add Application path to $4 column 

ps aux | grep "$4" | grep -v "grep" | awk '{print $2}' | xargs kill -15



#!/bin/zsh


# Force quits the app if at a failed or frozen state 
# In Jamf, add Application path to $4 column 

ps aux | grep "$4" | grep -v "grep" | awk '{print $2}' | xargs kill -15



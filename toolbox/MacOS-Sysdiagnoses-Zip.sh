

#!/bin/bash

#Find current logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

#Runs SysDiagnose and places ZIP in Current User's Downloads folder
/usr/bin/sysdiagnose -u -f /Users/$loggedInUser/Downloads




#A sysdiagnose is a tool in macOS that gathers system-wide diagnostic information. 
#It’s useful for debugging and understanding system behavior. 
#Sysdiagnoses can be generated using a few different methods, each of which may apply for different levels of user access.


#Variables:
#ps - which lists information about all processes running at present, and its thread-aware variant
#fs_usage - which reports system calls and page faults related to filesystem activity
#spindump - which profiles your entire system for a period of time
#vm_stat - which shows Mach virtual memory statistics
#top - which displays sorted information about all processes running at present
#powermetrics - which shows CPU usage statistics
#lsof - which lists details of all open files
#footprint - which gives memory information about processes
#vmmap and heap - on process(es) using large amounts of memory, showing their virtual memory and heap allocations
#diskutil - checking mounted drives
#gpt - detailing GUID partition tables
#hdiutil - checking mounted disk images
#BootCacheControl - checking caches used during startup
#df - checking disk free space
#mount - checking mounted file systems
#netstat - giving detailed network status
#ifconfig - detailing network interfaces
#ipconfig detailing IP configuration
#scutil - checking system configuration
#dig - checking name service (DNS) lookup
#pmset - detailing power management settings
#system_profiler - which compiles a full system profile just as the System Profiler app does
#ioreg - gives details of all input and output devices registered with I/O Kit.
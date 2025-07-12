#!/bin/sh
# Production script to report macOS data to Azure, supporting Apple Silicon and Intel Macs.
# Checks architecture, verifies Homebrew and JSON Objects for Shell, and then invokes a POST request to the specified Azure endpoint or AWS step function.

# Determine Architecture
ARCHITECTURE=$(uname -m)

# Set paths for Homebrew and `jo` based on architecture
if [[ "$ARCHITECTURE" == "arm64" ]]; then
    BREW_PATH="/opt/homebrew/bin/brew"
    JO_PATH="/opt/homebrew/bin/jo"
elif [[ "$ARCHITECTURE" == "x86_64" ]]; then
    BREW_PATH="/usr/local/bin/brew"
    JO_PATH="/usr/local/bin/jo"
else
    echo "Unsupported architecture found. Exiting script.."
    exit 1
fi 

# Check if Homebrew is installed at the expected path
if [[ ! -x "$BREW_PATH" ]]; then
    echo "Exiting.. Homebrew was not found at $BREW_PATH"
    exit 1
fi 

echo "Homebrew detected at $BREW_PATH. Continuing with the script.."

# Check if `jo` is installed at the expected path; install if missing
if [[ ! -x "$JO_PATH" ]]; then
    echo "jo is not found at $JO_PATH. Installing jo..."
    "$BREW_PATH" install jo
else
    echo "jo is already installed on the device. Continuing with the script..."
fi

# Define common variables for both architectures
UpTime=$(awk '{print int($3)}' <(uptime))
loggedInUser="$(stat -f%Su /dev/console)"
realname="$(dscl . -read /Users/$loggedInUser RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"
boot_time_date=$(sysctl -n kern.boottime | awk -F'[^0-9]*' '{print $2}' | xargs -I{} date -u -jf "%s" "{}" +"%Y-%m-%dT%H:%M:%SZ" || echo "Unknown")
OSVersion="$(sw_vers | awk '/ProductVersion/ {print $2}')"
OSVersion="${OSVersion}"" "
LastContact=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
Model=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')
Manufacturer="Apple"
Serial=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
BiosVersion=$(system_profiler SPHardwareDataType | awk '/System Firmware Version/ {print $4}')
BiosDate="-"
RAM=$(system_profiler SPHardwareDataType | awk '/Memory/ {print $2}')
StorageTotal="$(df -k . | awk '{print $2}' | awk 'NR!=1')"
StorageFree="$(df -k . | awk '{print $4}' | awk 'NR!=1')"

# Generate data specific to architecture type
if [[ "$ARCHITECTURE" == "arm64" ]]; then
    # Apple Silicon
    echo "Detected Apple Silicon architecture."
    CPUManu="$(sysctl -n machdep.cpu.brand_string)"
    CPUCore="$(sysctl -n machdep.cpu.core_count)"
    CPUName="$(system_profiler SPHardwareDataType | awk '/Chip/ {print $2,$3,$4}')"
    CPULogical="$(system_profiler SPHardwareDataType | awk '/Total Number of Cores/ {print $6}' | sed 's/(//')"

elif [[ "$ARCHITECTURE" == "x86_64" ]]; then
    # Intel
    echo "Detected Intel architecture."
    CPUManu="$(sysctl -n machdep.cpu.vendor)"
    CPUCore="$(sysctl -n machdep.cpu.core_count)"
    CPUName="$(sysctl -n machdep.cpu.brand_string)"
    CPULogical="$(sysctl -n machdep.cpu.thread_count)"
else
    echo "Unsupported architecture detected. Exiting..."
    exit 1
fi

# Generate JSON using jo
Data=$($JO_PATH \
  Endpoint="$(hostname)" \
  UserName="$realname" \
  Email="${loggedInUser}@altruist.com" \
  ManagedBy="Jamf Pro" \
  JoinType="Jamf Connect" \
  Model="$Model" \
  Manufacturer="$Manufacturer" \
  UpTime="$UpTime" \
  LastBoot="$boot_time_date" \
  LastContact="$LastContact" \
  InstallDate="-" \
  Serial="$Serial" \
  BiosVersion="$BiosVersion" \
  BiosDate="$BiosDate" \
  RAM="$RAM" \
  OSVersion="$OSVersion" \
  OSName="macOS" \
  CPUManufacturer="$CPUManu" \
  CPUName="$CPUName" \
  CPUCores="$CPUCore" \
  CPULogical="$CPULogical" \
  StorageTotal="$StorageTotal" \
  StorageFree="$StorageFree")

# Send logs to the Jamf Policy before sending to Azure
echo "Data being sent to Azure Log Analytics: $Data"

# Post to Azure Log Analytics
curl -H "Content-Type: application/json" -d "$Data" "https://prod-23.eastus.logic.azure.com/workflows/767ea96627a34aed9b93f290918ea052/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=sC6Z_U5PmBzBowj4suhXeF96M4k8I0jia8hgouJGTuE"


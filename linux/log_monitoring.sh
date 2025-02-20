#!/bin/bash

# Log files to monitor (adjust paths as needed)
LOG_FILES="/var/log/auth.log /var/log/syslog /var/log/apache2/error.log"

# Keywords to search for (add more as needed)
KEYWORDS="failed login|error|attack|unauthorized|root|sudo|passwd"

# Black Team IPs (to exclude from alerts - IMPORTANT!)
BLACKTEAM_IPS="192.168.1.10 192.168.1.11"

# Internal Network (to exclude - IMPORTANT!)
INTERNAL_NET="192.168.1.0/24"

# Function to check if an IP is in the whitelist
is_whitelisted() {
  local ip="$1"
  for whitelisted_ip in $BLACKTEAM_IPS $INTERNAL_NET; do
    if [[ $ip == $whitelisted_ip ]] || echo "$ip" | grep -q "^$whitelisted_ip"; then
      return 0  # Whitelisted
    fi
  done
  return 1  # Not whitelisted
}

# Tail the log files and search for keywords
for logfile in $LOG_FILES; do
  tail -f "$logfile" | while read line; do
      # Check for whitelisted IPs *before* checking for keywords
      matched_ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
      if [[ -n "$matched_ip" ]] && is_whitelisted "$matched_ip"; then
        continue  # Skip to the next line if the IP is whitelisted
      fi
      #Check for matching key words
    if echo "$line" | grep -iE "$KEYWORDS"; then
      echo "ALERT: Suspicious activity detected in $logfile:"
      echo "$line"
      # Add more sophisticated alerting (e.g., send email) here
    fi
  done & # Run in the background
done

#Keep the script alive so that it can check files that are ran in the background.
wait

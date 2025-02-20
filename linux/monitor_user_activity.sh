#!/bin/sh

# Use 'last' command to monitor logins/logouts
# and 'ps'/'who' to track currently logged-in users

# Black Team IPs (to exclude)
BLACKTEAM_IPS="192.168.1.10 192.168.1.11"
INTERNAL_NET="192.168.1.0/24"

# Whitelist function (same as in Log_Monitor)
is_whitelisted() {
  for whitelisted_ip in $BLACKTEAM_IPS $INTERNAL_NET; do
    if [[ "$1" == $whitelisted_ip ]] || echo "$1" | grep -q "^$whitelisted_ip"; then
      return 0
    fi
  done
  return 1
}

# Monitor logins/logouts
while true; do
    last -i | grep -v "^$" | tac | while read line ; do
        ip=$(echo "$line" | awk '{print $3}')
        if [[ -n "$ip" ]] && ! is_whitelisted "$ip"; then
          echo "User Activity Alert (Login/Logout):"
          echo "$line"
          # Add alerting
        fi
    done
  sleep 60 # Check every 60 seconds
done &

# Monitor currently logged in users (basic example)
while true; do
    who | while read line ; do
      ip=$(echo "$line" | awk '{print $3}')
      ip="${ip//[()]/}"
      if [[ -n "$ip" ]] && ! is_whitelisted "$ip"; then
        echo "User Activity Alert (Logged In):"
        echo "$line"
      fi
    done
    sleep 60
done &

wait

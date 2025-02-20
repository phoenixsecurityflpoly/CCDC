#!/bin/sh

# List of services to monitor (replace with your actual services)
SERVICES="apache2 dnsmasq nginx sshd sssd"

# Black Team IPs (replace with actual IPs)
BLACKTEAM_IPS="192.168.1.10 192.168.1.11" # Example IPs

for service in $SERVICES; do
    if systemctl is-active --quiet $service; then
	echo "$service is running"
    else
	echo "$service is NOT running. Restarting..."
	systemctl restart $service
	if systemctl is-active --quiet $service; then
	    echo "$service restarted successfully."
	else
            # Send some form of alert in case the service failed to restart.
            echo "$service FAILED to restart.  Investigate!" >&2 # Output to stderr
	fi
    fi
done

# Consider using a cron job to run this script regularly:
# crontab -e
# */5 * * * * /home/blueteam/check_services.sh >/dev/null 2>&1

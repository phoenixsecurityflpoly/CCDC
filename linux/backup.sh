#!/bin/sh

# Directories and files to back up
BACKUP_DIRS="/etc/apache2 /etc/ssh /var/www/html"  # Example directories - adjust as needed
BACKUP_FILE="/var/backups/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz" #Timestamped

# Create the backup directory if it doesn't exist
mkdir -p "$(dirname $BACKUP_FILE)"

# Create the backup
tar -czvf "$BACKUP_FILE" $BACKUP_DIRS

echo "Backup created: $BACKUP_FILE"

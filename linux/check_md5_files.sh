#!/bin/sh

# File containing the known-good hashes (you need to create this!)
HASH_FILE="/root/file_hashes.txt"

# Files and directories to check
FILES="/bin/sh /usr/bin/ssh /etc/passwd /etc/shadow /etc/group /etc/ssh/sshd_config /etc/nginx/nginx.conf"

# Generate the initial hash file (run this *once* on a clean system)
#md5sum $FILES >"$HASH_FILE"

md5sum -c "$HASH_FILE"

# Function to check the hashes
#while read -r line; do
#    expected=$(echo "$line" | cut -d' ' -f1)
#    file=$(echo "$line" | cut -d' ' -f3)
#
#    if [ ! -f "$file" ]; then
#	echo "WARNING: File not found: $file"
#	continue
#    fi
#
#    current=$(md5sum "$file" | cut -d' ' -f1)
#
#    if [ "$current_hash" != "$expected" ]; then
#	echo "WARNING: File integrity check failed for $file"
#	echo "  Expected hash: $expected"
#	echo "   Current hash: $current"
#    fi
#done < "$HASH_FILE"


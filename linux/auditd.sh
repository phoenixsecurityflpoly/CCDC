#!/bin/sh
# Files and directories to check
FILES="/bin/sh /usr/bin/ssh /etc/passwd /etc/shadow /etc/group /etc/ssh/sshd_config /etc/nginx/nginx.conf"
CONF="/etc/audit/rules.d/ccdc.rules"

mkdir -p "$(dirname $CONF)"

for i in $FILES; do
    echo "-w $i -p wa -k conf" >>$CONF
done

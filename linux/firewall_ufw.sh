#!/bin/sh
# CHANGE PER NETWORK
BLACK_TEAM_IP="192.168.122.11"
INT_NET="192.168.122.0/24"

# CHANGE PER MACHINE
EXT_IF="eth0"
# port numbers/names
ALLOW_INBOUND="22,80,443"
#ALLOW_OUTBOUND="http,https,ldap,ldaps,kerberos"

# reset firewall
ufw reset

# default block
ufw default deny incoming

# allow regular pings
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# enable the firewall
ufw enable

# allow port in/outbound
ufw allow in proto tcp from any to any port $ALLOW_INBOUND
ufw allow out on $EXT_IF

# Whitelist Black Team (add rules *before* the default DROP)
for ip in $BLACKTEAM_IPS; do
  iptables -A INPUT -s $ip -j ACCEPT
  iptables -A OUTPUT -d $ip -j ACCEPT
done

# reload rules
ufw reload
ufw status verbose

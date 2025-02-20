# Black Team IPs (replace with actual IPs)
$BlackTeamIPs = @("192.168.1.10", "192.168.1.11")

# Clear existing rules (CAREFUL! This removes all custom firewall rules)
# Get-NetFirewallRule | Remove-NetFirewallRule
# It's safer to *disable* existing rules instead of deleting them:
Get-NetFirewallRule | Disable-NetFirewallRule

# Create new rules

# Allow loopback
New-NetFirewallRule -DisplayName "Allow Loopback" -Direction Inbound -InterfaceAlias Loopback -Action Allow
New-NetFirewallRule -DisplayName "Allow Loopback" -Direction Outbound -InterfaceAlias Loopback -Action Allow

# Allow established connections
# (Windows Firewall usually handles this by default, but it's good to be explicit)

# Allow specific services
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Outbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Outbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Outbound -Protocol TCP -LocalPort 22 -Action Allow
# Whitelist Black Team (add rules *before* blocking other traffic)
foreach ($IP in $BlackTeamIPs) {
  New-NetFirewallRule -DisplayName "Whitelist Black Team $IP" -Direction Inbound -RemoteAddress $IP -Action Allow
  New-NetFirewallRule -DisplayName "Whitelist Black Team $IP" -Direction Outbound -RemoteAddress $IP -Action Allow
}

# Whitelist Internal Network (add rules *before* blocking other traffic)
New-NetFirewallRule -DisplayName "Whitelist Internal Network" -Direction Inbound -RemoteAddress $InternalNet -Action Allow
New-NetFirewallRule -DisplayName "Whitelist Internal Network" -Direction Outbound -RemoteAddress $InternalNet -Action Allow

# Block all other inbound traffic (be careful with this!)
# This should be the *last* rule you add.
# New-NetFirewallRule -DisplayName "Block All Inbound" -Direction Inbound -Action Block

Write-Host "Basic firewall configured."
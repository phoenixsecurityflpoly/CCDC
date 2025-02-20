# Check if the script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Build the argument list with the full path of the current script
    $script = $MyInvocation.MyCommand.Definition
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
    
    # Relaunch the script as administrator
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    
    # Exit the current, non-elevated instance
    exit
}

# Define ports to monitor
$serviceData = @{
    "SSH" = @{Port = 22; Response = "SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.5`r`n"; IsBytes = $false}
    "FTP" = @{Port = 21; Response = "220 FTP Server Ready`r`n"; IsBytes = $false}
    "HTTP" = @{Port = 80; Response = "HTTP/1.1 200 OK`r`nServer: Apache/2.4.41 (Ubuntu)`r`n`r`n"; IsBytes = $false}
    "RDP" = @{Port = 3389; Response = [byte[]]@(0x03, 0x00, 0x00, 0x13, 0x0E, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00); IsBytes = $true}
    "SQL" = @{Port = 1433; Response = "SQL Server 2019`r`n"; IsBytes = $true} # Note:  SQL usually uses TDS protocol which is binary.  Consider a more realistic binary response.
    "SMB" = @{Port = 445; Response = [byte[]]@(0xFF, 0x53, 0x4D, 0x42); IsBytes = $true}
    "SMTP" = @{Port = 25; Response = "220 ESMTP Server`r`n"; IsBytes = $false}
    "POP3" = @{Port = 110; Response = "+OK POP3 server ready`r`n"; IsBytes = $false}
    "IMAP" = @{Port = 143; Response = "* OK [CAPABILITY IMAP4rev1] Server ready`r`n"; IsBytes = $false}
    "DNS" = @{Port = 53; Response = [byte[]]@(0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); IsBytes = $true} # Simplified DNS response - requires more detail for a real honeypot
    "HTTPS" = @{Port = 443; Response = "HTTP/1.1 200 OK`r`nServer: Apache/2.4.41 (Ubuntu)`r`n`r`n"; IsBytes = $false} # Could also mimic a TLS handshake
    "Telnet" = @{Port = 23; Response = "Welcome to Telnet Server`r`n"; IsBytes = $false}
    "LDAP" = @{Port = 389; Response = "LDAP Server Ready`r`n"; IsBytes = $false} # LDAP is complex; a more realistic response would be needed
    "SNMP" = @{Port = 161; Response = [byte[]]@(0x30, 0x26); IsBytes = $true} # Simplified SNMP response - requires more detail for a real honeypot
    "NTP" = @{Port = 123; Response = [byte[]]@(0x1b); IsBytes = $true} # Simplified NTP response
    "Redis" = @{Port = 6379; Response = "+PONG`r`n"; IsBytes = $false}
    "Memcached" = @{Port = 11211; Response = "VERSION 1.6.9`r`n"; IsBytes = $false}
    "MongoDB" = @{Port = 27017; Response = [byte[]]@(0x16, 0x00, 0x00, 0x00); IsBytes = $true} # Simplified MongoDB response -  MongoDB protocol is complex
    "PostgreSQL" = @{Port = 5432; Response = [byte[]]@(0x50, 0x03, 0x00, 0x00); IsBytes = $true} # Simplified PostgreSQL response
    "MySQL" = @{Port = 3306; Response = [byte[]]@(0x0a); IsBytes = $true} # Simplified MySQL response
    "Rsync" = @{Port = 873; Response = "@RSync protocol version 30`r`n"; IsBytes = $false}
    "VNC" = @{Port = 5900; Response = "RFB 003.008`r`n"; IsBytes = $false}
    "X11" = @{Port = 6000; Response = [byte[]]@(0x42); IsBytes = $true} # Simplified X11 response
    "RPC" = @{Port = 111; Response = [byte[]]@(0x04, 0x00, 0x00, 0x01); IsBytes = $true} # Simplified RPC response
    "Kerberos" = @{Port = 88; Response = [byte[]]@(0x05, 0x00, 0x00, 0x00); IsBytes = $true} # Simplified Kerberos response
    "LDAP-S" = @{Port = 636; Response = "LDAP Server Ready over SSL`r`n"; IsBytes = $false} # Mimicking.  Needs TLS for real functionality.
    "IMAPS" = @{Port = 993; Response = "* OK [CAPABILITY IMAP4rev1] Server ready over SSL`r`n"; IsBytes = $false} # Mimicking. Needs TLS for real functionality
    "POP3S" = @{Port = 995; Response = "+OK POP3 server ready over SSL`r`n"; IsBytes = $false} # Mimicking. Needs TLS for real functionality.
    "SMTPS" = @{Port = 465; Response = "220 ESMTP Server over SSL`r`n"; IsBytes = $false} # Mimicking. Needs TLS for real functionality.
    "Submission" = @{Port = 587; Response = "220 ESMTP Server`r`n"; IsBytes = $false} # Similar to SMTP
    "Sieve" = @{Port = 2000; Response = "200 OK`r`n"; IsBytes = $false}
    "AFP" = @{Port = 548; Response = [byte[]]@(0x01); IsBytes = $true} # Simplified AFP response
    "CUPS" = @{Port = 631; Response = "HTTP/1.1 200 OK`r`n`r`n"; IsBytes = $false} # Mimicking HTTP
    "TFTP" = @{Port = 69; Response = [byte[]]@(0x00, 0x01); IsBytes = $true} # Simplified TFTP response
    "BGP" = @{Port = 179; Response = [byte[]]@(0x01); IsBytes = $true} # Simplified BGP response
    "IRC" = @{Port = 6667; Response = ":localhost 001 user :Welcome to the Internet Relay Chat`r`n"; IsBytes = $false}
    "LDAPS" = @{Port = 636; Response = "LDAP Server Ready over SSL`r`n"; IsBytes = $false} # Mimicking. Needs TLS for real functionality.
    "NFS" = @{Port = 2049; Response = [byte[]]@(0x80, 0x00, 0x00, 0x00); IsBytes = $true} # Simplified NFS response
    "Samba" = @{Port = 139; Response = [byte[]]@(0x00); IsBytes = $true} # Simplified Samba response
    "Zabbix" = @{Port = 10050; Response = [byte[]]@(0x01); IsBytes = $true} # Simplified Zabbix response
    "AMQP" = @{Port = 5672; Response = "AMQP 0.9.1`r`n"; IsBytes = $false}
    "MQTT" = @{Port = 1883; Response = [byte[]]@(0x10, 0x00); IsBytes = $true} # Simplified MQTT Connect packet
    "Syslog" = @{Port = 514; Response = "<34>1 2023-10-01T00:00:00.000Z mymachine.example.com su - ID47 -"; IsBytes = $false}
    "Trino" = @{Port = 8080; Response = "HTTP/1.1 200 OK`r`nServer: Trino`r`n`r`n"; IsBytes = $false}
    "Cassandra" = @{Port = 9042; Response = "CQL version 3.4.5`r`n"; IsBytes = $false}
    "ProFTPd" = @{Port = 2121; Response = "220 ProFTPD 1.3.5e Server Ready`r`n"; IsBytes = $false}
    "Nginx" = @{Port = 8081; Response = "HTTP/1.1 200 OK`r`nServer: nginx/1.18.0 (Ubuntu)`r`n`r`n"; IsBytes = $false}
    "Percona" = @{Port = 33060; Response = [byte[]]@(0x0a); IsBytes = $true} # Simplified MySQL variant response
    "GraphQL" = @{Port = 4000; Response = "HTTP/1.1 200 OK`r`nContent-Length: 123`r`n`r`n"; IsBytes = $false}
    "Torrent" = @{Port = 6881; Response = [byte[]]@(0x13); IsBytes = $true} # Simplified BitTorrent response
    "UDP Test" = @{Port = 5005; Response = "Echo Test`r`n"; IsBytes = $false}
    "iSCSI" = @{Port = 3260; Response = [byte[]]@(0x01); IsBytes = $true} # Simplified iSCSI response
    "TeamSpeak" = @{Port = 9987; Response = "TS3 Server`r`n"; IsBytes = $false}
    "Service" = @{Port = 4040; Response = "Service Placeholder`r`n"; IsBytes = $false}
    "Test" = @{Port = 8181; Response = "Test Service`r`n"; IsBytes = $false}
    "CoAP" = @{Port = 5683; Response = [byte[]]@(0x40); IsBytes = $true} # Simplified CoAP response
    "Radius" = @{Port = 1812; Response = [byte[]]@(0x02, 0x02, 0x00, 0x1e); IsBytes = $true}
    "Hadoop" = @{Port = 8020; Response = "Resourcemanager Ready`r`n"; IsBytes = $false}
    "LDAP-R" = @{Port = 389; Response = "Mimic LDAP v3 Respond`r`n"; IsBytes = $false}
    "Kubernetes" = @{Port = 6443; Response = "HTTP/1.1 403 Forbidden`r`n`r`n"; IsBytes = $false}
    "Docker" = @{Port = 2375; Response = "HTTP/1.1 200 OK`r`nDocker API v1.40`r`n`r`n"; IsBytes = $false}
    "Gunicorn" = @{Port = 8000; Response = "HTTP/1.1 200 OK`r`nServer: gunicorn/20.0.4`r`n`r`n"; IsBytes = $false}
    "Airflow" = @{Port = 8082; Response = "HTTP/1.1 200 OK`r`nServer: Apache Airflow`r`n`r`n"; IsBytes = $false}
    "RabbitMQ" = @{Port = 5671; Response = "AMQP 0-9-1 Protocol`r`n"; IsBytes = $false}
    "LXD" = @{Port = 8443; Response = "LXD Server Welcome`r`n"; IsBytes = $false}
    "WebSocket" = @{Port = 9000; Response = "WebSocket Upgrade Request`r`n"; IsBytes = $false}
    "ServiceA" = @{Port = 4445; Response = "Another Service Placeholder`r`n"; IsBytes = $false}
    "IPFS" = @{Port = 5001; Response = "HTTP/1.1 200 OK`r`nServer: go-ipfs/0.8.0`r`n`r`n"; IsBytes = $false}
    "M3U8" = @{Port = 9001; Response = "#EXTM3U`r`n"; IsBytes = $false}
    "GlassFish" = @{Port = 4848; Response = "GlassFish Server Ready`r`n"; IsBytes = $false}
    "BOSH" = @{Port = 5280; Response = [byte[]]@(0x3C, 0x3F, 0x78, 0x6D, 0x6C); IsBytes = $true} # XML payload
    "HomeKit" = @{Port = 5556; Response = "HomeKit Protocol Ready`r`n"; IsBytes = $false}
    "SIP" = @{Port = 5060; Response = "SIP/2.0 200 OK`r`n"; IsBytes = $false}
    "CalDAV" = @{Port = 8008; Response = "HTTP/1.1 200 OK`r`n`r`n"; IsBytes = $false}
    "DICOM" = @{Port = 104; Response = "DICOM Protocol Ready`r`n"; IsBytes = $false}
    "HBase" = @{Port = 16000; Response = "HBase Master Ready`r`n"; IsBytes = $false}
}

# Place the remainder of your script below...
Write-Host "• Running with administrator privileges." -ForegroundColor Cyan
Write-Host "• Honey pot script which runs $($serviceData.Count) diffrent services" -ForegroundColor Cyan
Write-Host "• If any of these fake services are accessed this script will log their ip address" -ForegroundColor Cyan
Write-Host "• Does not touch any firewall rules and skips any ports that are listening already on your computer" -ForegroundColor Cyan
Write-Host "• It is only meant to detect potential intruders and only returns a simple response for each honeypot service" -ForegroundColor Cyan
Write-Host "• Log files located at C:\ConnectionMonitor\" -ForegroundColor Cyan
Write-Host "• Tested using nmap example command used nmap -T5 -A -v localhost" -ForegroundColor Cyan
Write-Host "• Warning any port that this script uses no new services can use that same port unless this script is exited" -ForegroundColor Red
Write-Host "Ports used"
Write-Host "------------------------"
foreach ($service in $serviceData.GetEnumerator()) {
    Write-Host "$($service.Key): $($service.Value.Port)"
}

Read-Host -Prompt "Press any key to continue or CTRL+C to quit" | Out-Null

# Initialize runspace pool
$runspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
$runspacePool.Open()
$runspaces = @()

# Log file setup
$logFile = "C:\ConnectionMonitor\connection_attempts.log"
$logDir = "C:\ConnectionMonitor"
$logJson = "C:\ConnectionMonitor\connection_attempts.json"

# Create synchronized hashtable for connection attempts
$Global:connectionAttempts = [hashtable]::Synchronized(@{})
$Global:syncRoot = [System.Object]::new()

function Write-Logs {
    param([string]$logMessage)
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage -ForegroundColor Yellow
}

# Create log directory if it doesn't exist
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}

# Create or clear log file
Set-Content -Path $logFile -Value "Honeypot Started $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -Force

# Initialize JSON log if it doesn't exist
if (-not (Test-Path $logJson)) {
    $Global:connectionAttempts | ConvertTo-Json | Set-Content $logJson
}

# Function to update connection attempts and JSON log
function Update-ConnectionAttempts {
    param(
        [string]$sourceIP,
        [string]$logJsonPath
    )
    
    [System.Threading.Monitor]::Enter($Global:syncRoot)
    try {
        if ($Global:connectionAttempts.ContainsKey($sourceIP)) {
            $Global:connectionAttempts[$sourceIP]++
        } else {
            $Global:connectionAttempts[$sourceIP] = 1
        }
        
        # Update JSON file
        $Global:connectionAttempts | ConvertTo-Json | Set-Content $logJsonPath
    }
    finally {
        [System.Threading.Monitor]::Exit($Global:syncRoot)
    }
}

# Function to start TCP listener for a port
function Start-PortListener {
    param(
        [string]$serviceName,
        [hashtable]$serviceConfig
    )

    $scriptBlock = {
        param(
            $serviceName,
            $serviceConfig,
            $logFile,
            $logJson,
            $connectionAttempts,
            $syncRoot
        )

        try {
            $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, $serviceConfig.Port)
            $listener = [System.Net.Sockets.TcpListener]::new($endpoint)
            $listener.Start()

            while ($true) {
                if ($listener.Pending()) {
                    $client = $listener.AcceptTcpClient()
                    $sourceIP = $client.Client.RemoteEndPoint.Address.ToString()
                    
                    # Log the connection
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $logMessage = "$timestamp - Connection attempt to $serviceName (Port $($serviceConfig.Port)) from IP: $sourceIP"
                    
                    Add-Content -Path $logFile -Value $logMessage
                    
                    # Update connection attempts with proper synchronization
                    [System.Threading.Monitor]::Enter($syncRoot)
                    try {
                        if ($connectionAttempts.ContainsKey($sourceIP)) {
                            $connectionAttempts[$sourceIP]++
                        } else {
                            $connectionAttempts[$sourceIP] = 1
                        }
                        
                        # Update JSON file
                        $connectionAttempts | ConvertTo-Json | Set-Content $logJson
                    }
                    finally {
                        [System.Threading.Monitor]::Exit($syncRoot)
                    }

                    # Prepare and send response
                    $stream = $client.GetStream()
                    if ($serviceConfig.IsBytes) {
                        $response = if ($serviceConfig.Response -is [byte[]]) {
                            $serviceConfig.Response
                        } else {
                            [System.Text.Encoding]::ASCII.GetBytes($serviceConfig.Response)
                        }
                    } else {
                        $response = [System.Text.Encoding]::ASCII.GetBytes($serviceConfig.Response)
                    }

                    $stream.Write($response, 0, $response.Length)
                    $stream.Close()
                    $client.Close()
                }
                Start-Sleep -Milliseconds 100
            }
        }
        catch {
            Add-Content -Path $logFile -Value "Error on port $($serviceConfig.Port) : $_"
        }
        finally {
            if ($listener) {
                $listener.Stop()
            }
        }
    }

    # Create and start the runspace
    $runspace = [powershell]::Create().AddScript($scriptBlock).AddArgument($serviceName).AddArgument($serviceConfig).AddArgument($logFile).AddArgument($logJson).AddArgument($Global:connectionAttempts).AddArgument($Global:syncRoot)
    $runspace.RunspacePool = $runspacePool

    $handle = $runspace.BeginInvoke()
    
    return @{
        Runspace = $runspace
        Handle = $handle
    }
}

$testports = foreach ($item in Get-NetTCPConnection -State Listen | Select-Object LocalPort) {
    [PSCustomObject]@{
        Port = $item.LocalPort
    }
}


# Start listeners
foreach ($service in $serviceData.GetEnumerator()) {
    $portToCheck = $service.Value.Port

    if ($testports | Where-Object {$_.Port -eq $portToCheck}) {
        Write-Host "Port $portToCheck is already in use. Skipping honeypot for $($service.Key)." -ForegroundColor Red
    } else {
        Write-Host "Starting honeypot for $($service.Key) on port $portToCheck..." -ForegroundColor Cyan
        $runspaces += Start-PortListener -serviceName $service.Key -serviceConfig $service.Value
    }
}

Read-Host -Prompt "Press any key to continue or CTRL+C to quit" | Out-Null

# Function to pretty print connection statistics
function Show-ConnectionStatistics {
    Clear-Host
    Write-Host "`nMonitoring connections... Make sure to press Ctrl+C to stop or the honeypots may not be cleaned up.`n" -ForegroundColor Cyan
    Write-Host "Connection Attempts Summary:" -ForegroundColor blue
    Write-Host "------------------------" -ForegroundColor Cyan
    
    if ($Global:connectionAttempts.Count -eq 0) {
        Write-Host "No connection attempts recorded yet." -ForegroundColor Yellow
    } else {
        $Global:connectionAttempts.GetEnumerator() | 
            Sort-Object Value -Descending | 
            Format-Table @{
                Label = "IP Address"
                Expression = { $_.Key }
                Width = 20
            },
            @{
                Label = "Attempts"
                Expression = { $_.Value }
                Width = 10
            } -AutoSize
    }
}

try {
    while ($true) {
        Show-ConnectionStatistics
        Start-Sleep -Seconds 1
    }
}
finally {
    # Cleanup
    Write-Host "`nStopping all listeners..." -ForegroundColor Yellow
    foreach ($runspace in $runspaces) {
        $runspace.Runspace.Stop()
        $runspace.Runspace.Dispose()
    }
    $runspacePool.Close()
    $runspacePool.Dispose()
    Write-Host "All honeypots stopped and cleaned up." -ForegroundColor Green
}
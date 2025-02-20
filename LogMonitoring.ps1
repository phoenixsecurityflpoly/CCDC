# Log files to monitor (adjust paths as needed)
$LogFiles = @(
    "C:\Users\vboxuser\Downloads\testlog.txt" # Example text file
    # Add other log files as needed
)

# Keywords to search for (add more as needed)
$Keywords = "failed login", "error", "attack", "unauthorized", "root", "administrator", "password"

# Black Team IPs (to exclude from alerts - IMPORTANT!)
$BlackTeamIPs = @("192.168.1.10", "192.168.1.11")

# Internal Network (to exclude - IMPORTANT!)
$InternalNet = "192.168.1.0/24" # Example: Your internal network

# Function to check if an IP is in the whitelist
function Is-Whitelisted {
    param (
        [string]$IP
    )
    foreach ($WhitelistedIP in $BlackTeamIPs, $InternalNet) {
        if ($IP -like "$WhitelistedIP*") { # Use -like for wildcard matching
            return $true  # Whitelisted
        }
    }
    return $false  # Not whitelisted
}

# Function to convert CIDR to wildcard format
function ConvertTo-WildcardIP {
    param([string]$cidr)

    $parts = $cidr.Split("/")
    $ipaddress = $parts[0]
    $bits = [int]$parts[1]  # Convert to integer immediately

    if ($bits -lt 0 -or $bits -gt 32) {
        Write-Error "Invalid CIDR notation: $cidr"
        return $null # Or throw an exception
    }
    # Calculate the subnet mask as an integer.  This is the KEY FIX.
    $mask = [uint32]::MaxValue - [math]::Pow(2, (32 - $bits)) + 1

    # Convert the subnet mask to an array of bytes.
    $maskBytes = [System.BitConverter]::GetBytes([System.Net.IPAddress]::HostToNetworkOrder([int32]$mask))

	#Wildcard mask
	$wildcardmask = -join ($maskBytes | Foreach-Object {255-$_})
	$wildcardmasksplit = $wildcardmask.Split(".")

    #NetworkID
    $ipOctets = $ipaddress.Split('.')
    $networkid = for ($i=0; $i -lt 4; $i++) {
        $ipOctets[$i] -band $maskBytes[$i]
    }

    #Result
    $result = for ($i=0; $i -lt 4; $i++) {
        $octet = $networkid[$i] + ([int[]](0..255) | Where-Object {($_ -band $wildcardmasksplit[$i]) -eq 0})
        $octet = ($octet | Foreach-Object { if ($_ -gt 99) {$_} elseif ($_ -gt 9) {"0$_"} else {"00$_"}}) -join ","
        $octet
    }
    $result -join "."
}

# Monitor the log files
foreach ($LogFile in $LogFiles) {
    if (!(Test-Path -Path $LogFile)) {
        Write-Warning "Log file not found: $LogFile"
        continue
    }

    # Use Get-WinEvent for .evtx files, Get-Content for text files
    if ($LogFile -like "*.evtx") {
        # Event Log Monitoring
        $Query = "*[System[(Level=1  or Level=2 or Level=3 or Level=4) and TimeCreated[timediff(@SystemTime) <= 86400000]]]"

        try{
            Get-WinEvent -FilterHashtable @{LogName=$LogFile.Split('\')[-1].Replace(".evtx",""); StartTime = (Get-Date).AddMinutes(-1)} -ErrorAction Stop | ForEach-Object {
            #Write-Host $_.Properties[0].Value #Example of getting a value
            $Line = $_.Message
            $MatchedIP = ([regex]'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b').Matches($Line).Value

            if ($null -ne $MatchedIP -and (Is-Whitelisted $MatchedIP)) {
                return  # Skip to the next event if the IP is whitelisted
            }

            # Convert Internal network to wildcard, and add to black team IPs
            $internalNetwildcard = ConvertTo-WildcardIP $InternalNet
            $blackTeamIpsToUse = $BlackTeamIPs
            $blackTeamIpsToUse += $internalNetwildcard

            if($null -ne $MatchedIP -and ($MatchedIP -in $blackTeamIpsToUse)){
                continue;
            }

            foreach ($Keyword in $Keywords) {
                if ($Line -match $Keyword) {
                    Write-Host ("ALERT: Suspicious activity detected in " + $LogFile + ":") -ForegroundColor Red
                    Write-Host $Line -ForegroundColor Yellow
                    # Add more sophisticated alerting (e.g., send email) here
                }
            }
            }
        }
        catch
        {
            Write-Host "Could not read the log: $($LogFile.Split('\')[-1].Replace('.evtx',''))" -ForegroundColor Red
        }
    }
    else
    {
        # Text File Monitoring (using Get-Content with -Wait)
        Get-Content -Path $LogFile -Wait -Tail 0 | ForEach-Object {
            $Line = $_
            $MatchedIP = ([regex]'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b').Matches($Line).Value

            # Convert Internal network to wildcard, and add to black team IPs
            $internalNetwildcard = ConvertTo-WildcardIP $InternalNet
            $blackTeamIpsToUse = $BlackTeamIPs
            $blackTeamIpsToUse += $internalNetwildcard

            if ($null -ne $MatchedIP -and (Is-Whitelisted $MatchedIP)) {
                return  # Skip to the next line if the IP is whitelisted
            }

            foreach ($Keyword in $Keywords) {
                if ($Line -match $Keyword) {
                    Write-Host ("ALERT: Suspicious activity detected in " + $LogFile + ":") -ForegroundColor Red
                    Write-Host $Line -ForegroundColor Yellow
                    # Add more sophisticated alerting (e.g., send email) here
                }
            }
        }
    }
}
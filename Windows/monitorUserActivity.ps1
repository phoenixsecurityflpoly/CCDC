# Black Team IPs
$BlackTeamIPs = @("192.168.1.10", "192.168.1.11")

# Internal Network
$InternalNet = "192.168.1.0/24"

# Whitelist function (same as in Log_Monitor)
function Is-Whitelisted {
  param (
    [string]$IP
  )
  foreach ($WhitelistedIP in $BlackTeamIPs + $InternalNet) {
      if ($IP -like "$WhitelistedIP*") { #Wild card matching.
        return $true
      }
  }
  return $false
}

#Monitor Login Events
while($true) {
    $loginEvents = Get-WinEvent -FilterHashtable @{
      Logname   = 'Security'
      ID        = 4624  # Logon event ID
    } -MaxEvents 10 -ErrorAction SilentlyContinue #Grab only the 10 most recent

    if($loginEvents) {
        foreach($event in $loginEvents) {
            $eventXML = [xml]$event.ToXml()
             $IPAddress = $eventXML.Event.EventData.Data | Where-Object {$_.name -eq "IpAddress"}
            if ($IPAddress -and (Is-Whitelisted $IPAddress.'#text')) {
                continue
            }
            Write-Host "User Activity Alert (Login): $($event.TimeCreated)" -ForegroundColor Red
            Write-Host $event.Message
        }
    }
# Monitor Logoff Events
    $logoffEvents = Get-WinEvent -FilterHashtable @{
          Logname   = 'Security'
          ID        = 4634  # Logoff event ID
        } -MaxEvents 10 -ErrorAction SilentlyContinue #Grab only the 10 most recent

        if($logoffEvents) {
            foreach($event in $logoffEvents) {
                $eventXML = [xml]$event.ToXml()
                $IPAddress = $eventXML.Event.EventData.Data | Where-Object {$_.name -eq "IpAddress"}
                if ($IPAddress -and (Is-Whitelisted $IPAddress.'#text')) {
                    continue
                }
                Write-Host "User Activity Alert (Logoff): $($event.TimeCreated)" -ForegroundColor Red
                Write-Host $event.Message
            }
        }
    Start-Sleep -Seconds 60 #Check once a minute
}
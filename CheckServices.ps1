# List of services to monitor (replace with your actual services)
$Services = @("Apache2.4", "SSHD", "DNS")  # Example services.  Use Get-Service to find the correct names.

# Black Team IPs (replace with actual IPs)
$BlackTeamIPs = @("192.168.1.10", "192.168.1.11")

foreach ($Service in $Services) {
  $Status = Get-Service -Name $Service
  if ($Status.Status -eq "Running") {
    Write-Host "$Service is running"
  }
  else {
    Write-Host "$Service is NOT running. Restarting..."
    Restart-Service -Name $Service -Force -ErrorAction SilentlyContinue
    $Status = Get-Service -Name $Service
    if($Status.Status -eq "Running"){
        Write-Host "$Service restarted successfully"
    } else {
        Write-Host "$($Service) FAILED to restart. Investigate!" -ForegroundColor Red
    }
  }
}

# Consider using a Scheduled Task to run this script regularly.
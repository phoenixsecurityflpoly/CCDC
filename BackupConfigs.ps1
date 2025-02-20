# Directories and files to back up
$BackupDirs = @(
    "C:\xampp\apache\conf",  # Example Apache config
    "C:\Program Files\OpenSSH\etc", # Example SSH config
    "C:\inetpub\wwwroot"       # Example web root
    # Add other directories as needed
)

# Backup location
$BackupDir = "C:\Backups"
$BackupFile = Join-Path $BackupDir ("config_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".zip")

# Create the backup directory if it doesn't exist
if (-not (Test-Path -Path $BackupDir)) {
  New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

# Create the backup using Compress-Archive
Compress-Archive -Path $BackupDirs -DestinationPath $BackupFile -Force

Write-Host "Backup created: $BackupFile"
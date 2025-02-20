# File containing the known-good hashes (you need to create this!)
$HashFile = "C:\file_hashes.csv"

# Files and directories to check
$FilesToCheck = @(
    "C:\Windows\System32\notepad.exe",
    "C:\Windows\System32\calc.exe"
    # Add other files/directories as needed
)

# Generate initial hash file (Run ONCE on a CLEAN system)
# Get-FileHash -Algorithm SHA256 $FilesToCheck | Select-Object Hash, Path | Export-Csv -Path $HashFile -NoTypeInformation

# Function to check file integrity
function Check-FileIntegrity {
    try {
        $Hashes = Import-Csv $HashFile -ErrorAction Stop
    }
    catch {
        Write-Error "Error reading hash file: $($_.Exception.Message)"
        return # Exit the function if the hash file can't be read
    }

    foreach($file in $FilesToCheck) {
        if(-not(Test-Path $file)){
            Write-Warning "File Not Found: $file"
            continue
        }

        try {
            $currentHash = Get-FileHash -Algorithm SHA256 $file -ErrorAction Stop | Select-Object -ExpandProperty Hash
        }
        catch {
            Write-Warning "Error getting hash for: $file"
            Write-Warning $_.Exception.Message
            continue
        }

        $expectedHashEntry = $Hashes | Where-Object {$_.Path -eq $file}

        if($expectedHashEntry){
            $expectedHash = $expectedHashEntry.Hash

            if($currentHash -ne $expectedHash) {
                Write-Host "WARNING: File integrity check failed for $file" -ForegroundColor Red
                Write-Host "  Expected hash: $expectedHash"
                Write-Host "  Current hash:  $currentHash"
                # Add alerting (e.g., send email) here
            }
        } else {
            Write-Warning "Expected hash not found for: $file"
        }
    }
}

# Perform the integrity check
Check-FileIntegrity
# **WARNING:** This script changes passwords. Use with EXTREME CAUTION.
# Store the new passwords SECURELY.

# List of administrator usernames
$AdminUsers = @(
    "Administrator"
    # Add other admin usernames here
)

# List of normal usernames
$NormalUsers = @(
    "someuser",
    "anotheruser"
    # Add other normal usernames here
)

# --- Function to Generate a Secure Random Password ---
function Generate-SecurePassword {
    param (
        [int]$Length = 16  # Default password length
    )

    # Define character sets
    $Lowercase = "abcdefghijklmnopqrstuvwxyz"
    $Uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $Numbers = "0123456789"
    $SpecialChars = "!@#$"

    # Combine character sets
    $AllChars = $Lowercase + $Uppercase + $Numbers + $SpecialChars

    # Ensure minimum length for complexity
    if ($Length -lt 12) {
        Write-Warning "Password length less than 12 is not recommended.  Using 12."
        $Length = 12
    }

    # Build the password
    $Password = ""
    $Password += Get-Random -InputObject ($Lowercase.ToCharArray())
    $Password += Get-Random -InputObject ($Uppercase.ToCharArray())
    $Password += Get-Random -InputObject ($Numbers.ToCharArray())
    $Password += Get-Random -InputObject ($SpecialChars.ToCharArray())

   while ($Password.Length -lt $Length) {
        $Password += Get-Random -InputObject ($AllChars.ToCharArray())
    }

    # Shuffle the password to ensure randomness
    $Password = $Password | Get-Random -Count $Password.Length

    return $Password
}

# --- Function to Change Password ---
function Change-UserPassword {
    param (
        [string]$Username,
        [string]$UserType # "Admin" or "Normal"
    )

	# Generate a new secure password
    $NewPassword = Generate-SecurePassword

    try {
        $User = [ADSI]"WinNT://localhost/$Username,user"
        $User.SetPassword($NewPassword)
        $User.SetInfo()
        Write-Host "Password changed for $UserType user: $Username" -ForegroundColor Green
        Write-Host ("New Password for " + $Username + ": " + $NewPassword) -ForegroundColor Yellow # Output the password

        # Force password change on next login (optional, but generally good practice)
        net user $Username /passwordchg:yes
    }
    catch {
        Write-Host "Could not change the password for $UserType user: $Username" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

# --- Change Passwords for Admin Users ---
foreach ($AdminUser in $AdminUsers) {
    Change-UserPassword -Username $AdminUser -UserType "Admin"
}

# --- Change Passwords for Normal Users ---
foreach ($NormalUser in $NormalUsers) {
    Change-UserPassword -Username $NormalUser  -UserType "Normal"
}

Write-Host "Password change script completed."
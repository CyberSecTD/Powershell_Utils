# Import the LAPS module
Import-Module AdmPwd.PS

# Get a list of computers from Active Directory
$computers = Get-ADComputer -Filter * -Properties DisplayName

# Iterate through the computers and check LAPS configuration
$configuredComputers = foreach ($computer in $computers) {
    $computerName = $computer.Name

    # Retrieve LAPS password information for the computer
    $lapsPassword = Get-AdmPwdPassword -ComputerName $computerName -ErrorAction SilentlyContinue

    # Check if LAPS password is present and not expired
    if ($lapsPassword -ne $null -and $lapsPassword.ExpirationTimestamp -gt (Get-Date)) {
        $computerName
    }
}

# Display the count and the list of computers with proper LAPS configuration
Write-Output "Computers with LAPS configured: $($configuredComputers.Count)"
Write-Output "Computer Names: $($configuredComputers -join ', ')"

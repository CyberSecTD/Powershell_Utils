# Import the Active Directory module
Import-Module ActiveDirectory 

# Import the AWS Tools for PowerShell module
Import-Module -Name AWSPowerShell

# Set your AWS access key and secret key
$accessKey = "XXXXXXXXXXXXXXXXXXXX"
$secretKey = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Set the email parameters
$from = "sender.email@company.com"   # Sender's email address
$subject = "Password Expiry Notification" # Email subject

# Specify the region for assuming the role
$region = "ap-southeast-1"  # Replace with the desired region

# Configure AWS credentials with the specified region
#Set-AWSCredentials -AccessKey $accessKey -SecretKey $secretKey -Region $region
Initialize-AWSDefaultConfiguration -AccessKey $accessKey -SecretKey $secretKey -Region $region

# Get the current date
$currentDate = Get-Date

# Get the expiry date for password
$expiryDate = $currentDate.AddDays(10)

# Get the list of Active Directory users
$users = Get-ADUser -Filter {Enabled -eq $true -and PasswordNeverExpires -eq $false} -Properties PasswordExpired, PasswordLastSet, EmailAddress

# Loop through each user
foreach ($user in $users) {
    # Check if the password is expiring within 10 days
    if ($user.PasswordLastSet) {
        $expiry = $user.PasswordLastSet.AddDays((Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.TotalDays)
        
        if ($expiry -lt $expiryDate -and $expiry -gt $currentDate) {
            $expiryDaysRemaining = ($expiry - $currentDate).Days

            $to = $user.EmailAddress  # Recipient's email address
            $body = @"

              *** This is a system-generated email. Please do not reply. ***

Hi $($user.Name),

This is to notify you that your domain password will expire in $expiryDaysRemaining day(s). Please change it ASAP.

Regards,
IAM Team
"@
            # Create the raw email message
            $emailHeaders = "From: $from`nTo: $to`nSubject: $subject`nContent-Type: text/plain`n"
            $emailContent = [System.Text.Encoding]::UTF8.GetBytes($emailHeaders + "`n" + $body)

            # Send the raw email using Amazon SES
            Send-SESRawEmail -RawMessage_Data $emailContent
        }
    }
}

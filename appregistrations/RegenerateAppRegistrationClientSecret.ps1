# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All", "Application.ReadWrite.All"

# Specify the Application (App Registration) objectId
$objectId = "REPLACE-ME"

$response = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/applications/$($objectId)"
$clientSecrets = $response.PasswordCredentials

# Define a threshold for expiration (e.g., 5 days)
$thresholdDays = 5

# Display and check expiration dates for each secret
if ($clientSecrets) {
    foreach ($secret in $clientSecrets) {
        Write-Host "Client Secret ID: $($secret.KeyId)"
        Write-Host "Start Date: $($secret.StartDateTime)"
        Write-Host "Expiration Date: $($secret.EndDateTime)"

        # Calculate days until expiration
        $daysUntilExpiration = ($secret.EndDateTime - (Get-Date)).Days
        if ($daysUntilExpiration -le $thresholdDays) {
            Write-Host "WARNING: This secret is set to expire in $daysUntilExpiration days!" -ForegroundColor Yellow
            
            # Create a New Client Secret
            Write-Host "Creating a new client secret..."
            $newSecret = Add-MgApplicationPassword -ApplicationId $objectId -PasswordCredential @{
                displayName = "Regenerated secret"
                StartDateTime = Get-Date
                EndDateTime = (Get-Date).AddYears(1)  # Set a 1-year expiration or adjust as needed
            }

            Write-Host "New Client Secret created successfully!"
            Write-Host "Secret Value: $($newSecret.SecretText)" -ForegroundColor Green
            Write-Host "IMPORTANT: Save this secret value as it cannot be retrieved later!"
        } else {
            Write-Host "Status: This secret is safe and expires in $daysUntilExpiration days." -ForegroundColor Green
        }
        Write-Host "-------------------------"
    }
} else {
    Write-Host "No client secrets found for the specified App Registration."
}
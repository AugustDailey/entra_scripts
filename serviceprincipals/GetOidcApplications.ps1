# Connect to Microsoft Graph (Sign in with required permissions)
Connect-MgGraph -Scopes "Application.Read.All"

# Get all Enterprise Applications
$EnterpriseApps = Get-MgServicePrincipal -Filter "tags/Any(x: x eq 'WindowsAzureActiveDirectoryIntegratedApp')"
# Loop through each application and check authentication method
foreach ($App in $EnterpriseApps) {
    $AppName = $App.DisplayName
    $SignInMode = $App.PreferredSingleSignOnMode
    $OAuthScopes = $App.Oauth2PermissionScopes
    $ReplyUrls = $App.ReplyUrls

    if ($SignInMode -eq $null -and $ReplyUrls.Count -gt 0) {
        Write-Output "$AppName is using OpenID Connect (OIDC) or OAuth authentication."
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
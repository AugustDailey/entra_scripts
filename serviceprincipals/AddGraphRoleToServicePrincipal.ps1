Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Your service principal's display name
$spDisplayName = "<REPLACE-ME>"
# The Microsoft Graph role you want to assign (i.e. User.Read.All)
$graphRole = "<REPLACE-ME>"

$sp = Get-MgServicePrincipal -Filter "displayName eq '$spDisplayName'"
$graphServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"

# Find the role on the MS Graph app
$appRole = $graphServicePrincipal.AppRoles | Where-Object { $_.Value -eq $graphRole -and $_.AllowedMemberTypes -contains "Application" }
$params = @{
	principalId = $sp.Id
	resourceId = $graphServicePrincipal.Id
	appRoleId = $appRole.Id
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -BodyParameter $params

$_ = Disconnect-MgGraph
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.ReadWrite.All"

# Your service principal's display name
$spDisplayName = "<REPLACE-ME>"

$sp = Get-MgServicePrincipal -Filter "displayName eq '$spDisplayName'"
$appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id

# Remove all assigned roles
foreach ($assignment in $appRoleAssignments) {
    Remove-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -AppRoleAssignmentId $assignment.Id
    Write-Output "Removed role: $($assignment.appRoleId)"
}

# Confirm all roles have been removed
$appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id
Write-Output "Remaining roles: $($appRoleAssignments.Count)"

$_ = Disconnect-MgGraph
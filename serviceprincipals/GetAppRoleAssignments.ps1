# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Application.Read.All"

# Define variables
$objectId = "<REPLACE-ME>"  # Replace with the group, user, or service principal Object ID

# Fetch app role assignments for the specified object
$appRoleAssignments = Get-MgGroupAppRoleAssignment -GroupId $objectId

# Display the app role assignments
if ($appRoleAssignments) {
    foreach ($assignment in $appRoleAssignments) {
        Write-Host "Resource (App) ID: $($assignment.ResourceId)"
        Write-Host "App Role ID: $($assignment.AppRoleId)"
        Write-Host "Principal Type: $($assignment.PrincipalType)"
        Write-Host "------------------------"
    }
} else {
    Write-Host "No app role assignments found for the specified object."
}
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("user", "group", "all")]
    [string]$Source,
    [string]$UserId,
    [string]$GroupId,
    [string]$CsvOutputPath = ".\UserMFAStatus.csv"  # Default file path
)


$connect = Connect-MgGraph

if ($Source -eq "user") {
    $UserIds = @($UserId)
} elseif ($Source -eq "group") {
    $UserIds = Get-MgGroupMember -GroupId $GroupId | Select-Object -ExpandProperty Id
} elseif ($Source -eq "all") {
    $UserIds = Get-MgUser | Select-Object -ExpandProperty Id
}

$Results = @()
$UserCountWithMFA = 0
foreach ($UserId in $UserIds) {
    $AuthMethods = Get-MgBetaUserAuthenticationMethod -UserId $UserId | Where-Object { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" }
    $HasMfa = !(!($AuthMethods))
    $Result = [PSCustomObject]@{
        UserId = $UserId
        MFAStatus = $HasMfa
    }

    # Add to results array
    $Results += $Result
    if ($HasMfa) {
        $UserCountWithMFA++
    }
}

Write-Output "Users with MFA: $($UserCountWithMFA) out of $($UserIds.Count)"
$Results | Export-Csv -Path $CsvOutputPath -NoTypeInformation
Write-Output "User MFA statuses exported to: $($CsvOutputPath)"

$disconnect = Disconnect-MgGraph


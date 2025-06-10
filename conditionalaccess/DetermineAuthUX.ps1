# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All"

# Set these values before running
$UserId = "REPLACE ME"
$ssprGroups = @(
    "00000000-0000-0000-0000-000000000000",
    "00000000-0000-0000-0000-000000000000"
)

$User = Get-MgUser -UserId $UserId
$UserGroups = Get-MgUserMemberOf -UserId $userId
$UserAuthMethods = Get-MgBetaUserAuthenticationMethod -UserId $UserId
$AuthAppRegistrations = $UserAuthMethods | Where-Object { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" }

# FETCH STAGED ROLLOUT GROUPS
$stagedRolloutPolicies = Get-MgPolicyFeatureRolloutPolicy
$phsPolicy = $stagedRolloutPolicies | Where-Object { $_.Feature -eq "passwordHashSync"}

$phsPolicy = Get-MgPolicyFeatureRolloutPolicy -FeatureRolloutPolicyId $phsPolicy.Id -ExpandProperty "appliesTo"
$phsGroups = $phsPolicy.appliesTo | Select-Object -ExpandProperty Id

# FETCH MFA REG CAMPAIGN INCLUSIONS & EXCLUSIONS
$authPolicy = Get-MgBetaPolicyAuthenticationMethodPolicy
$mfaRegistrationCampaignInclusions = $authPolicy.RegistrationEnforcement.AuthenticationMethodsRegistrationCampaign.IncludeTargets | Where-Object { $_.TargetedAuthenticationMethod -eq "microsoftAuthenticator"}
$mfaRegUserInclusions = $mfaRegistrationCampaignInclusions | Where-Object { $_.TargetType -eq "user"}
$mfaRegGroupInclusions = $mfaRegistrationCampaignInclusions | Where-Object { $_.TargetType -eq "group"}

$mfaRegistrationCampaignExclusions = $authPolicy.RegistrationEnforcement.AuthenticationMethodsRegistrationCampaign.ExcludeTargets
$mfaRegUserExclusions = $mfaRegistrationCampaignExclusions | Where-Object { $_.TargetType -eq "user"}
$mfaRegGroupExclusions = $mfaRegistrationCampaignExclusions | Where-Object { $_.TargetType -eq "group"}

# FETCH AUTH APP USERS
$authAppPolicyConfig = Get-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration -AuthenticationMethodConfigurationId  "MicrosoftAuthenticator"
$authAppInclusions = $authAppPolicyConfig.AdditionalProperties.includeTargets
$authAppExclusions = $authAppPolicyConfig.AdditionalProperties.excludeTargets

# IS THE USER IN STAGED ROLLOUT?
$newAuth = $false
if ($phsGroups | Where-Object { $_ -in ($UserGroups.Id) }) {
    $newAuth = $true
}

# WILL A USER BE PROMPTED TO REGISTER FOR MFA?
$willReceiveMfaRegistrationPrompt = $false
$context = ""
if (!($AuthAppRegistrations)) {
    # Look to see if user is in a group that is included for SSPR
    $isIncludedInSsprReg = $ssprGroups | Where-Object { $_ -in ($UserGroups.Id) }

    # Look to see if user is in a group that is included in the MS Authentication App method in the Tenant Auth Policy
    $isExcludedFromAuthenticatorAppAuthMethod = !(!($authAppExclusions | Where-Object { $_ -in ($UserGroups.Id) }))
    $isIncludedInAuthenticatorAppAuthMethod = !($isExcludedFromAuthenticatorAppAuthMethod) -and ("all_users" -in $authAppInclusions.id -or !(!($authAppInclusions.id | Where-Object { $_ -in ($UserGroups.Id) })))
    # Look to see if user is in a group that is included in the MFA Registration Campaign

    $isExcludedFromRegCampaign = ($User.Id -in ($mfaRegUserExclusions.id)) -or ($mfaRegGroupExclusions.id | Where-Object { $_ -in ($UserGroups.Id) })
    $isIncludedInRegCampaign = !($isExcludedFromRegCampaign) -and (($User.Id -in ($mfaRegUserInclusions.id)) -or ("all_users" -in $mfaRegGroupInclusions.id) -or ($mfaRegGroupInclusions.id | Where-Object { $_ -in ($UserGroups.Id) }))

    if ($isIncludedInAuthenticatorAppAuthMethod) {

        if ($isIncludedInSsprReg) {
            $willReceiveMfaRegistrationPrompt = $true
        }
        elseif  ($isIncludedInRegCampaign) {
            $willReceiveMfaRegistrationPrompt = $false
            $context = "Dependent on CA policy eval"
        }

    }
    else {
        $context = "User not allowed to use Authenticator app"
    }
}

if ($newAuth) { 
    Write-Output "User is included in staged rollout (authenticates via Microsoft Entra)" 
} else { 
    "User is not included in staged rollout (authenticates via federation)"
}

if ($willReceiveMfaRegistrationPrompt) { 
    Write-Output "User will be required to register for MFA at next sign-in" 
} elseif (!($willReceiveMfaRegistrationPrompt) -and !($context)) { 
    Write-Output "User is already registered for MFA and will be prompted if a CA policy requires it."
} elseif (!($willReceiveMfaRegistrationPrompt) -and ($context -eq "User not allowed to use Authenticator app")) {
    Write-Output "User is not allowed to use Microsoft Authenticator. If this isn't expected, add them to the group that is assigned to this method (Authentication Methods -> policies -> MS Authenticator)"
} elseif (!($willReceiveMfaRegistrationPrompt) -and ($context -eq "Dependent on CA policy eval")) {
    Write-Output "User will be required to register for MFA at next sign-in ONLY IF a CA policy requires MFA."
}
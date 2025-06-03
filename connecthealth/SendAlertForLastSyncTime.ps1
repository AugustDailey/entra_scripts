
Connect-MgGraph
Get-MgOrganization -OrganizationId "<TENANT_ID>" | select OnPremisesLastSyncDateTime

Send-MgUserMail -UserId "<REPLACE-ME>" -Message @{
    Subject = "<REPLACE-ME>"
    Body = @{
        ContentType = "<REPLACE-ME>"
        Content = "<REPLACE-ME>"
    }
    ToRecipients = @(@{
        EmailAddress = @{ Address = "<REPLACE-ME>" }
    })
} -SaveToSentItems

Disconnect-MgGraph
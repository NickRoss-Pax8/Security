######### Secrets #########
$ApplicationId = 'ApplicationID'
$ApplicationSecret = 'ApplicationSecret' | ConvertTo-SecureString -Force -AsPlainText
$TenantID = 'Partner Center TenantID'
$RefreshToken = 'LongRefreshToken'

######### Create Connection #########
$secPas = $ApplicationSecret| ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($ApplicationId, $secPas)
 
$aadGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Tenant $tenantID
$graphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Tenant $tenantID
 
Connect-MsolService -AdGraphAccessToken $aadGraphToken.AccessToken -MsGraphAccessToken $graphToken.AccessToken
 
$customers = Get-MsolPartnerContract -All
 
$Baseuri = "https://graph.microsoft.com/beta"
$MFAState = foreach ($customer in $customers) {
    $users = Get-MSoluser -TenantId $customer.TenantId -All | Where {$_.UserPrincipalName -NotLike "*#EXT#*" -and $_.isLicensed -eq $true} 
    $PerUserMFA = foreach ($user in $users) {
        $MFAStatus = if ($null -ne $user.StrongAuthenticationUserDetails) { ($user.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq $true }).methodType } else { "Disabled" } 
        [PSCustomObject]@{
            "Customer"    = $customer.Name
            "DisplayName" = $user.DisplayName
            "UPN"         = $user.UserPrincipalName
            "MFA Type"    = $MFAStatus
        }
    }
    try {
        $CustGraphToken = New-PartnerAccessToken -ApplicationId $ApplicationId -Credential $credential -RefreshToken $refreshToken -Scopes "https://graph.microsoft.com/.default" -ServicePrincipal -Tenant $customer.TenantId
        $Header = @{ Authorization = "Bearer $($CustGraphToken.AccessToken)" }
        $SecureDefaultsState = (Invoke-RestMethod -Uri "$baseuri/policies/identitySecurityDefaultsEnforcementPolicy" -Headers $Header -Method get -ContentType "application/json").IsEnabled
        $CAPolicies = (Invoke-RestMethod -Uri "$baseuri/identity/conditionalAccess/policies" -Headers $Header -Method get -ContentType "application/json").value
    }
    catch {
        $CAPolicies = $false
    }
    $EnforcedForUsers = foreach ($Policy in $CAPolicies) {
        if ($policy.grantControls.builtincontrols -ne 'mfa') { continue }
        if ($Policy.conditions.applications) {
            [PSCustomObject]@{
                Name   = $policy.displayName
                Target = 'Specific Applications'
            }
            continue
        }
 
        if ($Policy.conditions.users.includeUsers -eq "All") {
            [PSCustomObject]@{
                Name   = $policy.displayName
                Target = 'All Users'
            } 
        }
             
    }
 
    $enforced = if ($EnforcedForUsers | Where-Object -Property Target -eq "All Users") { $True } else { $false }
    [PSCustomObject]@{
        TenantName                        = $customer.DefaultDomainName
        UserList                          = $PerUserMFA
        'Secure Defaults Enabled'         = $SecureDefaultsState
        'Conditional Access'              = $CAPolicies
        'Conditional Access Enforced MFA' = $Enforced
    }
 
}
 
$DisabledMFA = if ($MFAState.'Security Defaults Enabled' -eq $false -or $MFAState.'Conditional Access Enforced MFA') {
    $MFAState.userlist | Where-Object -Property "MFA Type" -eq "Disabled"
}
$DisabledMFA | Export-CSV C:\Temp\disabledMFAUsers.csv
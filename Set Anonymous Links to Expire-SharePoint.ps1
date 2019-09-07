Install-Module -Name Microsoft.Online.SharePoint.PowerShell

$SharePointURL = Read-Host -Prompt "Enter your Tenants SharePoint Admin URL. This is typically in the format of https://domain-admin.sharepoint.com"

Connect-SPOService -url $SharePointURL


Set-SPOTenant -SharingCapability ExternalUserAndGuestSharing

Set-SPOTenant -RequireAnonymousLinksExpireInDays 7 
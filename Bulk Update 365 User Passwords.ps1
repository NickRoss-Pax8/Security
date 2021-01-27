##########Connect to Exchange Online##########

Write-Host -Prompt "Connecting to Exchange Online"

$credential = Get-Credential

Install-module Msonline
Import-Module MsOnline
Connect-MsolService -Credential $credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -DisableNameChecking

############# Define CSV path of Users and Group ##################

$UserPath = Read-Host -Prompt "Enter File Path For CSV list of users"


#####Create CSV template with headers of Userprincipalname and Password#######


Import-Csv -Path $UserPath |%{Set-MsolUserPassword -userPrincipalName $_.UserPrincipalName –NewPassword $_.Password -ForceChangePassword $True}
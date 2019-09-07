Install-Module -Name Microsoft.Online.SharePoint.PowerShell

##Variables for Processing
$SiteUrl = Read-Host -Prompt "Enter the site url you want to enable versioning on."
$UserName= Read-Host -Prompt "Enter your username."
$Password =Read-Host -Prompt "Enter your password."
 
try{ 
    #Setup the context
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName,(ConvertTo-SecureString $Password -AsPlainText -Force))
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
    $Context.Credentials = $credentials
     
    #get the site and lists
    $web = $context.Web
    $context.Load($web)
    $context.load($web.lists)
    $Context.executeQuery()
  
    #Iterate through each list in the web
    foreach($list in $web.lists){
    if ($list.hidden -eq $false)
    {
        #Enable versioning
        $list.EnableVersioning = $true
        $lIST.MajorVersionLimit = 50
        $list.Update()
        $Context.ExecuteQuery()
        Write-host "Versioning has been turned ON at :"$List.title
    }
  }
}
catch{
    write-host "Completed Successfully" -foregroundcolor Green
}

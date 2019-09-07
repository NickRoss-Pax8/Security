Connect-MsolService

$role = Get-MsolRole -RoleName "Company Administrator"


Get-MsolRoleMember -RoleObjectId $role.ObjectId
Get-ADOrganizationalUnit -Filter {Name -eq "Application Servers"} -Properties DistinguishedName | 
  Select-Object Name, DistinguishedName
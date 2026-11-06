# 1. Create the computer object in the target OU
New-ADComputer -Name "SERVER-NAME" `
  -Path "OU=Servers,OU=Computers,DC=<INSERT DATA>" `
  -Enabled $true

# 2. If server already exists in default CN=Computers, move it
Move-ADObject -Identity (Get-ADComputer -Name "SERVER-NAME").DistinguishedName `
  -TargetPath "OU=Servers,OU=Computers,DC=<INSERT DATA>"
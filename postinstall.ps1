Set-TimeZone -Name 'US Eastern Standard Time' -PassThr
Start-Process  "C:\Users\Administrator\Documents\Post install\Duo\install64bit.bat" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\Tanium\SetupClient.exe" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\BGInfo\Setup _NonDell.bat" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\cortex.msi"-ArgumentList "/S" -PassThru

# Define variables
$Domain   = "<INSERT DATA>"
$NewName  = "Server01"
$OUPath   = "OU=Servers,DC=yourdomain,DC=com" # Optional: Remove if not targeting a specific OU
$User     = "<INSERT INFORMATION>"

# Prompt securely for the domain password
$Credential = Get-Credential -UserName $User -Message "Enter password to join the domain"

# Execute rename and domain join
Add-Computer -DomainName $Domain -NewName $NewName -OUPath $OUPath -Credential $Credential -Restart -Force

Set-TimeZone -Name 'US Eastern Standard Time' -PassThr
Start-Process  "C:\Users\Public\Documents\BGInfo\Setup _NonDell.bat" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\Cortex\Install Windows Agent.bat" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\DUO\install64bit.bat" -ArgumentList "/S" -PassThru
start-process -Wait "C:\Users\Administrator\Documents\Post install\Azure Agent\InstallAgent.bat"-ArgumentList "/S" -PassThru
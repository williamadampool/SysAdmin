# netsh int ipv4 show interfaces - Run to DNS interface if presented with an interface error.
$IPAdress ='10.20.1.85'


Get-NetAdapter -Name Ethernet| New-NetIPAddress –IPAddress $IPAdress -DefaultGateway 10.20.20.1 -PrefixLength 24
Set-DNSClientServerAddress –InterfaceIndex 2  –ServerAddresses 10.20.1.19, 10.20.25.17
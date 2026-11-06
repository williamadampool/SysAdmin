$uri = "<INSERT DATA>-dispatch.octaveoncall.com"
$port = 443

$client = New-Object System.Net.Sockets.TcpClient
$client.Connect($uri, $port)
$sslStream = New-Object System.Net.Security.SslStream($client.GetStream(),$false,({$true} -as [System.Net.Security.RemoteCertificateValidationCallback]))
$sslStream.AuthenticateAsClient($uri)
$cert = $sslStream.RemoteCertificate | ForEach-Object {New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($_)}

# View the cert
$cert | Select-Object Subject, Issuer, NotBefore, NotAfter, Thumbprint
$sslStream.Close()
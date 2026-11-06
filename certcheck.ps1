$minimumCertAgeDays = 30
$timeoutMilliseconds = 6000
$urls = @(
    "https://veeamone.<INSERT DATA>:1239/"
)

[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

foreach ($url in $urls) {
    Write-Host "Getting certificate information for $url ..." -ForegroundColor "Yellow"
    $req = [System.Net.WebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds

    try {
        $req.GetResponse() | Out-Null
    }
    catch {
        Write-Host "Exception occurred while checking URL $url`: $_ ." -ForegroundColor "Red"
    }
    $expirationString = $req.ServicePoint.Certificate.GetExpirationDateString()

    $dateTimeFormat = "$((Get-Culture).DateTimeFormat.ShortDatePattern) $((Get-Culture).DateTimeFormat.LongTimePattern)"
    $expiration = [DateTime]::ParseExact($expirationString, $dateTimeFormat, [System.Globalization.DateTimeFormatInfo]::InvariantInfo, [System.Globalization.DateTimeStyles]::None)

    [int]$certExpiresIn = ($expiration - $(Get-Date)).Days
    if ($certExpiresIn -gt $minimumCertAgeDays){
        Write-Host "Certificate for site $url expires in $certExpiresIn days (on $('{0:MM.dd.yyyy.}' -f $expiration))." -ForegroundColor "Green"
    }
    else {
        Write-Host "ERROR: Certificate for site $url expires in $certExpiresIn days (on $('{0:MM.dd.yyyy.}' -f $expiration)) and query threshold is set to $minimumCertAgeDays days!" -ForegroundColor "Red"
    }
} ConvertTo-Xml -As "Document" -InputObject (Get-Process) -Depth 3
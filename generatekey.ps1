# Generate a 32-character random PSK using a cryptographic RNG
$chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!#%+=@'
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$psk = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
$psk
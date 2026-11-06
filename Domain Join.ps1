# Prompt the user to input the server name
$hostname = Read-Host -Prompt 'Input your server name'

# Validate the hostname
if (-not $hostname) {
    Write-Host "Invalid hostname. Please provide a valid server name."
    return
}

# Set the domain name
$domain = '<INSERT DATA>'

try {
    # Rename the computer
    Rename-Computer -NewName $hostname -Force -ErrorAction Stop

    # Join the computer to the domain
    Add-Computer -DomainName $domain -NewName $hostname -Force -ErrorAction Stop

    Write-Host "Domain join successful!"
}
catch {
    Write-Host "An error occurred during the domain join process: $_"
}

# ============================================================================
#To find the OU, Run the following script. CHnange the -Filter name to the correct OU
#Get-ADOrganizationalUnit -Filter {Name -eq "Enter OU Name"} -Properties DistinguishedName | 
 # Select-Object Name, DistinguishedName
# ============================================================================

param(
    [string]$NewServerName = "NEWSERVER01",
    [string]$DomainName = "<INSERT DATA>",
    [string]$OUPath = "OU=Prod-Servers,OU=Servers,DC=<INSERT DATA>",
    [string]$IPAddress,
    [string]$Gateway,
    [pscredential]$DomainCredential,
    [string]$LogPath = "C:\Temp\PostInstall.log"
)

# Setup logging
$logDir = Split-Path $LogPath
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Tee-Object -FilePath $LogPath -Append
}

$stageMarker = "C:\Temp\PostInstall.stage"

# ============================================================================
# STAGE 0: Network Configuration
# ============================================================================
if (-not (Test-Path $stageMarker) -or (Get-Content $stageMarker) -eq "0") {
    Write-Log "STAGE 0: Network configuration"
    
    # Prompt for IP and Gateway if not provided
    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter static IP address"
    }
    if (-not $Gateway) {
        $Gateway = Read-Host "Enter default gateway"
    }
    
    Write-Log "Configuring network: IP=$IPAddress, Gateway=$Gateway, Mask=255.255.255.0"
    
    try {
        # Get the primary network adapter (first one that's connected)
        $adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
        
        if (-not $adapter) {
            Write-Log "ERROR: No active network adapter found" "ERROR"
            exit 1
        }
        
        Write-Log "Found adapter: $($adapter.Name) (InterfaceIndex: $($adapter.InterfaceIndex))"
        
        # Remove existing IP configuration
        Write-Log "Removing existing IP configuration..."
        Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
            Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        
        Get-NetRoute -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue | 
            Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
        
        Start-Sleep -Seconds 2
        
        # Set static IP (PrefixLength 24 = 255.255.255.0)
        Write-Log "Setting static IP: $IPAddress with gateway $Gateway"
        New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex `
            -IPAddress $IPAddress `
            -PrefixLength 24 `
            -DefaultGateway $Gateway | Out-Null
        
        # Set DNS servers
        Write-Log "Setting DNS servers: 10.20.1.19, 10.20.25.17"
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex `
            -ServerAddresses @("10.20.1.19", "10.20.25.17")
        
        Write-Log "Network configuration complete"
        
        # Test connectivity
        Write-Log "Testing DNS resolution..."
        $dnsTest = Resolve-DnsName -Name "google.com" -ErrorAction SilentlyContinue
        if ($dnsTest) {
            Write-Log "DNS working - connectivity verified"
        } else {
            Write-Log "WARNING: DNS test failed, but proceeding" "WARN"
        }
    }
    catch {
        Write-Log "ERROR: Network configuration failed: $_" "ERROR"
        exit 1
    }
    
    "1" | Out-File -FilePath $stageMarker -Force
}

# ============================================================================
# STAGE 1: Rename Server
# ============================================================================
if ((Get-Content $stageMarker) -eq "1") {
    Write-Log "STAGE 1: Starting server rename to $NewServerName"
    
    if ((Get-ComputerInfo).CsComputerName -ne $NewServerName) {
        Rename-Computer -NewName $NewServerName -Force
        Write-Log "Server renamed. Restarting in 30 seconds..."
        
        "2" | Out-File -FilePath $stageMarker -Force
        shutdown.exe /r /t 30 /c "Post-install: Stage 1 complete, proceeding to domain join"
        exit
    } else {
        Write-Log "Server already named $NewServerName, skipping rename"
        "2" | Out-File -FilePath $stageMarker -Force
    }
}

# ============================================================================
# STAGE 2: Domain Join
# ============================================================================
if ((Get-Content $stageMarker) -eq "2") {
    Write-Log "STAGE 2: Starting domain join to $DomainName"
    
    # Prompt for credentials if not provided
    if (-not $DomainCredential) {
        $DomainCredential = Get-Credential -Message "Enter domain admin credentials for $DomainName"
    }
    
    try {
        Add-Computer -DomainName $DomainName `
            -Credential $DomainCredential `
            -Force
        
        Write-Log "Domain join successful. Restarting in 30 seconds..."
        "3" | Out-File -FilePath $stageMarker -Force
        shutdown.exe /r /t 30 /c "Post-install: Stage 2 complete, proceeding to OU move"
        exit
    }
    catch {
        Write-Log "ERROR: Domain join failed: $_" "ERROR"
        exit 1
    }
}

# ============================================================================
# STAGE 3: Move to OU (runs AFTER domain join succeeds)
# ============================================================================
if ((Get-Content $stageMarker) -eq "3") {
    Write-Log "STAGE 3: Moving $NewServerName to OU: $OUPath"
    
    try {
        # Wait for AD to sync
        Start-Sleep -Seconds 10
        
        $computer = Get-ADComputer -Identity $NewServerName -Credential $DomainCredential
        Move-ADObject -Identity $computer.DistinguishedName `
            -TargetPath $OUPath `
            -Credential $DomainCredential
        
        Write-Log "Successfully moved $NewServerName to $OUPath"
    }
    catch {
        Write-Log "ERROR: Failed to move to OU: $_" "ERROR"
        # Non-fatal; continue with other steps
    }
    
    "4" | Out-File -FilePath $stageMarker -Force
}

# ============================================================================
# STAGE 4: System Configuration (No restart required from here)
# ============================================================================
if ((Get-Content $stageMarker) -eq "4") {
    Write-Log "STAGE 4: System configuration and software installation"
    
    # Timezone
    try {
        Set-TimeZone -Name "US Eastern Standard Time"
        Write-Log "Timezone set to US Eastern Standard Time"
    }
    catch {
        Write-Log "WARNING: Could not set timezone: $_" "WARN"
    }
    
    # Ensure software directories exist
    $softwarePaths = @(
        "C:\Users\Administrator\Documents\Post install\Duo",
        "C:\Users\Administrator\Documents\Post install\Tanium",
        "C:\Users\Administrator\Documents\Post install\BGInfo",
        "C:\Users\Administrator\Documents\Post install"
    )
    
    foreach ($path in $softwarePaths) {
        if (-not (Test-Path $path)) {
            Write-Log "WARNING: Software path not found: $path" "WARN"
        }
    }
    
    # Install Duo
    if (Test-Path "C:\Users\Administrator\Documents\Post install\Duo\install64bit.bat") {
        Write-Log "Installing Duo Security..."
        try {
            Start-Process -FilePath "C:\Users\Administrator\Documents\Post install\Duo\install64bit.bat" `
                -ArgumentList "/S" `
                -Wait -NoNewWindow
            Write-Log "Duo Security installed successfully"
        }
        catch {
            Write-Log "ERROR: Duo installation failed: $_" "ERROR"
        }
    } else {
        Write-Log "WARNING: Duo installer not found" "WARN"
    }
    
    # Install Tanium
    if (Test-Path "C:\Users\Administrator\Documents\Post install\Tanium\SetupClient.exe") {
        Write-Log "Installing Tanium..."
        try {
            Start-Process -FilePath "C:\Users\Administrator\Documents\Post install\Tanium\SetupClient.exe" `
                -ArgumentList "/S" `
                -Wait -NoNewWindow
            Write-Log "Tanium installed successfully"
        }
        catch {
            Write-Log "ERROR: Tanium installation failed: $_" "ERROR"
        }
    } else {
        Write-Log "WARNING: Tanium installer not found" "WARN"
    }
    
    # Install BGInfo
    if (Test-Path "C:\Users\Administrator\Documents\Post install\BGInfo\Setup_NonDell.bat") {
        Write-Log "Installing BGInfo..."
        try {
            Start-Process -FilePath "C:\Users\Administrator\Documents\Post install\BGInfo\Setup_NonDell.bat" `
                -ArgumentList "/S" `
                -Wait -NoNewWindow
            Write-Log "BGInfo installed successfully"
        }
        catch {
            Write-Log "ERROR: BGInfo installation failed: $_" "ERROR"
        }
    } else {
        Write-Log "WARNING: BGInfo installer not found" "WARN"
    }
    
    # Install Cortex (MSI)
    if (Test-Path "C:\Users\Administrator\Documents\Post install\cortex.msi") {
        Write-Log "Installing Cortex..."
        try {
            Start-Process -FilePath "msiexec.exe" `
                -ArgumentList "/i `"C:\Users\Administrator\Documents\Post install\cortex.msi`" /S /norestart" `
                -Wait -NoNewWindow
            Write-Log "Cortex installed successfully"
        }
        catch {
            Write-Log "ERROR: Cortex installation failed: $_" "ERROR"
        }
    } else {
        Write-Log "WARNING: Cortex MSI not found" "WARN"
    }
    
    Write-Log "=== POST-INSTALL COMPLETE ==="
    Write-Log "Server ready. Review $LogPath for details."
    
    # Clean up
    Remove-Item $stageMarker -Force
}
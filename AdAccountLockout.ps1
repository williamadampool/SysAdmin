# Quick reference: Event ID 4740 lookup (Account Lockout)

$username = "REPLACE"
# 1. SIMPLE: Last 24 hours on current DC (fastest)
Get-WinEvent -FilterHashtable @{
    LogName      = 'Security'
    ID           = 4740
    StartTime    = (Get-Date).AddHours(-24)
} | Where-Object { $_.Properties[0].Value -like "*username*" } | Format-Table TimeCreated, @{N='User';E={$_.Properties[0].Value}}, @{N='Source';E={$_.Properties[1].Value}} -AutoSize

# 2. FIND SPECIFIC USERNAME (case-insensitive, partial match)
$username = "REPLACE"
Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddHours(-24)
} | Where-Object { $_.Properties[0].Value -like "*$username*" }


# 3. QUERY REMOTE DC (for domain-wide queries)
$dcName = "dc-epw-p-01"
Get-WinEvent -ComputerName $dcName -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddHours(-24)
} | Where-Object { $_.Properties[0].Value -like "*username*" } | Format-List TimeCreated, @{N='User';E={$_.Properties[0].Value}}, @{N='Source';E={$_.Properties[1].Value}}


# 4. PAST 7 DAYS with summary
$username = $username
$events = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddDays(-7)
} | Where-Object { $_.Properties[0].Value -like "*$username*" }

if ($events) {
    Write-Host "Found $($events.Count) lockout events for $username"
    $events | Group-Object { $_.Properties[1].Value } | ForEach-Object {
        Write-Host "  From $($_.Name): $($_.Count) lockouts"
    }
    $events | Format-Table @{N='Time';E={$_.TimeCreated}}, @{N='User';E={$_.Properties[0].Value}}, @{N='Source';E={$_.Properties[1].Value}} -AutoSize
}


# ============================================================================
# ADVANCED: EVENT DATA STRUCTURE
# ============================================================================

# Event 4740 Properties breakdown:
# $_.Properties[0].Value = Target User Name (the locked-out account)
# $_.Properties[1].Value = Source Workstation (where the bad login attempts came from)

# Example - extract and analyze
$username = $username
$events = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddHours(-48)
} | Where-Object { $_.Properties[0].Value -like "*$username*" }

$analysis = $events | ForEach-Object {
    [PSCustomObject]@{
        TimeCreated       = $_.TimeCreated
        LockedOutUser     = $_.Properties[0].Value
        SourceWorkstation = $_.Properties[1].Value
    }
} | Sort-Object TimeCreated -Descending

$analysis | Export-Csv -Path "C:\temp\lockout_analysis.csv" -NoTypeInformation


# ============================================================================
# TROUBLESHOOTING: FIND REPEAT OFFENDERS
# ============================================================================

# What source workstations are locking out users most?
Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddDays(-7)
} | Group-Object { $_.Properties[1].Value } | Sort-Object Count -Descending | Format-Table Count, Name


# Which users are locked out most frequently?
Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddDays(-7)
} | Group-Object { $_.Properties[0].Value } | Sort-Object Count -Descending | Format-Table Count, Name


# ============================================================================
# EXPORT FOR ANALYSIS
# ============================================================================

# Build a detailed CSV report
$events = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    ID        = 4740
    StartTime = (Get-Date).AddDays(-7)
}

$report = $events | ForEach-Object {
    [PSCustomObject]@{
        TimeCreated        = $_.TimeCreated
        ComputerName       = $_.MachineName
        EventID            = $_.ID
        LockedOutUser      = $_.Properties[0].Value
        SourceWorkstation  = $_.Properties[1].Value
    }
} | Sort-Object TimeCreated -Descending

$report | Export-Csv -Path "C:\temp\Event4740_Report_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
Write-Host "Report saved to C:\temp\Event4740_Report_$(Get-Date -Format yyyyMMdd).csv"


# ============================================================================
# REAL-TIME MONITORING (while troubleshooting)
# ============================================================================

# Watch for lockouts as they happen (run in separate PowerShell window)
Write-Host "Monitoring for Event 4740... (Press Ctrl+C to stop)" -ForegroundColor Yellow
while ($true) {
    $latest = Get-WinEvent -FilterHashtable @{
        LogName   = 'Security'
        ID        = 4740
        StartTime = (Get-Date).AddSeconds(-30)
    } -ErrorAction SilentlyContinue
    
    if ($latest) {
        $latest | ForEach-Object {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] User: $($_.Properties[0].Value) locked out from: $($_.Properties[1].Value)" -ForegroundColor Red
        }
    }
    
    Start-Sleep -Seconds 5
}
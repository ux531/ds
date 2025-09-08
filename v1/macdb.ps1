<#
.SYNOPSIS
Search employee records in CSVs (test DB).
.DESCRIPTION
- Accepts either 1 argument (global search) or 2 arguments (location + ID).
- Checks both ID and SID columns.
#>

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Args,

    [string]$DatabaseDir = "./test_db"
)

if ($Args.Count -eq 1) {
    $searchMode = "global"
    $searchId   = $Args[0]
}
elseif ($Args.Count -eq 2) {
    $searchMode = "local"
    $location   = $Args[0]
    $searchId   = $Args[1]
}
else {
    Write-Host "Usage:"
    Write-Host "  ./macdb.ps1 EMPLOYEE_ID"
    Write-Host "  ./macdb.ps1 LOCATION EMPLOYEE_ID"
    exit
}

Write-Host "`n=== Employee Lookup ===`n"

$results = @()

if ($searchMode -eq "local") {
    $file = Join-Path $DatabaseDir "$location.csv"
    if (-Not (Test-Path $file)) {
        Write-Host "Location $location not found."
        exit
    }
    $rows = Import-Csv -Path $file
    $matches = $rows | Where-Object { $_.ID -eq $searchId -or $_.SID -eq $searchId }
    foreach ($m in $matches) {
        $results += [PSCustomObject]@{
            Location = $location
            ID       = $m.ID
            SID      = $m.SID
            JOB_DEF  = $m.JOB_DEF
            FILIAL   = $m.FILIAL
            COMMENT  = $m.COMMENT
        }
    }
}
else {
    Get-ChildItem -Path $DatabaseDir -Filter "*.csv" | ForEach-Object {
        $loc = $_.BaseName
        $rows = Import-Csv -Path $_.FullName
        $matches = $rows | Where-Object { $_.ID -eq $searchId -or $_.SID -eq $searchId }
        foreach ($m in $matches) {
            $results += [PSCustomObject]@{
                Location = $loc
                ID       = $m.ID
                SID      = $m.SID
                JOB_DEF  = $m.JOB_DEF
                FILIAL   = $m.FILIAL
                COMMENT  = $m.COMMENT
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No matching employee found."
}
else {
    $results | Format-Table -AutoSize
    Write-Host "`nTotal locations found: $($results.Count)`n"
}

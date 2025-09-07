<#
.SYNOPSIS
Polished cross-platform employee lookup for CSV “tables”

.DESCRIPTION
- Each CSV file in the folder represents a location
- Columns: TempID, ID, JOB_DEF, FILIAL, COMMENT
- Multi-keyword search with weighted scoring
- Index-style output for multiple results with headers
.PARAMETER Query
Space-separated keywords (ID, TempID, JOB_DEF, FILIAL, COMMENT)
.PARAMETER DatabaseDir
Folder containing CSV files (default: ./test_db)
#>

param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Query,

    [string]$DatabaseDir = "./test_db"
)

if (-not (Test-Path $DatabaseDir)) {
    Write-Host "Database folder not found: $DatabaseDir"
    exit
}

$results = @()
$keywords = $Query | ForEach-Object { $_.ToLower() }

# Loop over CSV files (locations)
Get-ChildItem -Path $DatabaseDir -Filter "*.csv" | ForEach-Object {
    $csvFile = $_.FullName
    $location = $_.BaseName

    $data = Import-Csv -Path $csvFile
    foreach ($row in $data) {
        $score = 0
        foreach ($kw in $keywords) {
            if ($row.ID -match $kw)       { $score += 5 }
            if ($row.TempID -match $kw)   { $score += 5 }
            if ($row.JOB_DEF -match $kw)  { $score += 3 }
            if ($row.FILIAL -match $kw)   { $score += 2 }
            if ($row.COMMENT -match $kw)  { $score += 1 }
        }

        if ($score -gt 0) {
            $results += [PSCustomObject]@{
                Location = $location
                TempID   = $row.TempID
                ID       = $row.ID
                JOB_DEF  = $row.JOB_DEF
                FILIAL   = $row.FILIAL
                COMMENT  = $row.COMMENT
                Score    = $score
            }
        }
    }
}

# Sort descending by Score, then by Location
$sortedResults = $results | Sort-Object @{Expression='Score';Descending=$true}, @{Expression='Location';Descending=$false}

if ($sortedResults.Count -eq 0) {
    Write-Host "No records found matching query: $($Query -join ' ')"
} else {
    Write-Host "`n=== Employee Job Definitions ===`n"

    $isTopMatch = $true
    $locationSummary = @{}

    foreach ($r in $sortedResults) {
        $header = if ($isTopMatch) { "--- Candidate 1 (Top Match) 🏆 (Score: $($r.Score)) ---"; $isTopMatch=$false } 
                  else { "--- Candidate (Score: $($r.Score)) ---" }

        Write-Host $header
        Write-Host ("Location    : {0}" -f $r.Location)
        Write-Host ("TempID      : {0}" -f $r.TempID)
        Write-Host ("ID          : {0}" -f $r.ID)
        Write-Host ("JOB_DEF     : {0}" -f $r.JOB_DEF)
        Write-Host ("FILIAL      : {0}" -f $r.FILIAL)
        Write-Host ("COMMENT     : {0}" -f $r.COMMENT)
        Write-Host "-------------------------------------"

        # Collect location summary
        if ($locationSummary.ContainsKey($r.Location)) {
            $locationSummary[$r.Location]++
        } else {
            $locationSummary[$r.Location] = 1
        }
    }

    Write-Host "`nLocations matched: $($locationSummary.Keys -join ', ')"
    Write-Host "Total matches: $($sortedResults.Count)"
}

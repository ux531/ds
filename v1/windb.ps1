# Sort by Score descending
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

    # Optional: location summary
    Write-Host "`nLocations matched: $($locationSummary.Keys -join ', ')"
    Write-Host "Total matches: $($sortedResults.Count)"
}

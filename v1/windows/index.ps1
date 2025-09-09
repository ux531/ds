<#
================================================================================
SCRIPT: index.ps1
DESCRIPTION:
Fast PowerShell CSV search with:
- Multi-word arguments without quotes
- Clipboard fallback
- Manual input fallback
- Line-by-line CSV reading for speed
- Scoring like original Bash script
================================================================================
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Query,
    [string]$DatabaseDir = "./database",
    [string]$ProceduresDir = "./procedures"
)

# --- Input Handling ---
if ($Query -and $Query.Count -gt 0) {
    # Join all provided arguments into one phrase
    $Query = $Query -join " "
} else {
    try { $Query = Get-Clipboard } catch { $Query = "" }
    if ([string]::IsNullOrWhiteSpace($Query)) {
        $Query = Read-Host "No query provided. Please paste/type your phrase"
    }
}

# --- Normalize Query ---
$text = $Query.ToLower() -replace '[|,;]', ' ' -replace '\s+', ' ' -replace '^\s+|\s+$', ''
$words = $text -split '\s+'

Write-Host "=== Query words ==="
$words | ForEach-Object { Write-Host $_ }
Write-Host "===================`n"

$keywordsForRegex = ($words -join "|")
$phrasePattern = [Regex]::Escape(($words -join " ")) -replace ' ', '.*'

# --- Sequential Search (line-by-line for speed) ---
$results = @()

Get-ChildItem -Path $DatabaseDir -Filter "*.csv" | ForEach-Object {
    $file = $_.FullName
    $reader = [System.IO.StreamReader]::new($file)
    $headerLine = $reader.ReadLine()
    $delimiter = if ($headerLine -match ";") { ";" } else { "," }
    $headers = $headerLine.Split($delimiter)

    while (-not $reader.EndOfStream) {
        $line = $reader.ReadLine()
        $fields = $line.Split($delimiter)
        $row = @{}
        for ($i = 0; $i -lt $headers.Count; $i++) {
            $row[$headers[$i].Trim()] = if ($i -lt $fields.Count) { $fields[$i] } else { "" }
        }

        # --- Scoring ---
        $baseScore = 0
        $fieldBonus = 0
        $phraseBonus = 0
        $matchedWords = @{}

        $fullLineText = ($row.Values -join " ").ToLower()

        foreach ($fieldValue in $row.Values) {
            $fieldValue = $fieldValue.ToLower()
            $fieldMatches = 0
            foreach ($kw in $keywordsForRegex -split '\|') {
                if ($kw -and $fieldValue -match [Regex]::Escape($kw)) {
                    $baseScore++
                    $fieldMatches++
                    if ($matchedWords.ContainsKey($kw)) { $matchedWords[$kw]++ } else { $matchedWords[$kw] = 1 }
                }
            }
            if ($fieldMatches -gt 1) { $fieldBonus += $fieldMatches }
        }

        if ($fullLineText -match $phrasePattern) { $phraseBonus = 100 }

        $totalScore = $baseScore + $fieldBonus + $phraseBonus
        if ($totalScore -gt 0) {
            $results += [PSCustomObject]@{
                Score        = $totalScore
                MatchedWords = ($matchedWords.GetEnumerator() | ForEach-Object { "$($_.Key) ($($_.Value))" }) -join ", "
                File         = $file
                Row          = $row
                Delimiter    = $delimiter
            }
        }
    }
    $reader.Close()
}

$results = $results | Sort-Object Score -Descending | Select-Object -First 3

# --- Print Results ---
if (-not $results) { Write-Host "No matching suggestions found."; exit }

$firstProcedureId = $null
$isTop = $true

foreach ($res in $results) {
    Write-Host "### Processing file: $($res.File) ###"

    if ($isTop) {
        Write-Host ("--- Candidate 1 (Top Match) 🏆 (Score: {0}) ---" -f $res.Score) -ForegroundColor Cyan
        $isTop = $false
    } else {
        Write-Host ("--- Candidate (Score: {0}) ---" -f $res.Score)
    }

    Write-Host "Matched keywords: $($res.MatchedWords)"

    foreach ($header in $res.Row.Keys) {
        $val = $res.Row[$header]
        if (-not $val) { $val = "N/A" }
        $val = $val -replace '^"|"$',''
        "{0,-12}: {1}" -f $header, $val
        if ($header -eq "procedure_id" -and -not $firstProcedureId) {
            $firstProcedureId = $val
        }
    }
    Write-Host "-------------------------------------"
}

# --- Procedure Lookup ---
if ($firstProcedureId) {
    $key = Read-Host "Press Enter to view the procedure or type anything else to exit"
    if (-not $key) {
        $procFile = Get-ChildItem -Path $ProceduresDir -File | Select-Object -First 1
        if ($procFile) {
            $procedureText = Get-Content -Path $procFile | ForEach-Object {
                $parts = $_ -split ';',2
                if ($parts[0] -eq $firstProcedureId) {
                    $parts[1] -replace '\\n',"`n" -replace '^"|"$',''
                }
            }
            if ($procedureText) {
                Write-Host "`n### ✅ Procedure Found: $firstProcedureId ###`n"
                Write-Host $procedureText
                Write-Host "-------------------------------------"
            }
        }
    }
}

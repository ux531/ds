# ==============================================================================
# SCRIPT: index.ps1
# PURPOSE:
#   Search for the best matching procedures from procedures.json
#   based on input text (from clipboard or command-line arguments).
#
#   Supports Unicode (Cyrillic + English) input, preserving original Markdown step formatting.
#
#   Uses a weighted search system:
#     - [pn], [kw], [pr] dominate the score (high weight)
#     - Step text and [ext] sections contribute lightly (low weight)
#     - [re] sections are stored but not scored
#
# INPUT:
#   - Argument(s): ./index.ps1 "search text"
#   - Clipboard: if no arguments provided, it will use clipboard content
#
# OUTPUT:
#   - Top 3 candidate procedures are displayed with scores
#   - Optionally shows full procedure details of top candidate
#
# ==============================================================================
# --- Ensure UTF-8 output for console (handles Cyrillic + special characters) ---

# --- Encoding Fix ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProceduresJson = ".\procedures.json"

if (-not (Test-Path $ProceduresJson)) {
    Write-Host "❌ File not found: $ProceduresJson"
    exit 1
}

# --- Input Handling ---
if ($args.Count -gt 0 -and $args[0].Trim() -ne "") {
    $text = $args -join " "
} else {
    try {
        $text = Get-Clipboard
        if ([string]::IsNullOrWhiteSpace($text)) {
            Write-Host "❌ No input provided (args or clipboard)."
            exit 0
        }
    } catch {
        Write-Host "❌ No input provided (args or clipboard)."
        exit 0
    }
}

# --- Normalize Input Words ---
$text = $text -replace '[|,;]+', " "
$text = $text -replace '[–—]', '-'   # Convert EN DASH / EM DASH to standard hyphen
$words = $text -split '\s+' | Where-Object { $_ -ne "" }

Write-Host "=== Filtered input words ==="
$words | ForEach-Object { Write-Host $_ }
Write-Host "===========================`n"

# --- Load Procedures ---
$json = Get-Content -Raw -Encoding UTF8 -Path $ProceduresJson | ConvertFrom-Json
if (-not $json.procedures) {
    Write-Host "❌ No procedures found in JSON."
    exit 0
}

$results = @()

foreach ($proc in $json.procedures) {
    $score = 0
    $matched = @()

    # --- Priority fields: [pn], [kw], [pr] ---
    $priorityFields = @()
    if ($proc.PSObject.Properties.Name -contains 'name') { $priorityFields += $proc.name }
    if ($proc.PSObject.Properties.Name -contains 'keywords' -and $proc.keywords) { $priorityFields += ($proc.keywords -split ';') }
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            if ($section.PSObject.Properties.Name -contains 'pr' -and $section.pr) {
                $priorityFields += $section.pr
            }
        }
    }

    foreach ($w in $words) {
        $wNorm = $w.ToLowerInvariant()
        foreach ($f in $priorityFields) {
            if ($f -and ($f.ToLowerInvariant() -like "*$wNorm*")) {
                $score += 90
                $matched += $w
            }
        }
    }

    # --- Lower-weight matches: steps, replies ---
    $fields = @($proc.name)
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            if ($section.PSObject.Properties.Name -contains 'reply' -and $section.reply) { $fields += $section.reply }
            if ($section.steps) { $fields += $section.steps }
        }
    }

    foreach ($w in $words) {
        $wNorm = $w.ToLowerInvariant()
        foreach ($f in $fields) {
            if ($f -is [string] -and $f -like "*$wNorm*") { $score += 1; $matched += $w }
            elseif ($f -is [array]) {
                foreach ($substep in $f) {
                    if ($substep -like "*$wNorm*") { $score += 1; $matched += $w }
                }
            }
        }
    }

    if ($score -gt 0) {
        $results += [PSCustomObject]@{
            Name = $proc.name
            Score = $score
            Matched = ($matched | Sort-Object -Unique) -join ", "
            Proc = $proc
        }
    }
}

$results = $results | Sort-Object Score -Descending | Select-Object -First 3
if (-not $results) {
    Write-Host "❌ No matching procedures found."
    exit 0
}

# --- Display Top Candidates ---
Write-Host "=== Top Candidates ==="
$first_match = $results[0].Name
foreach ($r in $results) {
    if ($r.Name -eq $first_match) {
        Write-Host ("--- Candidate 1 (Top Match) 🏆 (Score: {0}) ---" -f $r.Score) -ForegroundColor Cyan
    } else {
        Write-Host ("--- Candidate (Score: {0}) ---" -f $r.Score)
    }
    Write-Host "Name: $($r.Name)"
    Write-Host "Matched: $($r.Matched)"
    Write-Host "-------------------------------------"
}

# --- Show Procedure for Top Candidate ---
if ($first_match) {
    $userInput = Read-Host "Press Enter to show procedure for '$first_match' (or type anything to exit)"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $proc = $results[0].Proc
        Write-Host "`n### ✅ Procedure Found: $($proc.name) ###`n"
        foreach ($section in $proc.sections) {
            if ($section.steps -and $section.steps.Count -gt 0) {
                $sectionLabel = if ($section.PSObject.Properties.Name -contains 'reply') { $section.reply } else { $section.name }
                Write-Host "Section: $sectionLabel"
                foreach ($step in $section.steps) {
                    Write-Host "$step"
                }
                Write-Host ""
            }
        }
    }
}

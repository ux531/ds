# ==============================================================================
# SCRIPT: index.ps1
# DESCRIPTION:
# Searches inside procedures.json for the best matching procedures based on
# keywords, section reply fields, and step text. Supports Unicode input (Cyrillic + English).
# Shows the top 3 candidates and allows the user to view the top candidate's full procedure.
# Preserves original step formatting, including leading - where present.
# ==============================================================================

# --- Encoding Fix ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProceduresJson = ".\procedures.json"

if (-not (Test-Path $ProceduresJson)) {
    Write-Host "❌ File not found: $ProceduresJson"
    exit 1
}

# --- Input Handling ---
if ($args.Count -gt 0) {
    $text = $args -join " "
} else {
    try {
        $text = Get-Clipboard
    } catch {
        Write-Host "❌ No input provided (args or clipboard)."
        exit 0
    }
}

# --- Normalize Input Words ---
$text = $text -replace '[|,;]+', " "
$words = $text -split '\s+' | Where-Object { $_ -ne "" }
Write-Host "=== Filtered input words ==="
$words | ForEach-Object { Write-Host $_ }
Write-Host "===========================`n"

# --- Load Procedures (UTF-8 Safe) ---
$json = Get-Content -Raw -Encoding UTF8 -Path $ProceduresJson | ConvertFrom-Json
if (-not $json.procedures) {
    Write-Host "❌ No procedures found in JSON."
    exit 0
}

$results = @()
foreach ($proc in $json.procedures) {
    $score = 0
    $matched = @()

    # --- Collect keywords from all sections ---
    $keywords = @()
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            if ($section.PSObject.Properties.Name -contains 'keywords' -and $section.keywords) {
                $keywords += ($section.keywords -split ';')
            }
        }
    }

    # --- Collect searchable fields ---
    $fields = @($proc.name)
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            if ($section.PSObject.Properties.Name -contains 'reply' -and $section.reply) {
                $fields += $section.reply
            }
            foreach ($step in $section.steps) {
                if ($step -is [string]) {
                    $fields += $step
                } elseif ($step.PSObject.Properties.Name -contains 'title') {
                    $fields += $step.title
                    $fields += $step.steps
                }
            }
        }
    }

    # --- Matching ---
    foreach ($w in $words) {
        $wNorm = $w.ToLowerInvariant()
        # Keyword matches (high weight)
        foreach ($k in $keywords) {
            $kNorm = $k.ToLowerInvariant()
            if ($kNorm -like "*$wNorm*") {
                $score += 100
                $matched += $w
            }
        }
        # Field matches (low weight)
        foreach ($f in $fields) {
            if ($f -is [string] -and $f) {
                $fNorm = $f.ToLowerInvariant()
                if ($fNorm -like "*$wNorm*") {
                    $score += 1
                    $matched += $w
                }
            } elseif ($f -is [array]) {
                foreach ($substep in $f) {
                    $substepNorm = $substep.ToLowerInvariant()
                    if ($substepNorm -like "*$wNorm*") {
                        $score += 1
                        $matched += $w
                    }
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

# --- Show Procedure for the Top Candidate ---
if ($first_match) {
    $userInput = Read-Host "Press Enter to show procedure for '$first_match' (or type anything to exit)"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $proc = $results[0].Proc
        Write-Host "`n### ✅ Procedure Found: $($proc.name) ###`n"
        foreach ($section in $proc.sections) {
            $sectionLabel = if ($section.PSObject.Properties.Name -contains 'reply') { $section.reply -replace '^# ', '' }
                           elseif ($section.PSObject.Properties.Name -contains 'keywords') { "Keywords" }
                           else { "Procedure" }
            Write-Host "Section: $sectionLabel"
            $isSublist = $section.PSObject.Properties.Name -contains 'reply' -and $section.reply -match '^# '
            if ($isSublist) {
                # Treat as sublist under Procedure
                Write-Host "  $sectionLabel"
                foreach ($step in $section.steps) {
                    Write-Host "    $step"
                }
            } else {
                foreach ($step in $section.steps) {
                    if ($step -is [string]) {
                        Write-Host "$step"
                    } elseif ($step.PSObject.Properties.Name -contains 'title') {
                        Write-Host "  $($step.title)"
                        foreach ($substep in $step.steps) {
                            if ($substep -is [string]) {
                                Write-Host "    $substep"
                            } elseif ($substep -is [array]) {
                                foreach ($nestedStep in $substep) {
                                    Write-Host "      $nestedStep"
                                }
                            }
                        }
                    }
                }
            }
            Write-Host ""
        }
    }
}

# ==============================================================================
# Notes:
# - Fully Unicode-safe (Cyrillic + English)
# - JSON loaded with UTF-8 to avoid garbled text
# - Console output forced to UTF-8
# - Search uses ToLowerInvariant() + -like for matching
# - Preserves original step formatting, including leading - where present
# - Handles reply sections starting with # as sublists under Procedure
# ==============================================================================
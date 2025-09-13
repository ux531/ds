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
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProceduresJson = ".\procedures.json"

# --- Check that the JSON file exists ---
if (-not (Test-Path $ProceduresJson)) {
    Write-Host "❌ File not found: $ProceduresJson"
    exit 1
}

# --- Get input text ---
if ($args.Count -gt 0) {
    # Use command-line arguments if provided
    $text = $args -join " "
} else {
    try {
        # Otherwise, get text from clipboard
        $text = Get-Clipboard
    } catch {
        Write-Host "❌ No input provided (args or clipboard)."
        exit 0
    }
}

# --- Normalize input: remove separators and split into words ---
$text = $text -replace '[|,;]+', " "
$words = $text -split '\s+' | Where-Object { $_ -ne "" }

Write-Host "=== Filtered input words ==="
$words | ForEach-Object { Write-Host $_ }
Write-Host "===========================`n"

# --- Load procedures.json ---
$json = Get-Content -Raw -Encoding UTF8 -Path $ProceduresJson | ConvertFrom-Json
if (-not $json.procedures) {
    Write-Host "❌ No procedures found in JSON."
    exit 0
}

# --- Initialize results array ---
$results = @()

foreach ($proc in $json.procedures) {
    $score = 0           # Total relevance score for this procedure
    $matched = @()       # Words that matched for display

    # --- Collect high-weight keywords ([pn], [kw], [pr]) ---
    $keywords = @()
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            if ($section.PSObject.Properties.Name -contains 'keywords' -and $section.keywords) {
                $keywords += ($section.keywords -split ';')
            }
        }
    }

    # --- Collect fields for low-weight matching (step text, [ext], reply text) ---
    $fields = @($proc.name)
    if ($proc.sections) {
        foreach ($section in $proc.sections) {
            # [re] reply sections
            if ($section.PSObject.Properties.Name -contains 'reply' -and $section.reply) {
                $fields += $section.reply
            }
            # Steps (including [ext] / Extra)
            foreach ($step in $section.steps) {
                if ($step -is [string]) {
                    $fields += $step
                } elseif ($step.PSObject.Properties.Name -contains 'title') {
                    # Nested steps under a title
                    $fields += $step.title
                    $fields += $step.steps
                }
            }
        }
    }

    # --- Matching logic ---
    foreach ($w in $words) {
        $wNorm = $w.ToLowerInvariant()

        # --- High weight: keywords match (~100 points) ---
        foreach ($k in $keywords) {
            $kNorm = $k.ToLowerInvariant()
            if ($kNorm -like "*$wNorm*") {
                $score += 100
                $matched += $w
            }
        }

        # --- Low weight: step text, [ext], reply text (~1 point) ---
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

    # --- If any matches found, store the result ---
    if ($score -gt 0) {
        $results += [PSCustomObject]@{
            Name    = $proc.name
            Score   = $score
            Matched = ($matched | Sort-Object -Unique) -join ", "
            Proc    = $proc
        }
    }
}

# --- Sort results descending and take top 3 ---
$results = $results | Sort-Object Score -Descending | Select-Object -First 3
if (-not $results) {
    Write-Host "❌ No matching procedures found."
    exit 0
}

# --- Display top candidates ---
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

# --- Show full procedure for top candidate ---
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
# NOTES:
# - Fully Unicode-safe (Cyrillic + English)
# - Keywords ([pn], [kw], [pr]) dominate the score
# - [ext] sections are included in low-weight matching
# - [re] sections are captured but not scored
# - Step formatting is preserved exactly as in Markdown
# - Clipboard or command-line input is supported
# - Outputs top 3 candidates and full procedure optionally
# ==============================================================================

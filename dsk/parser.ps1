param(
    [string]$mdFile = "./procedures.md",
    [string]$jsonFile = "./procedures.json"
)

# Debug: Verify file exists
if (-not (Test-Path $mdFile)) {
    Write-Host "Error: Input file $mdFile not found."
    exit
}

# Read the Markdown
$content = Get-Content $mdFile -Raw -Encoding UTF8
Write-Host "Debug: Raw content length: $($content.Length)"

# Split by procedure blocks
$blocks = $content -split '(?s)(?<=--- # close procedure)|(?=--- # open procedure)' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
Write-Host "Debug: Found $($blocks.Count) blocks"

$procedures = @()

foreach ($block in $blocks) {
    Write-Host "Debug: Processing block: $($block.Substring(0, [Math]::Min($block.Length, 50)))..."

    # Skip if block doesn't contain open procedure
    if ($block -notmatch '--- # open procedure') { continue }

    # Remove closing wrapper
    $block = $block -replace '---\s*# close procedure\s*', ''
    $lines = $block -split '\r?\n'
    
    $procName = ""
    $procID = ""
    $sections = @()
    $currentSection = $null
    $currentSublist = $null
    $currentNestedList = $null

    foreach ($line in $lines) {
        $lineTrim = $line.Trim()
        Write-Host "Debug: Line: $lineTrim"

        # Skip empty lines
        if (-not $lineTrim) { continue }

        # Procedure name
        if ($lineTrim -match '^##\s*(.+?)\s*$' -and -not $procName) {
            $procName = $matches[1].Trim()
            Write-Host "Debug: Set procedure name: $procName"
            continue
        }

        # Procedure ID
        if ($lineTrim -match '^####\s*(PR\d+)\s*$' -and -not $procID) {
            $procID = $matches[1].Trim()
            Write-Host "Debug: Set procedure ID: $procID"
            continue
        }

        # Keywords
        if ($lineTrim -match '^###\s*Keywords:\s*(.+?)\s*$') {
            $currentSection = [PSCustomObject]@{
                keywords = $matches[1].Trim()
                steps = @()
            }
            $sections += $currentSection
            $currentSublist = $null
            $currentNestedList = $null
            Write-Host "Debug: Started keywords section: $($matches[1].Trim())"
            continue
        }

        # [re] or Email шаблони section
        if ($lineTrim -match '^###\s*(?:\[re\]\s*)?(.+?)\s*$' -and $lineTrim -notmatch '^###\s*Procedure\s*$') {
            $currentSection = [PSCustomObject]@{
                reply = $matches[1].Trim()
                steps = @()
            }
            $sections += $currentSection
            $currentSublist = $null
            $currentNestedList = $null
            Write-Host "Debug: Started reply section: $($matches[1].Trim())"
            continue
        }

        # Procedure section
        if ($lineTrim -match '^###\s*Procedure\s*$') {
            $currentSection = [PSCustomObject]@{
                steps = @()
            }
            $sections += $currentSection
            $currentSublist = $null
            $currentNestedList = $null
            Write-Host "Debug: Started procedure section"
            continue
        }

        # Sublist header (####)
        if ($lineTrim -match '^####\s*(.+?)\s*$' -and $currentSection) {
            $currentSublist = [PSCustomObject]@{
                title = $matches[1].Trim()
                steps = @()
            }
            $currentSection.steps += $currentSublist
            $currentNestedList = $null
            Write-Host "Debug: Started sublist: $($matches[1].Trim())"
            continue
        }

        # Handle steps
        if ($currentSection -and $lineTrim -notmatch '^###|^##|^####') {
            $indent = ($line -replace '\S.*').Length / 2  # Count spaces, divide by 2 for indent level
            
            # Preserve original step text, including leading - or >
            if ($indent -ge 2 -and $currentSublist) {
                # Nested list (e.g., under За отговорник офис)
                if (-not $currentNestedList) {
                    $currentNestedList = @()
                    $currentSublist.steps += $currentNestedList
                }
                $currentNestedList += $lineTrim
                Write-Host "Debug: Added nested step: $lineTrim (indent: $indent)"
            } elseif ($indent -ge 1 -and $currentSublist) {
                # Sublist step
                $currentSublist.steps += $lineTrim
                $currentNestedList = $null
                Write-Host "Debug: Added sublist step: $lineTrim (indent: $indent)"
            } elseif ($currentSection) {
                # Regular step
                $currentSection.steps += $lineTrim
                $currentSublist = $null
                $currentNestedList = $null
                Write-Host "Debug: Added step: $lineTrim (indent: $indent)"
            }
        }
    }

    # Build procedure object
    if ($procName -and $procID -and $sections.Count -gt 0) {
        $procedures += [PSCustomObject]@{
            name = $procName
            id = $procID
            sections = $sections
        }
        Write-Host "Debug: Added procedure: $procName ($procID) with $($sections.Count) sections"
    } else {
        Write-Host "Debug: Skipped procedure. Name: $procName, ID: $procID, Sections: $($sections.Count)"
    }
}

# Wrap in root object and save
$json = [PSCustomObject]@{
    procedures = $procedures
}
$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $jsonFile -Encoding UTF8
Write-Host "Conversion complete. JSON written to $jsonFile"
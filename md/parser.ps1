# parser.ps1 - Convert Markdown procedures to JSON

param(
    [string]$mdFile = "./procedures.md",
    [string]$jsonFile = "./procedures.json"
)

# Read the Markdown
$content = Get-Content $mdFile -Raw -Encoding UTF8

# Split by --- wrappers (each block is one procedure)
$blocks = $content -split '---' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

$procedures = @()

foreach ($block in $blocks) {
    $lines = $block -split "`r?`n"

    $procedureName = ""
    $steps = @()
    $keywords = ""

    foreach ($line in $lines) {
        $lineTrim = $line.Trim()

        # Procedure name (##)
        if ($lineTrim -match '^##\s*(.+)$') {
            $procedureName = $matches[1].Trim()
            continue
        }

        # Steps header (### Procedure)
        if ($lineTrim -match '^###\s*Procedure$') { continue }

        # Keywords header (### or #### Keywords:)
        if ($lineTrim -match '^#{3,4}\s*Keywords:\s*(.+)$') {
            $keywords = $matches[1].Trim()
            continue
        }

        # Skip empty lines
        if ($lineTrim -eq "") { continue }

        # Everything else is a step
        $steps += $lineTrim
    }

    if ($procedureName -ne "") {
        $procedures += [PSCustomObject]@{
            name = $procedureName
            sections = @(
                [PSCustomObject]@{
                    keywords = $keywords
                    steps = $steps
                }
            )
        }
    }
}

# Wrap in root object
$json = [PSCustomObject]@{
    procedures = $procedures
}

# Save JSON
$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $jsonFile -Encoding UTF8

Write-Host "Conversion complete. JSON written to $jsonFile"

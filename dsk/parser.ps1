param(
    [string]$mdFile = "./procedures.md",
    [string]$jsonFile = "./procedures.json"
)

if (-not (Test-Path $mdFile)) {
    Write-Host "Error: Input file $mdFile not found."
    exit
}

$lines = Get-Content $mdFile -Encoding UTF8
Write-Host "Debug: Read $($lines.Count) lines."

$procedures = @()
$currentProcedure = $null
$currentSection = $null
$inProcedureBlock = $false
$currentMarker = ""

foreach ($line in $lines) {
    $trim = $line.Trim()

    # Start/end of block
    if ($trim -eq '--- >') {
        $currentProcedure = [PSCustomObject]@{
            name = ""
            id = ""
            keywords = ""
            sections = @()
        }
        $inProcedureBlock = $true
        $currentSection = $null
        $currentMarker = ""
        continue
    }
    if ($trim -eq '--- <') {
        if ($currentProcedure) {
            $procedures += $currentProcedure
        }
        $currentProcedure = $null
        $currentSection = $null
        $inProcedureBlock = $false
        $currentMarker = ""
        continue
    }
    if (-not $inProcedureBlock -or $trim -eq "") { continue }

    # Detect markers
    if ($trim -match '^\s*##\s*\[pn\]\s*(.+)$') {
        $currentProcedure.name = $matches[1].Trim()
        $currentMarker = "[pn]"
        $currentSection = $null
        continue
    }
    if ($trim -match '^\s*###\s*\[kw\]\s*Keywords:\s*(.+)$') {
        $currentProcedure.keywords = $matches[1].Trim()
        $currentMarker = "[kw]"
        $currentSection = $null
        continue
    }
    if ($trim -match '^\s*####\s*\[id\]\s*(.+)$') {
        $currentProcedure.id = $matches[1].Trim()
        $currentMarker = "[id]"
        $currentSection = $null
        continue
    }
    if ($trim -match '^\s*###\s*\[pr\]\s*(.+)?$') {
        $currentSection = [PSCustomObject]@{
            steps = @()
        }
        $currentProcedure.sections += $currentSection
        $currentMarker = "[pr]"
        continue
    }
    if ($trim -match '^\s*###\s*\[re\]\s*(.+)?$') {
        $currentSection = [PSCustomObject]@{
            reply = if ($matches[1]) { $matches[1].Trim() } else { "Reply" }
            steps = @()
        }
        $currentProcedure.sections += $currentSection
        $currentMarker = "[re]"
        continue
    }
    if ($trim -match '^\s*###\s*\[ext\]\s*(.+)?$') {
        $currentSection = [PSCustomObject]@{
            ext = if ($matches[1]) { $matches[1].Trim() } else { "Extra" }
            steps = @()
        }
        $currentProcedure.sections += $currentSection
        $currentMarker = "[ext]"
        continue
    }

    # Add lines to the current section based on marker
    if ($currentSection) {
        switch ($currentMarker) {
            "[pr]" {
                if ($trim -ne "") { $currentSection.steps += $trim }
            }
            "[re]" {
                # Capture all lines as steps, even without "-" bullets
                if ($trim -ne "") { $currentSection.steps += $trim }
            }
            "[ext]" {
                if ($trim -ne "") { $currentSection.steps += $trim }
            }
        }
    }
}

# Save JSON
$json = [PSCustomObject]@{
    procedures = $procedures
}
$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $jsonFile -Encoding UTF8
Write-Host "Conversion complete. JSON written to $jsonFile"

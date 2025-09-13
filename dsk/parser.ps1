param(
    [string]$mdFile = "./procedures.md",
    [string]$jsonFile = "./procedures.json"
)

if (-not (Test-Path $mdFile)) {
    Write-Host "Error: Input file $mdFile not found."
    exit
}

$lines = Get-Content $mdFile -Encoding UTF8
$procedures = @()
$currentProcedure = $null
$currentSection = $null
$inBlock = $false

foreach ($line in $lines) {
    $trim = $line.Trim()

    # Start of block
    if ($trim -eq '--- >') {
        $inBlock = $true
        $currentProcedure = [PSCustomObject]@{
            name = ""
            id = ""
            keywords = ""
            sections = @()
        }
        $currentSection = $null
        continue
    }

    # End of block
    if ($trim -eq '--- <') {
        $inBlock = $false
        if ($currentProcedure) {
            $procedures += $currentProcedure
        }
        $currentProcedure = $null
        $currentSection = $null
        continue
    }

    if (-not $inBlock -or $trim -eq "") { continue }

    # Detect markers
    if ($trim -match '^\s*##\s*\[pn\]\s*(.+)$') {
        $currentProcedure.name = $matches[1].Trim()
        continue
    }
    if ($trim -match '^\s*##*\s*\[kw\]\s*Keywords:\s*(.+)$') {
        $currentProcedure.keywords = $matches[1].Trim()
        continue
    }
    if ($trim -match '^\s*####\s*\[id\]\s*(.+)$') {
        $currentProcedure.id = $matches[1].Trim()
        continue
    }

    # Sections
    if ($trim -match '^\s*##*\s*\[pr\]\s*Procedure') {
        $currentSection = [PSCustomObject]@{
            steps = @()
        }
        $currentProcedure.sections += $currentSection
        continue
    }
    if ($trim -match '^\s*##*\s*\[re\]\s*(.+)$') {
        $currentSection = [PSCustomObject]@{
            reply = $matches[1].Trim()
            steps = @()
        }
        $currentProcedure.sections += $currentSection
        continue
    }
    if ($trim -match '^\s*##*\s*\[ext\]\s*(.+)$') {
        $currentSection = [PSCustomObject]@{
            extra = @()
        }
        $currentProcedure.sections += $currentSection
        continue
    }

    # Capture content
    if ($currentSection) {
        if ($currentSection.PSObject.Properties.Name -eq 'steps') {
            $currentSection.steps += $trim
        } elseif ($currentSection.PSObject.Properties.Name -eq 'extra') {
            $currentSection.extra += $trim
        } elseif ($currentSection.PSObject.Properties.Name -eq 'reply') {
            $currentSection.steps += $trim
        }
    }
}

# Save JSON
$json = [PSCustomObject]@{
    procedures = $procedures
}
$json | ConvertTo-Json -Depth 10 -Compress | Set-Content $jsonFile -Encoding UTF8
Write-Host "Conversion complete. JSON written to $jsonFile"

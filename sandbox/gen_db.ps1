<#
.SYNOPSIS
Generate a cross-platform test database using CSV files with TempID column
.DESCRIPTION
- Creates multiple location CSV files
- Populates each with random employees
- Columns: TempID, ID, JOB_DEF, FILIAL, COMMENT
- Works on Windows/macOS/Linux, no dependencies
#>

# --- Config ---
$DatabaseDir = "./test_db"
$locations = @("NY_Office","LA_Office","London_Office","Berlin_Office","Tokyo_Office")
$jobDefs = @("Sales","Support","Finance","HR","IT","Marketing")
$filials = @("Manager","Lead","Supervisor","TempSupervisor","FrontDesk","Backup")
$comments = @(
    "Handles VIP clients",
    "Front office replacement",
    "Back office tasks",
    "Temporary assignment",
    "Cross-trained staff"
)
$employeesPerTable = 200  # adjust as needed

# Create folder
New-Item -Path $DatabaseDir -ItemType Directory -Force | Out-Null

# --- Generate employees ---
function Get-RandomEmployee {
    $idNum = Get-Random -Minimum 1000 -Maximum 9999
    $tempIdNum = Get-Random -Minimum 5000 -Maximum 9999
    [PSCustomObject]@{
        TempID   = "t00$tempIdNum"
        ID       = "b00$idNum"
        JOB_DEF  = $jobDefs | Get-Random
        FILIAL   = $filials | Get-Random
        COMMENT  = $comments | Get-Random
    }
}

# --- Create CSVs ---
foreach ($loc in $locations) {
    $csvPath = Join-Path $DatabaseDir "$loc.csv"
    $employees = for ($i=0; $i -lt $employeesPerTable; $i++) { Get-RandomEmployee }
    $employees | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "Created $csvPath with $employeesPerTable employees"
}

Write-Host "`nTest database generation complete! Folder: $DatabaseDir"

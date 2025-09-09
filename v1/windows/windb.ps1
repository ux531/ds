<#
.SYNOPSIS
    Employee/Job Definition Lookup in MDB file
.DESCRIPTION
    - Accepts 1 argument (global search across all tables) or 2 arguments (specific table + search)
    - Searches JD and SJD columns (case-insensitive)
    - Outputs aligned, readable table
#>

param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Arg1,

    [Parameter(Position=1)]
    [string]$Arg2
)

# === CONFIGURATION ===
$MDBFile = "C:\Path\To\Database.mdb"   # <-- update path
$ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$MDBFile"

# Determine search mode
if ($PSBoundParameters.Count -eq 1) {
    $SearchMode = "Global"
    $SearchID = $Arg1
} elseif ($PSBoundParameters.Count -eq 2) {
    $SearchMode = "Local"
    $TableName = $Arg1
    $SearchID = $Arg2
} else {
    Write-Host "Usage:`n  .\macdb.ps1 EMPLOYEEID`n  .\macdb.ps1 TABLE EMPLOYEEID"
    exit
}

# Connect to MDB
$Connection = New-Object System.Data.OleDb.OleDbConnection($ConnectionString)
$Connection.Open()

# Get tables
$AllTables = $Connection.GetSchema("Tables") | Where-Object { $_.TABLE_TYPE -eq "TABLE" }

if ($SearchMode -eq "Local") {
    $TablesToSearch = $AllTables | Where-Object { $_.TABLE_NAME -eq $TableName }
    if (-not $TablesToSearch) {
        Write-Host "Table '$TableName' not found in MDB."
        exit
    }
} else {
    $TablesToSearch = $AllTables
}

# Collect results
$Results = @()

foreach ($table in $TablesToSearch) {
    $Table = $table.TABLE_NAME

    # Get column names
    $Columns = $Connection.GetSchema("Columns", @($null, $null, $Table, $null)) | Select-Object -ExpandProperty COLUMN_NAME

    if ($Columns -contains "JD" -and $Columns -contains "SJD") {
        $Query = "SELECT * FROM [$Table]"
        $Command = $Connection.CreateCommand()
        $Command.CommandText = $Query

        $Adapter = New-Object System.Data.OleDb.OleDbDataAdapter $Command
        $DataSet = New-Object System.Data.DataSet
        $Adapter.Fill($DataSet) | Out-Null

        foreach ($row in $DataSet.Tables[0].Rows) {
            if (($row.JD -eq $SearchID) -or ($row.SJD -eq $SearchID)) {
                $Results += [PSCustomObject]@{
                    Table    = $Table
                    JD       = $row.JD
                    SJD      = $row.SJD
                    Employee = if ($Columns -contains "EmployeeID") { $row.EmployeeID } else { "" }
                    Comment  = if ($Columns -contains "Comment") { $row.Comment } else { "" }
                }
            }
        }
    }
}

$Connection.Close()

# Display results
if (-not $Results) {
    Write-Host "No matching employee found."
} else {
    # Print aligned table
    $Results | Format-Table Table, Employee, JD, SJD, Comment -AutoSize
    Write-Host "`nTotal matches found: $($Results.Count)"
}

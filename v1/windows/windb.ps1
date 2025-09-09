<#
.SYNOPSIS
Search employee records in Access MDB database.
.DESCRIPTION
- Accepts either 1 argument (global search) or 2 arguments (location + ID).
- Checks both ID and SID columns.
- Requires Microsoft ACE OLEDB provider (installed with Office).
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string[]]$Args
)

if (-Not (Test-Path $DatabaseFile)) {
    Write-Host "Database file not found: $DatabaseFile"
    exit
}

if ($Args.Count -eq 1) {
    $searchMode = "global"
    $searchId   = $Args[0]
}
elseif ($Args.Count -eq 2) {
    $searchMode = "local"
    $location   = $Args[0]
    $searchId   = $Args[1]
}
else {
    Write-Host "Usage:"
    Write-Host "  ./windb.ps1 EMPLOYEE_ID"
    Write-Host "  ./windb.ps1 LOCATION EMPLOYEE_ID"
    exit
}

Write-Host "`n=== Employee Lookup ===`n"

$results = @()

$provider = "Microsoft.ACE.OLEDB.12.0"
$connStr  = "Provider=$provider;Data Source=$DatabaseFile"
$conn     = New-Object -ComObject ADODB.Connection
$conn.Open($connStr)

function Get-TableNames($conn) {
    $rs = $conn.OpenSchema(20) # adSchemaTables
    $tables = @()
    while (-not $rs.EOF) {
        $t = $rs.Fields.Item("TABLE_NAME").Value
        if ($rs.Fields.Item("TABLE_TYPE").Value -eq "TABLE") {
            $tables += $t
        }
        $rs.MoveNext()
    }
    $rs.Close()
    return $tables
}

$tables = Get-TableNames $conn

if ($searchMode -eq "local") {
    if ($tables -notcontains $location) {
        Write-Host "Location $location not found in database."
        $conn.Close()
        exit
    }
    $sql = "SELECT * FROM [$location] WHERE ID='$searchId' OR SID='$searchId'"
    $rs = New-Object -ComObject ADODB.Recordset
    $rs.Open($sql, $conn)
    while (-not $rs.EOF) {
        $results += [PSCustomObject]@{
            Location = $location
            ID       = $rs.Fields.Item("ID").Value
            SID      = $rs.Fields.Item("SID").Value
            JOB_DEF  = $rs.Fields.Item("JOB_DEF").Value
            FILIAL   = $rs.Fields.Item("FILIAL").Value
            COMMENT  = $rs.Fields.Item("COMMENT").Value
        }
        $rs.MoveNext()
    }
    $rs.Close()
}
else {
    foreach ($table in $tables) {
        $sql = "SELECT * FROM [$table] WHERE ID='$searchId' OR SID='$searchId'"
        $rs = New-Object -ComObject ADODB.Recordset
        $rs.Open($sql, $conn)
        while (-not $rs.EOF) {
            $results += [PSCustomObject]@{
                Location = $table
                ID       = $rs.Fields.Item("ID").Value
                SID      = $rs.Fields.Item("SID").Value
                JOB_DEF  = $rs.Fields.Item("JOB_DEF").Value
                FILIAL   = $rs.Fields.Item("FILIAL").Value
                COMMENT  = $rs.Fields.Item("COMMENT").Value
            }
            $rs.MoveNext()
        }
        $rs.Close()
    }
}

$conn.Close()

if ($results.Count -eq 0) {
    Write-Host "No matching employee found."
}
else {
    $results | Format-Table -AutoSize
    Write-Host "`nTotal locations found: $($results.Count)`n"
}

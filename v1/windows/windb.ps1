<#
.SYNOPSIS
Employee/Job Definition Lookup in MDB file
.DESCRIPTION
- Accepts 2 arguments: specific table + search value
- Accepts 1 argument: search value (global search)
- Accepts 0 arguments: reads search value from clipboard
- Searches USER_ID, JOBDEF, OLD_JOBDEF, and FILIAL columns (case-insensitive)
- Stops after first 2 matches
#>

param (
    [Parameter(Position = 0)][string]$Arg1,
    [Parameter(Position = 1)][string]$Arg2
)

# === CONFIGURATION ===
$MDBFile = "\\srvhobefps01\CORP\Building Benkovski\Access management Department\SEC DATABASE\AM DATA 28.03.2025 WORKING.mdb"
$ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$MDBFile"

# === Determine Search Mode ===
if ($PSBoundParameters.Count -eq 2) {
    $SearchMode = "Local"
    $TableName = $Arg1
    $SearchID = $Arg2
} elseif ($PSBoundParameters.Count -eq 1) {
    $SearchMode = "Global"
    $SearchID = $Arg1
} else {
    $ClipboardContent = Get-Clipboard
    if (-not $ClipboardContent) {
        Write-Host "❌ No arguments provided and clipboard is empty. Please provide a search ID."
        exit
    }
    $SearchMode = "Global"
    $SearchID = $ClipboardContent.Trim()
    Write-Host "Using clipboard content as search ID: '$SearchID'"
}

# === Connect to MDB ===
Write-Host "Connecting to MDB file..."
$Connection = New-Object System.Data.OleDb.OleDbConnection($ConnectionString)
try {
    $Connection.Open()
    Write-Host "✅ Connection opened successfully."
} catch {
    Write-Host "❌ Failed to open MDB file: $($_.Exception.Message)"
    exit
}

# === Get Table List ===
Write-Host "Retrieving table list..."
try {
    $AllTables = $Connection.GetSchema("Tables") | Where-Object { $_.TABLE_TYPE -eq "TABLE" }
    Write-Host "✅ Found $($AllTables.Count) tables."
} catch {
    Write-Host "❌ Failed to retrieve tables: $($_.Exception.Message)"
    $Connection.Close()
    exit
}

# === Determine Tables to Search ===
if ($SearchMode -eq "Local") {
    $TablesToSearch = $AllTables | Where-Object { $_.TABLE_NAME -eq $TableName }
    if (-not $TablesToSearch) {
        Write-Host "❌ Table '$TableName' not found."
        $Connection.Close()
        exit
    }
    Write-Host "🔍 Searching in specific table: $TableName"
} else {
    $TablesToSearch = $AllTables
    Write-Host "🔍 Global search in all tables..."
}

# === Begin Searching ===
$Results = @()
$MaxResults = 2

foreach ($table in $TablesToSearch) {
    $Table = $table.TABLE_NAME
    Write-Host "`n→ Checking table: $Table"

    # Get Columns
    $Columns = @()
    $SchemaQuery = "SELECT TOP 1 * FROM [$Table]"
    $Cmd = $Connection.CreateCommand()
    $Cmd.CommandText = $SchemaQuery
    try {
        $Reader = $Cmd.ExecuteReader()
        for ($i = 0; $i -lt $Reader.FieldCount; $i++) {
            $Columns += $Reader.GetName($i)
        }
        $Reader.Close()
    } catch {
        Write-Host "⚠️ Skipping table '$Table': $($_.Exception.Message)"
        continue
    }

    # Skip tables without required columns
    if (-not ($Columns -contains "USER_ID" -and $Columns -contains "JOBDEF")) {
        Write-Host "⚠️ Skipping table '$Table': missing USER_ID or JOBDEF columns"
        continue
    }

    # Read Data
    $Query = "SELECT * FROM [$Table]"
    $Command = $Connection.CreateCommand()
    $Command.CommandText = $Query
    try {
        $Adapter = New-Object System.Data.OleDb.OleDbDataAdapter $Command
        $DataSet = New-Object System.Data.DataSet
        $Adapter.Fill($DataSet) | Out-Null
        foreach ($row in $DataSet.Tables[0].Rows) {
            # Check for match in USER_ID, JOBDEF, OLD_JOBDEF, or FILIAL
            $match = ($row.USER_ID -ieq $SearchID) -or
                     ($row.JOBDEF -ieq $SearchID) -or
                     ($Columns -contains "OLD_JOBDEF" -and $row.OLD_JOBDEF -ieq $SearchID) -or
                     ($Columns -contains "FILIAL" -and $row.FILIAL -ieq $SearchID)

            # For local search, filter by FILIAL
            if ($SearchMode -eq "Local" -and $Columns -contains "FILIAL") {
                if ($row.FILIAL -ne $TableName) {
                    continue
                }
            }

            if ($match) {
                $Results += [PSCustomObject]@{
                    Table      = $Table
                    FILIAL     = if ($Columns -contains "FILIAL") { $row.FILIAL } else { "" }
                    USER_ID    = $row.USER_ID
                    JOBDEF     = $row.JOBDEF
                    OLD_JOBDEF = if ($Columns -contains "OLD_JOBDEF") { $row.OLD_JOBDEF } else { "" }
                    DATE_REG   = if ($Columns -contains "DATE_REG") { $row.DATE_REG } else { "" }
                    DATE_DEL   = if ($Columns -contains "DATE_DEL") { $row.DATE_DEL } else { "" }
                    LEVEL      = if ($Columns -contains "LEVEL") { $row.LEVEL } else { "" }
                    NAME       = if ($Columns -contains "NAME") { $row.NAME } else { "" }
                }
                if ($Results.Count -ge $MaxResults) {
                    Write-Host "✅ Found $($Results.Count) match(es), stopping early."
                    break
                }
            }
        }
        if ($Results.Count -ge $MaxResults) {
            break
        }
    } catch {
        Write-Host "⚠️ Error reading from table '$Table': $($_.Exception.Message)"
        continue
    }
}

$Connection.Close()

# === Output Results ===
Write-Host "`n================== SEARCH RESULTS =================="
if (-not $Results) {
    Write-Host "❌ No matches found for '$SearchID'."
} else {
    $Results | Format-Table Table, FILIAL, USER_ID, JOBDEF, OLD_JOBDEF, DATE_REG, DATE_DEL, LEVEL, NAME -AutoSize
    Write-Host "`n✅ Total matches found: $($Results.Count)"
}
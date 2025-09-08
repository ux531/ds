<#
.SYNOPSIS
Generates a fake Access MDB database with numeric table names (city/office codes).
.DESCRIPTION
- Tables named like 1251, 1302, 1499
- Each table has employee records
- Columns: TempID, SID, JOB_DEF, FILIAL, COMMENT
#>

param(
    [string]$OutputFile = ".\test_employees.mdb",
    [int]$EmployeesPerTable = 200
)

# Delete old db if present
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile -Force
    Write-Host "Deleted old database: $OutputFile"
}

# Create Access Application
$access = New-Object -ComObject Access.Application
$provider = "Microsoft.ACE.OLEDB.12.0"
$connStr = "Provider=$provider;Data Source=$OutputFile"

# Create new MDB
$catalog = New-Object -ComObject ADOX.Catalog
$catalog.Create($connStr)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($catalog) | Out-Null

$access.OpenCurrentDatabase($OutputFile)

# Example city/office codes
$tableCodes = @("1251","1302","1499","1780","2010")
$jobDefs   = @("Cashier","Sales","Manager","Finance","Support","Clerk","Analyst")
$comments  = @("On probation","VIP client handler","Back office tasks","Night shift",
               "Front desk","Temp replacement","Certified trainer")

# Create and populate each numeric table
foreach ($code in $tableCodes) {
    Write-Host "Creating table $code ..."
    $sqlCreate = @"
CREATE TABLE [$code] (
    TempID   TEXT(10),
    SID      TEXT(10),
    JOB_DEF  TEXT(50),
    FILIAL   TEXT(50),
    COMMENT  TEXT(100)
)
"@
    $access.CurrentDb().Execute($sqlCreate)

    for ($i=1; $i -le $EmployeesPerTable; $i++) {
        $tempId = "t{0:D6}" -f $i
        $sid    = "s{0:D6}" -f ($i + (Get-Random -Minimum 1000 -Maximum 9999))
        $job    = $jobDefs | Get-Random
        $filial = $jobDefs | Get-Random
        $comment= $comments | Get-Random

        $sqlInsert = "INSERT INTO [$code] (TempID, SID, JOB_DEF, FILIAL, COMMENT) VALUES " +
                     "('$tempId','$sid','$job','$filial','$comment')"
        $access.CurrentDb().Execute($sqlInsert)
    }

    Write-Host "Table $code created with $EmployeesPerTable employees"
}

$access.CloseCurrentDatabase()
$access.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($access) | Out-Null

Write-Host "`n✅ Test MDB generated: $OutputFile"

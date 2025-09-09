param (
    [string]$SourceMDB,
    [string]$BackupDir,
    [int]$Keep = 30,
    [switch]$List,
    [string]$Restore,
    [string]$TargetDir,
    [switch]$DumpSchema
)

function Backup-MDB {
    param($SourceMDB, $BackupDir, $Keep, $DumpSchema)

    if (-not (Test-Path $BackupDir)) {
        Write-Host "Backup directory does not exist. Creating $BackupDir ..."
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    if (-not (Test-Path (Join-Path $BackupDir ".git"))) {
        Write-Host "Initializing new Git repository in $BackupDir ..."
        Push-Location $BackupDir
        git init | Out-Null
        Pop-Location
    }

    $FileName = Split-Path $SourceMDB -Leaf
    $DestFile = Join-Path $BackupDir $FileName

    Write-Host "Copying $SourceMDB -> $DestFile ..."
    Copy-Item -Path $SourceMDB -Destination $DestFile -Force

    # Optional schema dump
    if ($DumpSchema) {
        $SchemaFile = Join-Path $BackupDir ($FileName + ".schema.txt")
        Dump-MDBSchema -SourceMDB $SourceMDB -OutputFile $SchemaFile
    }

    Push-Location $BackupDir
    git add * | Out-Null

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CommitMsg = "Backup $FileName at $TimeStamp"
    git commit -m $CommitMsg | Out-Null

    $CommitHash = (git rev-parse HEAD).Trim()

    # --- Monthly tag ---
    $Today = Get-Date
    if ($Today.Day -eq 1) {
        $Tag = "monthly-$($Today.ToString('yyyy-MM'))"
        git tag -f $Tag $CommitHash
        $LogEntry = "$TimeStamp  Monthly backup -> Commit $CommitHash"
    } else {
        $LogEntry = "$TimeStamp  Daily backup -> Commit $CommitHash"
    }

    # --- Logging ---
    Add-Content -Path (Join-Path $BackupDir "backup.log") -Value $LogEntry
    git add backup.log | Out-Null
    git commit --amend --no-edit | Out-Null  # include log in same commit

    # --- Prune old commits (keep last N) ---
    $CommitCount = git rev-list --count HEAD
    if ($CommitCount -gt $Keep) {
        Write-Host "Pruning history to keep only the last $Keep daily commits ..."
        git checkout --orphan temp HEAD~$Keep 2>$null
        git commit -m "Pruned history, keeping last $Keep daily backups" --allow-empty | Out-Null
        git branch -D main 2>$null
        git branch -M main
        git reflog expire --expire=now --all
        git gc --prune=now --aggressive
    }

    Pop-Location
    Write-Host "✅ Backup completed and committed at $TimeStamp"
}

function Dump-MDBSchema {
    param($SourceMDB, $OutputFile)

    Write-Host "Dumping schema from $SourceMDB -> $OutputFile ..."
    $ConnStr = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$SourceMDB;Persist Security Info=False;"

    $conn = New-Object -ComObject ADODB.Connection
    $conn.Open($ConnStr)
    $catalog = New-Object -ComObject ADOX.Catalog
    $catalog.ActiveConnection = $conn

    $sb = New-Object System.Text.StringBuilder
    foreach ($table in $catalog.Tables) {
        if ($table.Type -eq "TABLE") {
            $null = $sb.AppendLine("Table: $($table.Name)")
            foreach ($col in $table.Columns) {
                $null = $sb.AppendLine("    $($col.Name) ($($col.Type))")
            }
            $null = $sb.AppendLine()
        }
    }

    $conn.Close()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($conn) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($catalog) | Out-Null

    $sb.ToString() | Out-File -Encoding UTF8 -FilePath $OutputFile
}

# (List-Backups and Restore-MDB functions same as before...)

# === Main logic ===
if ($List) {
    List-Backups -BackupDir $BackupDir
}
elseif ($Restore) {
    if (-not $TargetDir) {
        Write-Host "You must specify -TargetDir when using -Restore"
        exit 1
    }
    Restore-MDB -BackupDir $BackupDir -Restore $Restore -TargetDir $TargetDir
}
elseif ($SourceMDB -and $BackupDir) {
    Backup-MDB -SourceMDB $SourceMDB -BackupDir $BackupDir -Keep $Keep -DumpSchema:$DumpSchema
}
else {
    Write-Host "Usage:"
    Write-Host "  Backup:  .\mdb-backup.ps1 -SourceMDB <path> -BackupDir <path> [-Keep N] [-DumpSchema]"
    Write-Host "  List:    .\mdb-backup.ps1 -BackupDir <path> -List"
    Write-Host "  Restore: .\mdb-backup.ps1 -BackupDir <path> -Restore <commit|date> -TargetDir <path>"
    exit 1
}

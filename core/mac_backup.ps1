# =========================================================
# Módulo centralizado: respaldo de MACs por familia de equipo
# Uso: . (Join-Path $rootDir "core\mac_backup.ps1")
#      Initialize-MacBackup -ScriptDir $PSScriptRoot -Familia "POE_1GB_FLASH"
#      Save-MacBackup -Mac $macResult
#      Export-MacBackupSession   # al salir del script (tecla S)
# =========================================================

function Get-MacBackupRoot {
    param([string]$ScriptDir)
    Split-Path -Parent $ScriptDir
}

function Initialize-MacBackup {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptDir,
        [Parameter(Mandatory = $true)][string]$Familia,
        [string]$MacFileName = "mac.txt"
    )

    $root = Get-MacBackupRoot -ScriptDir $ScriptDir
    $backupDir = Join-Path $root "backups_macs"
    $macFile = Join-Path $ScriptDir $MacFileName

    foreach ($dir in @(
            $backupDir,
            (Join-Path $backupDir "historial"),
            (Join-Path $backupDir "sesiones")
        )) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    if (-not (Test-Path $macFile)) {
        New-Item -Path $macFile -ItemType File -Force | Out-Null
    }

    $masterCsv = Join-Path $backupDir "produccion_master.csv"
    if (-not (Test-Path $masterCsv)) {
        "Fecha,Hora,Familia,MAC,Resultado,Script" | Out-File -FilePath $masterCsv -Encoding UTF8
    }

    $script:MacBackupState = @{
        ScriptDir  = $ScriptDir
        RootDir    = $root
        BackupDir  = $backupDir
        MacFile    = $macFile
        Familia    = $Familia.Trim()
        Session    = [System.Collections.Generic.List[object]]::new()
        StartedAt  = Get-Date
    }
}

function Format-MacAddress {
    param([string]$Mac)
    if ([string]::IsNullOrWhiteSpace($Mac)) { return $null }
    $m = $Mac.Trim().ToUpper() -replace '-', ':'
    if ($m -match '^([0-9A-F]{2}:){5}[0-9A-F]{2}$') { return $m }
    return $null
}

function Save-MacBackup {
    param(
        [Parameter(Mandatory = $true)][string]$Mac,
        [string]$Resultado = "OK"
    )

    if (-not $script:MacBackupState) {
        Write-Warning "Save-MacBackup: ejecute Initialize-MacBackup primero."
        return $false
    }

    $macNorm = Format-MacAddress -Mac $Mac
    if (-not $macNorm) { return $false }

    $st = $script:MacBackupState
    $now = Get-Date
    $fecha = $now.ToString("yyyy-MM-dd")
    $hora = $now.ToString("HH:mm:ss")

    Add-Content -Path $st.MacFile -Value $macNorm -Encoding UTF8 -ErrorAction SilentlyContinue

    $historialFile = Join-Path $st.BackupDir "historial\$($st.Familia)_$fecha.txt"
    $linea = "$hora | $($st.Familia) | $macNorm | $Resultado"
    Add-Content -Path $historialFile -Value $linea -Encoding UTF8

    $masterCsv = Join-Path $st.BackupDir "produccion_master.csv"
    $scriptName = Split-Path $st.ScriptDir -Leaf
    $csvLine = "$fecha,$hora,$($st.Familia),$macNorm,$Resultado,$scriptName"
    Add-Content -Path $masterCsv -Value $csvLine -Encoding UTF8

    $st.Session.Add([PSCustomObject]@{
            Fecha     = $fecha
            Hora      = $hora
            Familia   = $st.Familia
            MAC       = $macNorm
            Resultado = $Resultado
        })

    Write-Host "      [BACKUP] $macNorm -> mac.txt + backups_macs" -ForegroundColor DarkCyan
    return $true
}

function Export-MacBackupSession {
    if (-not $script:MacBackupState) { return }

    $st = $script:MacBackupState
    if ($st.Session.Count -eq 0) {
        Write-Host " [BACKUP] Sin MACs en esta sesion; no se exporta archivo de sesion." -ForegroundColor Gray
        return
    }

    $now = Get-Date
    $fecha = $now.ToString("yyyy-MM-dd")
    $horaTag = $now.ToString("HHmmss")
    $sesionesDir = Join-Path $st.BackupDir "sesiones"
    $exportFile = Join-Path $sesionesDir "$($st.Familia)_${fecha}_$horaTag.csv"

    $st.Session | Export-Csv -Path $exportFile -NoTypeInformation -Encoding UTF8

    $resumen = Join-Path $st.BackupDir "resumen_por_familia.csv"
    if (-not (Test-Path $resumen)) {
        "Fecha,Hora,Familia,Cantidad,Archivo_Sesion" | Out-File -FilePath $resumen -Encoding UTF8
    }
    $resumenLine = "$fecha,$($now.ToString('HH:mm:ss')),$($st.Familia),$($st.Session.Count),$(Split-Path $exportFile -Leaf)"
    Add-Content -Path $resumen -Value $resumenLine -Encoding UTF8

    Write-Host ""
    Write-Host " [BACKUP] Sesion exportada: $exportFile ($($st.Session.Count) MACs)" -ForegroundColor Green
}

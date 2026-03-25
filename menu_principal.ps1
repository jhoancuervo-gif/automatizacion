# =====================================================================
# MENU PRINCIPAL INTEGRADO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RootPath = $PSScriptRoot
$EnvPath = Join-Path $RootPath ".env"

function Mostrar-Menu {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "      SISTEMA DE AUTOMATIZACION - ESTACION DE TRABAJO     " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " 1. SWITCH POE 1.0 Gb"
    Write-Host " 2. SWITCH POE 2.5 Gb"
    Write-Host "----------------------------------------------------------"
    Write-Host " 3. PHANTOM F2"
    Write-Host " 4. PHANTOM NUEVOS"
    Write-Host " 5. PHANTOM REINTEGRO"
    Write-Host "----------------------------------------------------------"
    Write-Host " 6. ORBES NUEVAS"
    Write-Host " 7. ORBES REINTEGRO"
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " 8. TV BOX"
     Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " 10. INSTALAR DEPENDENCIAS (Configurar nueva PC)" -ForegroundColor Yellow
    Write-Host " 11. CAMBIAR RANGO DE IPs"
    Write-Host " 0. SALIR"
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "Seleccione una opcion: " -NoNewline
}

do {
    Mostrar-Menu
    $opcion = Read-Host
    
    switch ($opcion) {
        "1" { 
            $Path = Join-Path $RootPath "scripts_poe_1gb"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c iniciarfirmPOE.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe carpeta 'scripts_poe_1gb'" -ForegroundColor Red; Pause }
        }
        "2" { 
            $Path = Join-Path $RootPath "scripts_poe_2_5gb"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c iniciarfirmPOE2.5.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe carpeta 'scripts_poe_2_5gb'" -ForegroundColor Red; Pause }
        }
        "4" { 
            $Path = Join-Path $RootPath "scripts_phantom_nuevos"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantom_nuevos.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe 'scripts_phantom_nuevos'" -ForegroundColor Red; Pause }
        }
        "5" { 
            $Path = Join-Path $RootPath "scripts_phantom_reintegro"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantom.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe 'scripts_phantom_reintegro'" -ForegroundColor Red; Pause }
        }
        "6" { 
            $Path = Join-Path $RootPath "scripts_orbes_nuevas"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_orbes_nuevas.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe carpeta 'scripts_orbes_nuevas'" -ForegroundColor Red; Pause }
        }
        "7" { 
            $Path = Join-Path $RootPath "scripts_orbe_reintegro"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_orbes_rein.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe carpeta 'scripts_orbe_reintegro'" -ForegroundColor Red; Pause }
        }
        "8" {
            $Path = Join-Path $RootPath "configurartvbox_sinapp"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c configurar_sinapp.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n[-] ERROR: No existe carpeta 'configurartvbox_sinapp'" -ForegroundColor Red; Pause }
        }
        "10" {
            $PathDeps = Join-Path $RootPath "instalar_dependencias.ps1"
            if (Test-Path $PathDeps) {
                Write-Host "`n[!] Iniciando instalador de dependencias..." -ForegroundColor Cyan
                powershell -ExecutionPolicy Bypass -File "$PathDeps"
            } else { Write-Host "`n[-] ERROR: No se encuentra 'instalar_dependencias.ps1' en la ra�z." -ForegroundColor Red; Pause }
        }
        "11" {
            Write-Host "`n--- CONFIGURACI�N DE RANGO ---" -ForegroundColor Cyan
            $inicio = Read-Host " Ingrese IP INICIAL"
            $fin = Read-Host " Ingrese IP FINAL"
            if ($inicio -match "^\d+$" -and $fin -match "^\d+$") {
                if (Test-Path $EnvPath) {
                    $content = Get-Content $EnvPath
                    $content = $content -replace "IP_START=.*", "IP_START=$inicio"
                    $content = $content -replace "IP_END=.*", "IP_END=$fin"
                    Set-Content -Path $EnvPath -Value $content -Encoding UTF8
                    Write-Host "`n[+] Rango actualizado en .env" -ForegroundColor Green
                } else { Write-Host "`n[-] ERROR: No se encontr� archivo .env" -ForegroundColor Red }
            } else { Write-Host "`n[-] ERROR: Ingrese solo n�meros" -ForegroundColor Red }
            Pause
        }
        "0" { exit }
    }
} while ($true)
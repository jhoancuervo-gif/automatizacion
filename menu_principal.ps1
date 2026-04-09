# =====================================================================
# MENU PRINCIPAL INTEGRADO - VERSION PROFESIONAL MAGENTA
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RootPath = $PSScriptRoot
$EnvPath = Join-Path $RootPath ".env"

function Mostrar-Menu {
    Clear-Host
    # Bordes en Magenta, Título en Blanco
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  🚀  SISTEMA DE AUTOMATIZACIÓN - ESTACIÓN DE TRABAJO     " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Magenta
    
    # Cuerpo del menú
    Write-Host "  ║                                                          ║" -ForegroundColor Magenta
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  [ 📡 POE´S ]                    [ 👻 PHANTOM´S ]        " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  1. Switch PoE 1.0 Gb             4. Phantom F2 Reintegro" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  2. Switch PoE 2.5 Gb             5. Phantom F2 (TEST)   " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  3. 🔍 Verificar Puertos          6. Phantom Nuevos      " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta

    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "                                   7. Phantom Reintegro   " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    Write-Host "  ║                                                          ║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  [ 🔍 MONITOREO ]                [ 🔮 ORB´S ]            " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  10. 📺 TV BOX                    8. Orbes Nuevas        " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "                                   9. Orbes Reintegro     " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║                                                          ║" -ForegroundColor Magenta
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  [ ⚙️ CONFIGURACIÓN ]                                    " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  11. Instalar Dependencias (Nueva PC)                    " -NoNewline -ForegroundColor Yellow
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  12.🌐 Cambiar Rango de IPs                              " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ║" -NoNewline -ForegroundColor Magenta
    Write-Host "  0. ❌ Salir                                             " -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor Magenta
    
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor White
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
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_poe_1gb'" -ForegroundColor Red; Pause }
        }
        "2" { 
            $Path = Join-Path $RootPath "scripts_poe_2_5gb"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c iniciarfirmPOE2.5.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_poe_2_5gb'" -ForegroundColor Red; Pause }
        }
        "3" {
            $PathCheck = Join-Path $RootPath "check_puerto_poe.ps1"
            if (Test-Path $PathCheck) {
                powershell -ExecutionPolicy Bypass -File "$PathCheck"
            } else {
                Write-Host "`n  [-] ERROR: Archivo no encontrado." -ForegroundColor Red
                Pause
            }
        }
        "4" { 
            $Path = Join-Path $RootPath "scripts_phantom_f2_reintegro"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantomf2.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_phantom_f2_reintegro'" -ForegroundColor Red; Pause }
        }
        "5" { 
            $Path = Join-Path $RootPath "scripts_phantom_f2"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantomf2nuevos.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_phantom_f2'" -ForegroundColor Red; Pause }
        }
        "6" { 
            $Path = Join-Path $RootPath "scripts_phantom_nuevos"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantom_nuevos.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe 'scripts_phantom_nuevos'" -ForegroundColor Red; Pause }
        }
        "7" { 
            $Path = Join-Path $RootPath "scripts_phantom_reintegro"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_phantom.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe 'scripts_phantom_reintegro'" -ForegroundColor Red; Pause }
        }
        "8" { 
            $Path = Join-Path $RootPath "scripts_orbes_nuevas"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_orbes_nuevas.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_orbes_nuevas'" -ForegroundColor Red; Pause }
        }
        "9" { 
            $Path = Join-Path $RootPath "scripts_orbe_reintegro"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c menu_orbes_rein.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'scripts_orbe_reintegro'" -ForegroundColor Red; Pause }
        }
        "10" {
            $Path = Join-Path $RootPath "configurartvbox_sinapp"
            if (Test-Path $Path) {
                Set-Location -Path $Path
                cmd.exe /c configurar_sinapp.bat
                Set-Location -Path $RootPath
            } else { Write-Host "`n  [-] ERROR: No existe carpeta 'configurartvbox_sinapp'" -ForegroundColor Red; Pause }
        }
        "11" {
            $LanzadorPath = Join-Path $RootPath "lanzador.bat"
            if (Test-Path $LanzadorPath) {
                Write-Host "`n  [!] Ejecutando lanzador con privilegios..." -ForegroundColor Cyan
                Start-Process "$LanzadorPath" -Wait
            } else { 
                Write-Host "`n  [-] ERROR: No se encuentra 'lanzador.bat' en la raiz." -ForegroundColor Red
                Pause 
            }
        }
        "12" {
            Write-Host "`n  --- CONFIGURACION DE RANGO ---" -ForegroundColor Cyan
            $inicio = Read-Host "   Ingrese IP INICIAL"
            $fin = Read-Host "   Ingrese IP FINAL"
            if ($inicio -match "^\d+$" -and $fin -match "^\d+$") {
                if (Test-Path $EnvPath) {
                    $content = Get-Content $EnvPath
                    $content = $content -replace "IP_START=.*", "IP_START=$inicio"
                    $content = $content -replace "IP_END=.*", "IP_END=$fin"
                    Set-Content -Path $EnvPath -Value $content -Encoding UTF8
                    Write-Host "`n  [+] Rango actualizado en .env" -ForegroundColor Green
                } else { Write-Host "`n  [-] ERROR: No se encontró archivo .env" -ForegroundColor Red }
            } else { Write-Host "`n  [-] ERROR: Ingrese solo números" -ForegroundColor Red }
            Pause
        }
        "0" { exit }
    }
} while ($true)
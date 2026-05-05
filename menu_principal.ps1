# =====================================================================
# SISTEMA DE AUTOMATIZACIÓN PRO - BARRA DINÁMICA & TECLADO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "Automation Station - $env:USERNAME"

$RootPath = $PSScriptRoot
$EnvPath = Join-Path $RootPath ".env"

# Cachear IP una sola vez al cargar la aplicación
$script:IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Ethernet*" -or $_.InterfaceAlias -like "*Wi-Fi*" } | Select-Object -First 1).IPAddress

# --- Función para ejecutar herramientas sin repetir código ---
function Ejecutar-Herramienta {
    param([string]$SubDir, [string]$ScriptName)
    $Path = Join-Path $RootPath $SubDir
    if (Test-Path $Path) {
        Push-Location $Path
        if ($ScriptName.EndsWith(".bat")) {
            cmd.exe /c $ScriptName
        }
        elseif ($ScriptName.EndsWith(".ps1")) {
            & .\$ScriptName
        }
        Pop-Location
    }
    else { 
        Write-Host "`n  [!] ERROR: Carpeta '$SubDir' no encontrada." -ForegroundColor Red
        Pause 
    }
}

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"

    # --- BARRA DE ESTADO DINÁMICA ---
    # IP Activa y hora del sistema
    $Fecha = Get-Date -Format "HH:mm:ss"
    
    Write-Host "  IP: $($script:IP.PadRight(15)) | HOST: $($env:COMPUTERNAME.PadRight(15)) | $Fecha" -ForegroundColor $C
    
    # --- DISEÑO DEL MENÚ ---
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  🚀  SISTEMA DE AUTOMATIZACIÓN - ESTACIÓN DE TRABAJO     " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ 📡 POE´S ]                    [ 👻 PHANTOM´S ]        " -NoNewline -ForegroundColor DarkBlue; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  1. Switch PoE 1.0 Gb             4. Phantom F2 Reintegro" -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  2. Switch PoE 2.5 Gb             5. Phantom F2 (TEST)   " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  3. 🔍 Verificar Puertos          6. Phantom Nuevos      " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "                                   7. Phantom Reintegro   " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ 🔍 MONITOREO ]                [ 🔮 ORB´S ]            " -NoNewline -ForegroundColor DarkBlue; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  10. 📺 TV BOX                    8. Orbes Nuevas        " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "                                   9. Orbes Reintegro     " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ ⚙️ CONFIGURACIÓN ]                                    " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  11. Instalar Dependencias (Nueva PC)                    " -NoNewline -ForegroundColor $Y; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  12.🌐 Cambiar Rango de IPs                              " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  0. ❌ Salir                                             " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor $W
}

# --- Bucle de Ejecución ---
do {
    Mostrar-Menu
    $opcion = Read-Host

    switch ($opcion) {
        "1" { Ejecutar-Herramienta "scripts_poe_1gb" "iniciarfirmPOE.ps1" }
        "2" { Ejecutar-Herramienta "scripts_poe_2_5gb" "iniciarfirmPOE2.5.ps1" }
        "3" { 
            $f = Join-Path $RootPath "check_puerto_poe.ps1"
            if (Test-Path $f) { & $f } else { Write-Host "Error"; Pause }
        }
        "4" { Ejecutar-Herramienta "scripts_phantom_f2_reintegro" "menu_phantomf2.bat" }
        "5" { Ejecutar-Herramienta "scripts_phantom_f2" "menu_phantomf2nuevos.bat" }
        "6" { Ejecutar-Herramienta "scripts_phantom_nuevos" "menu_phantom_nuevos.bat" }
        "7" { Ejecutar-Herramienta "scripts_phantom_reintegro" "menu_phantom.ps1" }
        "8" { Ejecutar-Herramienta "scripts_orbes_nuevas" "menu_orbes_nuevas.ps1" }
        "9" { Ejecutar-Herramienta "scripts_orbe_reintegro" "menu_orbes_rein.ps1" }
        "10" { Ejecutar-Herramienta "configurartvbox_sinapp" "configurar_sinapp.bat" }
        "11" {
            $L = Join-Path $RootPath "lanzador.bat"
            if (Test-Path $L) { Start-Process "$L" -Wait } else { Write-Host "No se encuentra lanzador.bat"; Pause }
        }
        "12" {
            Write-Host "`n  --- CONFIGURACION DE RANGO ---" -ForegroundColor Cyan
            $inicio = Read-Host "   Ingrese IP INICIAL"
            $fin = Read-Host "   Ingrese IP FINAL"
            if ($inicio -match "^\d+$" -and $fin -match "^\d+$") {
                if (Test-Path $EnvPath) {
                    $content = Get-Content $EnvPath
                    $content = $content -replace "IP_START=.*", "IP_START=$inicio" -replace "IP_END=.*", "IP_END=$fin"
                    Set-Content $EnvPath $content -Encoding UTF8
                    Write-Host "`n  [+] Rango actualizado." -ForegroundColor Green
                }
            }
            Pause
        }
        "0" { exit }
    }
} while ($true)



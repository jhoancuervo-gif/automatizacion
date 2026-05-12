# Forzar que los errores se vean para diagnostico
$ErrorActionPreference = "Continue"

# Configurar el titulo de la ventana
$host.ui.RawUI.WindowTitle = "SUB-MENU: GESTION DE SWITCHES POE 1.0G"

# Obtener la ruta exacta de la carpeta donde vive este script
$CurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (!$CurrentPath) { $CurrentPath = "." }

function Mostrar-MenuPoe1 {
    Clear-Host
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Magenta
    Write-Host "    SUB-MENU: GESTION DE SWITCHES POE 1.0G - CUERVO          " -ForegroundColor White
    Write-Host "  ============================================================" -ForegroundColor Magenta
    Write-Host ""
    
    Write-Host "  [ PROCESOS INDIVIDUALES ]" -ForegroundColor DarkBlue
    Write-Host "  1. Equipo Nuevo Puerto 1        3. Config. Puerto 1" -ForegroundColor White
    Write-Host "  2. Equipo Nuevo Puerto 8        4. Config. Puerto 8" -ForegroundColor White
    
    Write-Host ""
    Write-Host "  [ AUTOMATIZACION MASIVA ]" -ForegroundColor DarkBlue
    Write-Host "  5. GESTION POE MASIVO (Por Lotes)" -ForegroundColor Green

    Write-Host ""
    Write-Host "  [ RED / IP ]" -ForegroundColor DarkBlue
    Write-Host "  6. Configurar IP Fija (192.168.18.2)" -ForegroundColor Cyan
    Write-Host "  7. Revertir IP a DHCP (Internet)" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "  ------------------------------------------------------------" -ForegroundColor Magenta
    Write-Host "  0. Salir al menu principal" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  >> Seleccione una opcion: " -NoNewline -ForegroundColor White
}

while ($true) {
    Mostrar-MenuPoe1
    $opcion = Read-Host

    if ($opcion -eq "0") { break }

    switch ($opcion) {
        "1" {
            Write-Host "`n  [*] Ejecutando poe.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\poe.ps1"
            Pause
        }
        "2" {
            Write-Host "`n  [*] Ejecutando poe1g8puertonuevo.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\poe1g8puertonuevo.ps1"
            Pause
        }
        "3" {
            Write-Host "`n  [*] Ejecutando poeport1.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\poeport1.ps1"
            Pause
        }
        "4" {
            Write-Host "`n  [*] Ejecutando poeport81G.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\poeport81G.ps1"
            Pause
        }
        "5" {
            Write-Host "`n  [*] Iniciando Gestion PoE Masiva (Python)..." -ForegroundColor Green
            # Llamada directa al script de Python en la misma carpeta
            python "$CurrentPath\poe_masivo_lote.py"
            Write-Host "`n  [OK] Proceso masivo finalizado." -ForegroundColor Green
            Pause
        }
        "6" {
            Write-Host "`n  [*] Configurando IP Fija..." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\Configurar Ip poe.ps1"
            Pause
        }
        "7" {
            Write-Host "`n  [*] Restaurando DHCP..." -ForegroundColor Yellow
            powershell -ExecutionPolicy Bypass -File "$CurrentPath\revertir_ip.ps1"
            Pause
        }
    }
}

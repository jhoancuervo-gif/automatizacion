# =====================================================================
# SUB-MENU: PHANTOM NUEVOS - CUERVO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "SUB-MENU: PHANTOM NUEVOS - CUERVO"

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"

    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |               SUB-MENU: PHANTOM NUEVOS - CUERVO          |" -ForegroundColor $W
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |                                                          |" -ForegroundColor $M
    
    Write-Host "  |   1. EJECUTAR PHANTOM NUEVOS (Flashear + Limpiar Raiz)   |" -ForegroundColor $W
    Write-Host "  |   2. VERIFICAR EN PORTAL (macs.txt de raiz)              |" -ForegroundColor $W
    
    Write-Host "  |                                                          |" -ForegroundColor $M
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |   0. VOLVER AL MENU PRINCIPAL                            |" -ForegroundColor $Y
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opcion: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-Menu
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Iniciando flasheo de equipo nuevo..." -ForegroundColor Cyan
            python phantom.py
            Pause
        }
        "2" {
            Write-Host "`n  [!] Consultando portal (macs.txt en raiz)..." -ForegroundColor Cyan
            python ../core/portal_tools.py verify --file ../macs.txt
            Pause
        }
        "0" { exit }
    }
} while ($true)

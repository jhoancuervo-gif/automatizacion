. ../core/notify_tools.ps1
# =====================================================================
# SUB-MENU: PHANTOM F2 NUEVOS - CUERVO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "SUB-MENU: PHANTOM F2 NUEVOS - CUERVO"

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $Y = "Yellow"; $C = "Cyan"

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
            python phantomsf2nuevos.py; Send-Notification -Title "Phantom F2" -Message "Flasheo de equipos nuevos finalizado"
            Pause
        }
        "2" {
            Write-Host "`n  [!] Consultando portal (macs.txt en raiz)..." -ForegroundColor Cyan
            python ../core/portal_tools.py verify --file ../macs.txt
            Pause
        }
        "0" {
            exit
        }
    }
} while ($true)

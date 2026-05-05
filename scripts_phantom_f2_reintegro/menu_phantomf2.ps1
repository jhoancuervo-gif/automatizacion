. ../core/notify_tools.ps1
# =====================================================================
# SUB-MENU: PHANTOM F2 REINTEGRO - CUERVO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "SUB-MENU: PHANTOM F2 REINTEGRO - CUERVO"

$RootPath = Join-Path $PSScriptRoot ".."

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $Y = "Yellow"; $C = "Cyan"

    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |            MENU: PHANTOM F2 REINTEGRO (212-215)          |" -ForegroundColor $W
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |                                                          |" -ForegroundColor $M
    
    Write-Host "  |   1. REINTEGRO COMPLETO           4. VERIFICAR MACS PORTAL |" -ForegroundColor $W
    Write-Host "  |   2. REINTEGRO PERSONALIZADO      5. ELIMINAR MACS PORTAL  |" -ForegroundColor $W
    Write-Host "  |   3. PRUEBA DE CONEXION                                    |" -ForegroundColor $W
    
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
            Write-Host "`n  [!] Ejecutando REINTEGRO F2 COMPLETO..." -ForegroundColor Cyan
            python Phantomsf2Rein.py; Send-Notification -Title "Phantom F2" -Message "Proceso de Reintegro finalizado"
            Pause
        }
        "2" {
            Write-Host "`n  [!] Ejecutando REINTEGRO F2 PERSONALIZADO..." -ForegroundColor Cyan
            python Phantomsf2Rein.py; Send-Notification -Title "Phantom F2" -Message "Proceso de Reintegro finalizado"
            Pause
        }
        "3" {
            Write-Host "`n  [!] Iniciando PRUEBA DE CONEXION F2..." -ForegroundColor Cyan
            python Phantomsf2Rein.py; Send-Notification -Title "Phantom F2" -Message "Proceso de Reintegro finalizado"
            Pause
        }
        "4" {
            Write-Host "`n  --- VERIFICAR MACs PORTAL (F2) ---" -ForegroundColor Cyan
            $macsFile = Join-Path $RootPath "macs.txt"
            if (Test-Path $macsFile) {
                Write-Host "  [+] Archivo macs.txt encontrado" -ForegroundColor Green
                $continuar = Read-Host "  >> ¿Continuar? (S/N)"
                if ($continuar -eq "S" -or $continuar -eq "s") {
                    python ../core/portal_tools.py verify --file ../macs.txt
                }
            } else {
                Write-Host "  [-] ERROR: No hay macs.txt en la raiz." -ForegroundColor Red
            }
            Pause
        }
        "5" {
            Write-Host "`n  --- ELIMINAR MACs PORTAL (F2) ---" -ForegroundColor Red
            $macsFile = Join-Path $RootPath "macs.txt"
            if (Test-Path $macsFile) {
                python ../core/portal_tools.py delete --file ../macs.txt
            } else {
                Write-Host "  [-] ERROR: No hay archivo macs.txt para eliminar." -ForegroundColor Red
            }
            Pause
        }
        "0" {
            exit
        }
    }
} while ($true)

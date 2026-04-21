# =====================================================================
# MENU: PHANTOM REINTEGRO (Optimizado nativo PowerShell)
# =====================================================================
$host.ui.RawUI.WindowTitle = "MENU PHANTOM REINTEGRO - CUERVO"

function Mostrar-MenuPhantom {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  👻  MENU: PHANTOM REINTEGRO                             " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ ⚡ OPERACIONES ]                                      " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  1. Reintegro Completo                                   " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  2. Reintegro Personalizado                              " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  3. 🔍 Prueba de Conexión                                " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ 🌐 PORTAL ]                                           " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  4. Verificar MACs Portal                                " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  5. Eliminar MACs Portal                                 " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M

    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  0. ❌ Salir al menú principal                           " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuPhantom
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Ejecutando REINTEGRO COMPLETO..." -ForegroundColor Cyan
            python phantom_reintegro.py
            cmd.exe /c pause
        }
        "2" {
            Write-Host "`n  [!] Ejecutando REINTEGRO PERSONALIZADO..." -ForegroundColor Cyan
            python phantom_reintegro.py
            cmd.exe /c pause
        }
        "3" {
            Write-Host "`n  [!] Iniciando PRUEBA DE CONEXIÓN..." -ForegroundColor Cyan
            python phantom_reintegro.py
            cmd.exe /c pause
        }
        "4" {
            Write-Host "`n  --- VERIFICAR MACs PORTAL ---" -ForegroundColor Cyan
            if (Test-Path "..\macs.txt") {
                Write-Host "  [+] Archivo macs.txt encontrado en la raiz" -ForegroundColor Green
                $continuar = Read-Host "  >> ¿Continuar? (S/N)"
                if ($continuar -match "^[Ss]$") {
                    python verificar_macs_portal.py
                }
            } else {
                Write-Host "  [-] ERROR: No hay archivo macs.txt en la raiz." -ForegroundColor Red
            }
            cmd.exe /c pause
        }
        "5" {
            Write-Host "`n  --- ELIMINAR MACs PORTAL ---" -ForegroundColor Red
            if (Test-Path "..\macs.txt") {
                python eliminar_macs_portal.py
            } else {
                Write-Host "  [-] ERROR: No hay archivo macs.txt para eliminar." -ForegroundColor Red
            }
            cmd.exe /c pause
        }
        "0" { return }
    }
} while ($true)


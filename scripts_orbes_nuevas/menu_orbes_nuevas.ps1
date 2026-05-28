. ../core/notify_tools.ps1
$host.ui.RawUI.WindowTitle = "SUB-MENU: ORBES NUEVAS - CUERVO"

function Mostrar-MenuOrbesN {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  🔮  SUB-MENU: ORBES NUEVAS - CUERVO                     " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ ⚡ OPERACIONES ]                                      " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  1. 🌟 Ejecutar Orbes Nuevas (Flashear)                  " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  2. 🔍 Verificar en Portal (macs.txt de raiz)            " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  0. ❌  Volver al menú principal                         " -NoNewline -ForegroundColor $Y; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuOrbesN
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Iniciando flasheo automático de Orbes..." -ForegroundColor Cyan
            python orbe.py; Send-Notification -Title "Orbes Nuevas" -Message "Flasheo de Orbes finalizado"
            cmd.exe /c pause
        }
        "2" {
            Write-Host "`n  [!] Consultando portal (macs.txt en raiz)..." -ForegroundColor Cyan
            python ../core/portal_tools.py verify --file ../macs.txt
            cmd.exe /c pause
        }
        "0" { return }
    }
} while ($true)


$host.ui.RawUI.WindowTitle = "SUB-MENU: ORBE REINTEGRO - CUERVO"

function Mostrar-MenuOrbeR {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  🔮  SUB-MENU: ORBE REINTEGRO - CUERVO                   " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ ⚡ OPERACIONES ]                                      " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  1. 🔄 Ejecutar Reintegro (Flashear + Reporte)           " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  2. 🔍 Verificar en Portal (macs.txt)                    " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  3. 🗑️ Eliminar del Portal (macs.txt)                    " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  0. ❌  Volver al menú principal                         " -NoNewline -ForegroundColor $Y; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuOrbeR
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Iniciando proceso de flasheo de Orbes..." -ForegroundColor Cyan
            python orbe_reintegro.py
            Write-Host "`n  [+] Flasheo finalizado. Reporte abierto en Bloc de notas." -ForegroundColor Green
            cmd.exe /c pause
        }
        "2" {
            Write-Host "`n  [!] Consultando portal para equipos en macs.txt..." -ForegroundColor Cyan
            python verificar_macs_portal.py
            # Original no pausaba aquí, para ser consistente
        }
        "3" {
            Write-Host "`n  [!] Iniciando borrado en portal para equipos en macs.txt..." -ForegroundColor Red
            python eliminar_macs_portal.py
            cmd.exe /c pause
        }
        "0" { return }
    }
} while ($true)


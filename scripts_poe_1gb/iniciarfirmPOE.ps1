$host.ui.RawUI.WindowTitle = "SUB-MENU: GESTIÓN DE SWITCHES POE 1.0G - CUERVO"

function Mostrar-MenuPoe1 {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"; $G = "Green"

    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  📡  SUB-MENU: GESTIÓN DE SWITCHES POE 1.0G              " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ ⚙️ PUERTOS ]                                          " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  1. Equipo Nuevo Puerto 1        3. Config. Puerto 1     " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  2. Equipo Nuevo Puerto 8        4. Config. Puerto 8     " -NoNewline -ForegroundColor $W; Write-Host "║" -ForegroundColor $M
    
    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  [ 🌐 RED / IP ]                                         " -NoNewline -ForegroundColor $B; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  5. Configurar IP Fija (192.168.18.2)                    " -NoNewline -ForegroundColor $C; Write-Host "║" -ForegroundColor $M
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  6. Revertir IP a DHCP (Internet)                        " -NoNewline -ForegroundColor $C; Write-Host "║" -ForegroundColor $M

    Write-Host "  ║                                                          ║" -ForegroundColor $M
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor $M
    
    Write-Host "  ║" -NoNewline -ForegroundColor $M; Write-Host "  0. ❌ Salir al menú principal                           " -NoNewline -ForegroundColor $Y; Write-Host "║" -ForegroundColor $M
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opción: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuPoe1
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Ejecutando poe.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poe.ps1"
            cmd.exe /c pause
        }
        "2" {
            Write-Host "`n  [!] Ejecutando poe1g8puertonuevo.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poe1g8puertonuevo.ps1"
            cmd.exe /c pause
        }
        "3" {
            Write-Host "`n  [!] Ejecutando configuracion1.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poeport1.ps1"
            cmd.exe /c pause
        }
        "4" {
            Write-Host "`n  [!] Ejecutando firmware8.ps1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poeport81G.ps1"
            cmd.exe /c pause
        }
        "5" {
            Write-Host "`n  [!] Configurando IP estática para auditoría..." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File ".\Configurar Ip poe.ps1"
            cmd.exe /c pause
        }
        "6" {
            Write-Host "`n  [!] Restaurando adaptador a modo DHCP..." -ForegroundColor Yellow
            powershell -ExecutionPolicy Bypass -File ".\revertir_ip.ps1"
            cmd.exe /c pause
        }
        "7" {
            Write-Host "`n  [!] Restaurando adaptador a modo DHCP..." -ForegroundColor Yellow
            powershell -ExecutionPolicy Bypass -File ".\revertir_ip.ps1"
            cmd.exe /c pause
        }
        "0" { return }
    }
} while ($true)


# =====================================================================
# SUB-MENU: GESTION DE SWITCHES POE 2.5G - CUERVO
# =====================================================================
$host.ui.RawUI.WindowTitle = "SUB-MENU: GESTION DE SWITCHES POE 2.5G - CUERVO"

function Mostrar-MenuPoe25 {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"; $G = "Green"

    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |  SUB-MENU: GESTION DE SWITCHES POE 2.5G                |" -ForegroundColor $W
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host "  |                                                          |" -ForegroundColor $M
    
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  [ PUERTOS ]                                             " -NoNewline -ForegroundColor $B; Write-Host "|" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  1. Equipo Nuevo Puerto 1        3. Config. Puerto 1     " -NoNewline -ForegroundColor $W; Write-Host "|" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  2. Equipo Nuevo Puerto 8        4. Config. Puerto 8     " -NoNewline -ForegroundColor $W; Write-Host "|" -ForegroundColor $M
    
    Write-Host "  |                                                          |" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  [ AUTOMATIZACION ]                                      " -NoNewline -ForegroundColor $B; Write-Host "|" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  5. CONFIGURACION EN LOTE (MASIVO)                       " -NoNewline -ForegroundColor $G; Write-Host "|" -ForegroundColor $M
    
    Write-Host "  |                                                          |" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  [ RED / IP ]                                            " -NoNewline -ForegroundColor $B; Write-Host "|" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  6. Configurar IP Fija (192.168.18.2)                    " -NoNewline -ForegroundColor $C; Write-Host "|" -ForegroundColor $M
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  7. Revertir IP a DHCP (Internet)                        " -NoNewline -ForegroundColor $C; Write-Host "|" -ForegroundColor $M

    Write-Host "  |                                                          |" -ForegroundColor $M
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    
    Write-Host "  |" -NoNewline -ForegroundColor $M; Write-Host "  0. Salir al menu principal                              " -NoNewline -ForegroundColor $Y; Write-Host "|" -ForegroundColor $M
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opcion: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuPoe25
    $opcion = Read-Host

    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Iniciando proceso para puerto 1 (Nuevo)..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poe_25g_MASTER.ps1"
            cmd.exe /c pause
        }
        "2" {
            Write-Host "`n  [!] Iniciando proceso para Puerto 8 (Nuevo)..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poe2.5puerto8nuevo.ps1"
            cmd.exe /c pause
        }
        "3" {
            Write-Host "`n  [!] Iniciando Cambio de Firmware Puerto 1..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\puerto1reintegro.ps1"
            cmd.exe /c pause
        }
        "4" {
            Write-Host "`n  [!] Iniciando Cambio de Configuracion Puerto 8..." -ForegroundColor Cyan
            powershell -ExecutionPolicy Bypass -File ".\poeport82.5.ps1"
            cmd.exe /c pause
        }
        "5" {
            Write-Host "`n  [!] Iniciando Configuracion en Lote (2.5Gb)..." -ForegroundColor Green
            python ".\Poe_2.5masivo.py"
            cmd.exe /c pause
        }
        "6" {
            Write-Host "`n  [!] Aplicando IP Estatica Definitiva..." -ForegroundColor Green
            powershell -ExecutionPolicy Bypass -File ".\Configurar Ip poe.ps1"
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

. ../core/notify_tools.ps1
# =====================================================================
# SUB-MENU: PHANTOM F2 NUEVOS - CUERVO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "SUB-MENU: PHANTOM F2 NUEVOS - CUERVO"

# --- DEFINICION DE CARACTERES ESPECIALES ---
$TL = [char]0x2554; $H = [char]0x2550; $TR = [char]0x2557; $V = [char]0x2551
$ML = [char]0x2560; $MR = [char]0x2563; $BL = [char]0x255A; $BR = [char]0x255D
$H_Line = New-Object String ($H, 58)

$Rocket = "$([char]0xD83D)$([char]0xDE80)"; $Search = "$([char]0xD83D)$([char]0xDD0D)"
$Exit = "$([char]0x274C)"; $Ghost = "$([char]0xD83D)$([char]0xDC7B)"; $Box = "$([char]0xD83D)$([char]0xDCE6)"

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $Y = "Yellow"; $C = "Cyan"

    Write-Host ""
    Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "           $Ghost SUB-MENU: PHANTOM F2 NUEVOS          " -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  1. $Rocket EJECUTAR PHANTOM NUEVOS (Flash + Limpiar)" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  2. $Search VERIFICAR EN PORTAL (macs.txt de raiz)" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
    Write-Host "  $V" -NoNewline -ForegroundColor $M; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  0. $Exit VOLVER AL MENU PRINCIPAL" -NoNewline -ForegroundColor $Y; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $BL$H_Line$BR" -ForegroundColor $M
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
        "0" { return }
    }
} while ($true)


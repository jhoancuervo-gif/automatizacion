. ../core/notify_tools.ps1
# =====================================================================
# MENU: PHANTOM REINTEGRO - CUERVO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "MENU PHANTOM REINTEGRO - CUERVO"

# --- DEFINICION DE CARACTERES ESPECIALES ---
$TL = [char]0x2554; $H = [char]0x2550; $TR = [char]0x2557; $V = [char]0x2551
$ML = [char]0x2560; $MR = [char]0x2563; $BL = [char]0x255A; $BR = [char]0x255D
$H_Line = New-Object String ($H, 58)

$Rocket = "$([char]0xD83D)$([char]0xDE80)"; $Search = "$([char]0xD83D)$([char]0xDD0D)"
$Exit = "$([char]0x274C)"; $Warning = "$([char]0x26A0)"; $Ghost = "$([char]0xD83D)$([char]0xDC7B)"

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $Y = "Yellow"; $C = "Cyan"

    Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "           $Ghost MENU: PHANTOM REINTEGRO              " -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  1. $Rocket REINTEGRO COMPLETO" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  2. $Search VERIFICAR MACS PORTAL" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  3. $Warning ELIMINAR MACS PORTAL" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
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
            Write-Host "`n  $Rocket [!] Ejecutando REINTEGRO COMPLETO..." -ForegroundColor Cyan
            python phantom_reintegro.py; Send-Notification -Title "Phantom" -Message "Proceso de Reintegro finalizado"
            Pause
        }
        "2" {
            Write-Host "`n  $Search --- VERIFICAR MACs PORTAL ---" -ForegroundColor Cyan
            if (Test-Path "..\macs.txt") {
                python verificar_macs_portal.py
            } else {
                Write-Host "  [-] ERROR: No hay archivo macs.txt." -ForegroundColor Red
            }
            Pause
        }
        "3" {
            Write-Host "`n  $Warning --- ELIMINAR MACs PORTAL ---" -ForegroundColor Red
            if (Test-Path "..\macs.txt") {
                python eliminar_macs_portal.py
            } else {
                Write-Host "  [-] ERROR: No hay archivo macs.txt." -ForegroundColor Red
            }
            Pause
        }
        "0" { return }
    }
} while ($true)

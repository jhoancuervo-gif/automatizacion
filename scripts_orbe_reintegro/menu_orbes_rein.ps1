. ../core/notify_tools.ps1
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "SUB-MENU: ORBE REINTEGRO - CUERVO"

# --- DEFINICION DE CARACTERES ESPECIALES ---
$TL = [char]0x2554; $H = [char]0x2550; $TR = [char]0x2557; $V = [char]0x2551
$ML = [char]0x2560; $MR = [char]0x2563; $BL = [char]0x255A; $BR = [char]0x255D
$H_Line = New-Object String ($H, 58)

$Orb = "$([char]0xD83D)$([char]0xDD2E)"; $Search = "$([char]0xD83D)$([char]0xDD0D)"
$Exit = "$([char]0x274C)"; $Warning = "$([char]0x26A0)"; $Sync = "$([char]0xD83D)$([char]0xDD04)"
$Bolt = "$([char]0x26A1)"; $Trash = "$([char]0xD83D)$([char]0xDDD1)"

function Mostrar-MenuOrbeR {
    Clear-Host
    $M = "Magenta"; $W = "White"; $Y = "Yellow"; $C = "Cyan"; $B = "DarkBlue"

    Write-Host ""
    Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "           $Orb SUB-MENU: ORBE REINTEGRO               " -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  [ $Bolt OPERACIONES ]" -NoNewline -ForegroundColor $B; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  1. $Sync Ejecutar Reintegro (Flashear + Reporte)" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  2. $Search Verificar en Portal (macs.txt)" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  3. $Trash Eliminar del Portal (macs.txt)" -NoNewline -ForegroundColor $W; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    
    Write-Host "  $V" -NoNewline -ForegroundColor $M; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V " -NoNewline -ForegroundColor $M; Write-Host "  0. $Exit VOLVER AL MENU PRINCIPAL" -NoNewline -ForegroundColor $Y; [Console]::CursorLeft = 61; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $BL$H_Line$BR" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opcion: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-MenuOrbeR
    $opcion = Read-Host
    switch ($opcion) {
        "1" {
            Write-Host "`n  [!] Iniciando proceso de flasheo de Orbes..." -ForegroundColor Cyan
            python orbe_reintegro.py; Send-Notification -Title "Orbe Reintegro" -Message "Proceso de Reintegro finalizado"
            Write-Host "`n  [+] Flasheo finalizado. Reporte abierto en Bloc de notas." -ForegroundColor Green
            Pause
        }
        "2" {
            Write-Host "`n  [!] Consultando portal para equipos en macs.txt..." -ForegroundColor Cyan
            python ../core/portal_tools.py verify --file ../macs.txt
            Pause
        }
        "3" {
            Write-Host "`n  [!] Iniciando borrado en portal para equipos en macs.txt..." -ForegroundColor Red
            python ../core/eliminar_macs.py
            Pause
        }
        "0" { return }
    }
} while ($true)



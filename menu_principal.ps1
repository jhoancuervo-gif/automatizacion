# =====================================================================
# SISTEMA DE AUTOMATIZACION PRO - BARRA DINAMICA & TECLADO
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "Automation Station - $env:USERNAME"

$RootPath = $PSScriptRoot
$EnvPath = Join-Path $RootPath ".env"

# --- DEFINICION DE CARACTERES ESPECIALES (MODO COMPATIBLE) ---
$TL = [char]0x2554; $H = [char]0x2550; $TR = [char]0x2557; $V = [char]0x2551
$ML = [char]0x2560; $MR = [char]0x2563; $BL = [char]0x255A; $BR = [char]0x255D
$H_Line = New-Object String ($H, 58) # Ancho exacto para que todo cuadre

$Rocket = "$([char]0xD83D)$([char]0xDE80)"; $Sat = "$([char]0xD83D)$([char]0xDCE1)"
$Ghost = "$([char]0xD83D)$([char]0xDC7B)"; $Search = "$([char]0xD83D)$([char]0xDD0D)"
$Orb = "$([char]0xD83D)$([char]0xDD2E)"; $TV = "$([char]0xD83D)$([char]0xDCFA)"
$Gear = "$([char]0x2699)"; $Globe = "$([char]0xD83C)$([char]0xDF10)"
$Exit = "$([char]0x274C)"; $User = "$([char]0xD83D)$([char]0xDC64)"
$PC = "$([char]0xD83D)$([char]0xDCBB)"; $Cal = "$([char]0xD83D)$([char]0xDCC5)"
$Wrench = "$([char]0xD83D)$([char]0xDD27)"

# Cachear IP una sola vez al cargar la aplicacion
$script:IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Ethernet*" -or $_.InterfaceAlias -like "*Wi-Fi*" } | Select-Object -First 1).IPAddress

# --- DEFINICION DE NOMBRE VISUAL (MAPEO) ---
$EquipoMapeo = @{
    "MPC-1OCAK8IK9CP" = "Rey"
    "DESKTOP-PT8UMBI" = "Cuervonv"
    "ALVARO"          = "Alvaro"
    "DESKTOP-4D3P5N2" = "Esteban"
    "MPC-17KT4458H7R" = "Kevin"
    "DESKTOP-7D3G6V0" = "Felipe"
    "DESKTOP-R1IDN86" = "Paula Andrea"
    "MPC-71225UVI7HG" = "Bryan"
    "USUARIO-IO29QUF" = "FlechasJuan"
    "DESKTOP-5FNCEON" = "Yeison"
    "WINDOWS-OBOHUKI" = "Santiago"
    "MPC-A5584AEIOOK" = "Oscar"
    "MPC-175K2LHCBFV" = "Juan Marin"
}
$script:NombreVisual = $env:COMPUTERNAME
if ($EquipoMapeo.ContainsKey($env:COMPUTERNAME)) {
    $script:NombreVisual = $EquipoMapeo[$env:COMPUTERNAME]
}

# --- NOTIFICACION DE INICIO (DISCORD WEBHOOK) ---
try {
    $WebhookURL = "https://discord.com/api/webhooks/1501650686700425389/Vovrg4DTz1WBb3yzzyn2h8xsiCNIWIia33P7ANR-3q_WMahR8LwqfftdeUIXi7VrSAMy"
    $Payload = @{
        embeds = @(
            @{
                title  = "$Rocket Estacion de Trabajo Activa"
                color  = 5814783
                fields = @(
                    @{ name = "$User Usuario"; value = "**$env:USERNAME**"; inline = $true }
                    @{ name = "$PC Equipo"; value = "**$script:NombreVisual**"; inline = $true }
                    @{ name = "$Globe IP Local"; value = "$($script:IP)"; inline = $true }
                    @{ name = "$Cal Fecha y Hora"; value = (Get-Date -Format "dd/MM/yyyy HH:mm:ss"); inline = $false }
                )
                footer = @{ text = "Sistema de Automatizacion - Soluciones Cuervo" }
            }
        )
    } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri $WebhookURL -Method Post -Body $Payload -ContentType 'application/json' -ErrorAction SilentlyContinue
}
catch { }

function Ejecutar-Herramienta {
    param([string]$SubDir, [string]$ScriptName)
    $Path = Join-Path $RootPath $SubDir
    if (Test-Path $Path) {
        Push-Location $Path
        if ($ScriptName.EndsWith(".bat")) { cmd.exe /c $ScriptName }
        elseif ($ScriptName.EndsWith(".ps1")) { & .\$ScriptName }
        Pop-Location
    }
    else { 
        Write-Host "`n  [!] ERROR: Carpeta '$SubDir' no encontrada." -ForegroundColor Red
        Pause 
    }
}

function Mostrar-Menu {
    Clear-Host
    $M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $B = "DarkBlue"
    $Fecha = Get-Date -Format "HH:mm:ss"
    Write-Host "  IP: $($script:IP.PadRight(15)) | HOST: $($script:NombreVisual.PadRight(15)) | $Fecha" -ForegroundColor $C
    Write-Host ""
    
    # RENDERIZADO PIXEL-PERFECT
    Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  $Rocket  SISTEMA DE AUTOMATIZACION - ESTACION DE TRABAJO     " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V                                                          $V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $Sat POE'S ]                    [ $Ghost PHANTOM'S ]        " -NoNewline -ForegroundColor $B; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  1. Switch PoE 1.0 Gb             4. Phantom F2 Reintegro" -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  2. Switch PoE 2.5 Gb             5. Phantom F2 Nuevos   " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  3. $Search Verificar Puertos          6. Phantom Nuevos      " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "                                   7. Phantom Reintegro   " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V                                                          $V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $Search MONITOREO ]                [ $Orb ORB'S ]            " -NoNewline -ForegroundColor $B; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  10. $TV TV BOX                    8. Orbes Nuevas        " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "                                   9. Orbes Reintegro     " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V                                                          $V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $Gear CONFIGURACION ]                                     " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  11. Instalar Dependencias (Nueva PC)                    " -NoNewline -ForegroundColor $Y; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  12.$Wrench Reparar Red / Reset Stack (netsh)                 " -NoNewline -ForegroundColor $C; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  0. $Exit Salir                                             " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $BL$H_Line$BR" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione una opcion: " -NoNewline -ForegroundColor $W
}

do {
    Mostrar-Menu
    $opcion = Read-Host
    switch ($opcion) {
        "1" { Ejecutar-Herramienta "scripts_poe_1gb" "iniciarfirmPOE.ps1" }
        "2" { Ejecutar-Herramienta "scripts_poe_2_5gb" "iniciarfirmPOE2.5.ps1" }
        "3" { $f = Join-Path $RootPath "check_puerto_poe.ps1"; if (Test-Path $f) { & $f } else { Write-Host "Error"; Pause } }
        "4" { Ejecutar-Herramienta "scripts_phantom_f2_reintegro" "menu_phantomf2.ps1" }
        "5" { Ejecutar-Herramienta "scripts_phantom_f2" "menu_phantomf2nuevos.ps1" }
        "6" { Ejecutar-Herramienta "scripts_phantom_nuevos" "menu_phantom_nuevos.ps1" }
        "7" { Ejecutar-Herramienta "scripts_phantom_reintegro" "menu_phantom.ps1" }
        "8" { Ejecutar-Herramienta "scripts_orbes_nuevas" "menu_orbes_nuevas.ps1" }
        "9" { Ejecutar-Herramienta "scripts_orbe_reintegro" "menu_orbes_rein.ps1" }
        "10" { Ejecutar-Herramienta "configurartvbox_sinapp" "configurar_sinapp.bat" }
        "11" { $L = Join-Path $RootPath "lanzador.bat"; if (Test-Path $L) { Start-Process "$L" -Wait } else { Write-Host "No se encuentra lanzador.bat"; Pause } }
        "12" { $R = Join-Path $RootPath "core\reparar_red.ps1"; if (Test-Path $R) { & $R } else { Write-Host "Error"; Pause } }
        "0" { exit }
    }
} while ($true)

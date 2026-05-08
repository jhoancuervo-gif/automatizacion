# =====================================================================
# MONITOR POE - NAVEGACIÓN PREMIUM (SELECT -> MONITOR)
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.ui.RawUI.WindowTitle = "POE Port Monitor - $env:USERNAME"

# --- DEFINICION DE CARACTERES Y COLORES ---
$TL = [char]0x2554; $H = [char]0x2550; $TR = [char]0x2557; $V = [char]0x2551
$ML = [char]0x2560; $MR = [char]0x2563; $BL = [char]0x255A; $BR = [char]0x255D
$H_Line = New-Object String ($H, 58)

# Emojis via Unicode
$Rocket = "$([char]0xD83D)$([char]0xDE80)"; $Search = "$([char]0xD83D)$([char]0xDD0D)"
$Plug = "$([char]0xD83D)$([char]0xDD0C)"; $Bolt = "$([char]0x26A1)"
$Exit = "$([char]0x274C)"; $Gear = "$([char]0x2699)"

$M = "Magenta"; $W = "White"; $C = "Cyan"; $Y = "Yellow"; $G = "Green"; $R = "Red"; $B = "DarkBlue"

# Cachear Hostname y mapeo
$EquipoMapeo = @{ "MPC-1OCAK8IK9CP" = "Rey"; "DESKTOP-PT8UMBI" = "Cuervonv"; "ALVARO" = "Alvaro"; "DESKTOP-4D3P5N2" = "Esteban"; "MPC-17KT4458H7R" = "Kevin"; "DESKTOP-7D3G6V0" = "Felipe"; "DESKTOP-R1IDN86" = "Paula Andrea"; "MPC-71225UVI7HG" = "Bryan"; "USUARIO-IO29QUF" = "FlechasJuan" }
$script:NombreVisual = if ($EquipoMapeo.ContainsKey($env:COMPUTERNAME)) { $EquipoMapeo[$env:COMPUTERNAME] } else { $env:COMPUTERNAME }

function Get-AdapterIP {
    param([int]$Index)
    if ($Index -gt 0) {
        $ip = (Get-NetIPAddress -InterfaceIndex $Index -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
        return if ($null -eq $ip) { "---.---.---.---" } else { $ip }
    }
    # IP por defecto si no hay seleccion (el primer ethernet/wifi con IP)
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "*Ethernet*" -or $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*WiFi*" } | Select-Object -First 1).IPAddress
    return if ($null -eq $ip) { "---.---.---.---" } else { $ip }
}

function Mostrar-Encabezado {
    param([int]$Index = 0)
    $Fecha = Get-Date -Format "HH:mm:ss"
    $ipStr = Get-AdapterIP -Index $Index
    Write-Host "  IP: $($ipStr.PadRight(15)) | HOST: $($script:NombreVisual.PadRight(15)) | $Fecha" -ForegroundColor $C
}

while ($true) {
    Clear-Host
    Mostrar-Encabezado
    Write-Host ""
    
    Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  $Search  SELECCION DE PUERTO PARA MONITOREO                  " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M

    # Obtener adaptadores fisicos (Ordenados para estabilidad)
    $adapters = @(Get-NetAdapter -Physical | Where-Object { 
            $_.InterfaceDescription -notmatch "Wi-Fi|WiFi|Wireless|Bluetooth|Tailscale|vEthernet|Virtual|VPN|Pseudo|Loopback" -and
            $_.Name -notmatch "Wi-Fi|WiFi"
        } | Sort-Object InterfaceIndex)

    if ($adapters.Count -eq 0) {
        Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [!] No se encontraron puertos fisicos disponibles." -NoNewline -ForegroundColor $R; Write-Host "$V" -ForegroundColor $M
    }
    else {
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            $status = $adapters[$i].Status
            $statusChar = if ($status -eq "Up") { "$G" } else { "$R" }
            $id = ($i + 1).ToString().PadLeft(2)
            $name = $adapters[$i].Name.PadRight(15)
            $desc = $adapters[$i].InterfaceDescription
            if ($desc.Length -gt 30) { $desc = $desc.Substring(0, 27) + "..." }
            $desc = $desc.PadRight(30)

            Write-Host "  $V" -NoNewline -ForegroundColor $M
            Write-Host "  [$id]" -NoNewline -ForegroundColor $Y
            Write-Host " $name" -NoNewline -ForegroundColor $W
            Write-Host " | " -NoNewline -ForegroundColor $M
            Write-Host "$($status.ToString().PadRight(6))" -NoNewline -ForegroundColor $statusChar
            Write-Host " | $desc " -NoNewline -ForegroundColor "DarkGray"
            Write-Host "$V" -ForegroundColor $M
        }
    }

    Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  0. $Exit Volver al Menu Principal                          " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
    Write-Host "  $BL$H_Line$BR" -ForegroundColor $M
    Write-Host ""
    Write-Host "  >> Seleccione un ID: " -NoNewline -ForegroundColor $W
    
    $selection = Read-Host
    if ($selection -eq "0") { exit }

    if (-not [int]::TryParse($selection, [ref]$idx) -or $idx -lt 1 -or $idx -gt $adapters.Count) {
        Write-Host "`n  [!] Seleccion no valida." -ForegroundColor $R
        Start-Sleep -Seconds 1
        continue
    }

    $TargetAdapterObj = $adapters[$idx - 1]
    $TargetName = $TargetAdapterObj.Name
    $TargetIndex = $TargetAdapterObj.InterfaceIndex
    $TargetDesc = $TargetAdapterObj.InterfaceDescription

    Write-Host "`n  [+] Seleccionado: $TargetName" -ForegroundColor $G
    Start-Sleep -Milliseconds 300

    # BUCLE DE MONITOREO
    while ($true) {
        if ([console]::KeyAvailable) {
            $key = [console]::ReadKey($true)
            if ($key.Key -eq 'Escape' -or $key.Key -eq 'M') { break }
        }

        Clear-Host
        Mostrar-Encabezado -Index $TargetIndex
        Write-Host ""
        
        Write-Host "  $TL$H_Line$TR" -ForegroundColor $M
        Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  $Plug  MONITOREANDO: $($TargetName.PadRight(34))    " -NoNewline -ForegroundColor $C; Write-Host    "$V" -ForegroundColor $M
        Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  MODELO: $($TargetDesc.PadRight(42))      " -NoNewline -ForegroundColor "DarkGray"; Write-Host "$V" -ForegroundColor $M
        Write-Host "  $ML$H_Line$MR" -ForegroundColor $M

        $adapter = Get-NetAdapter -InterfaceIndex $TargetIndex
        
        if ($adapter.Status -ne "Up") {
            Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $R$Exit$W ] ESTADO: DESCONECTADO / SIN SENAL              " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
            Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  Esperando conexion fisica en el puerto...           " -NoNewline -ForegroundColor $Y; Write-Host "$V" -ForegroundColor $M
        } 
        else {
            $speed = $adapter.LinkSpeed
            if ($speed -match "Gbps") {
                Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $G$Bolt$W ] NEGOCIACION:$($speed.PadRight(27))" -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
                Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  ESTADO: EQUIPO OPERATIVO (ALTA VELOCIDAD)               " -NoNewline -ForegroundColor $G; Write-Host "$V" -ForegroundColor $M
            } 
            elseif ($speed -match "Mbps") {
                $speedValue = [int]($speed -replace "[^\d]", "")
                if ($speedValue -le 100) {
                    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $R!$W ] NEGOCIACION: $($speed.PadRight(27)) " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
                    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  ERROR: Puerto Base 100. Equipo defectuoso.          " -NoNewline -ForegroundColor $W -BackgroundColor $R; Write-Host "$V" -ForegroundColor $M
                }
                else {
                    Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  [ $Y-$W ] NEGOCIACION INTERMEDIA: $($speed.PadRight(21)) " -NoNewline -ForegroundColor $W; Write-Host "$V" -ForegroundColor $M
                }
            }
        }

        Write-Host "  $ML$H_Line$MR" -ForegroundColor $M
        Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  Presione 'M' para volver a la lista de puertos.         " -NoNewline -ForegroundColor "Gray"; Write-Host "$V" -ForegroundColor $M
        Write-Host "  $V" -NoNewline -ForegroundColor $M; Write-Host "  Presione 'ESC' para salir al menu.                      " -NoNewline -ForegroundColor "Gray"; Write-Host "$V" -ForegroundColor $M
        Write-Host "  $BL$H_Line$BR" -ForegroundColor $M
        
        Start-Sleep -Milliseconds 500
    }
}
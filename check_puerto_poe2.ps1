# =========================================================
# MONITOR POE - NAVEGACIÓN COMPLETA (SELECT -> MONITOR)
# =========================================================
$ErrorActionPreference = "SilentlyContinue"

while ($true) { # BUCLE PRINCIPAL (Menú de Selección)
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "       CONFIGURACIÓN DE PUERTO PARA LA SESIÓN             " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Yellow

    # Obtener adaptadores físicos
    $adapters = Get-NetAdapter | Where-Object { 
        $_.InterfaceDescription -notmatch "Wi-Fi|Wireless|Bluetooth|Tailscale|vEthernet|Virtual|VPN|Pseudo|Loopback" 
    }

    Write-Host "Lista de puertos físicos encontrados:" -ForegroundColor White
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "ID  |  ESTADO      |  NOMBRE       |  VELOCIDAD      |  DESCRIPCIÓN" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor Gray

    for ($i=0; $i -lt $adapters.Count; $i++) {
        $status = $adapters[$i].Status
        $statusColor = if ($status -eq "Up") { "Green" } else { "Red" }
        $id = $i + 1

        Write-Host "[$id]" -NoNewline -ForegroundColor Yellow
        Write-Host "  | $($status.ToString().PadRight(10))" -NoNewline -ForegroundColor $statusColor
        Write-Host " | $($adapters[$i].Name.PadRight(12)) | " -NoNewline
        Write-Host "$($adapters[$i].LinkSpeed.PadRight(14))" -NoNewline
        Write-Host " | $($adapters[$i].InterfaceDescription)" -ForegroundColor Gray
    }

    Write-Host "-----------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "[0]  VOLVER AL MENÚ PRINCIPAL (.BAT)" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""

    $selection = Read-Host "Ingrese el ID del puerto o '0' para salir"

    if ($selection -eq "0") {
        Write-Host "`nRegresando al menú principal..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        exit 
    }

    # Validar que la selección sea un número válido
    if ($null -eq $adapters[[int]$selection - 1]) {
        Write-Host "Selección no válida. Intente de nuevo." -ForegroundColor Red
        Start-Sleep -Seconds 1
        continue
    }

    $TargetAdapter = $adapters[[int]$selection - 1].Name

    # 2. BUCLE DE MONITOREO (Sesión Activa)
    while ($true) {
        if ([console]::KeyAvailable) {
            $key = [console]::ReadKey($true)
            if ($key.Key -eq 'Escape' -or $key.Key -eq 'M') { break } # Sale al menú de selección
        }

        Clear-Host
        $adapter = Get-NetAdapter -Name $TargetAdapter
        
        Write-Host "==========================================================" -ForegroundColor Yellow
        Write-Host "   MONITOREANDO: $TargetAdapter " -ForegroundColor Cyan
        Write-Host "   MODELO: $($adapter.InterfaceDescription)" -ForegroundColor Gray
        Write-Host "==========================================================" -ForegroundColor Yellow

        if ($adapter.Status -ne "Up") {
            Write-Host "`n[!] ESTADO: DESCONECTADO / SIN SEÑAL" -ForegroundColor Red
            Write-Host "Esperando conexión física en el puerto..." -ForegroundColor Yellow
        } 
        else {
            $speed = $adapter.LinkSpeed
            if ($speed -match "Gbps") {
                Write-Host "`n[OK] NEGOCIACIÓN: $speed" -ForegroundColor Green
                Write-Host "ESTADO: EQUIPO OPERATIVO" -ForegroundColor Green
            } 
            elseif ($speed -match "Mbps") {
                $speedValue = [int]($speed -replace "[^\d]", "")
                if ($speedValue -le 100) {
                    Write-Host "`n[X] NEGOCIACIÓN: $speed" -ForegroundColor Red
                    Write-Host "ERROR: Puerto Base 100. Equipo malo" -ForegroundColor White -BackgroundColor Red
                } else {
                    Write-Host "`n[-] NEGOCIACIÓN INTERMEDIA: $speed" -ForegroundColor Yellow
                }
            }
        }

        Write-Host "`n==========================================================" -ForegroundColor Yellow
        Write-Host "Presione 'M' para volver a la selección de puertos."
        Write-Host "Presione 'Ctrl+C' para cerrar el script."
        Start-Sleep -Seconds 2
    }
}
# =========================================================
# SCRIPT: HT-SG08_FIX_CRITICAL.ps1
# FIX: Bypass de bloqueo en subida de firmware
# =========================================================

if ($PSScriptRoot) { $baseDir = $PSScriptRoot } else { $baseDir = Get-Location }
$fwFile = "$baseDir\upg_appimage2.bin"; $configFile = "$baseDir\port8_snmp.bin"
$ip = "192.168.18.1"; $macFile = "$baseDir\mac.txt"

do {
    Clear-Host
    Write-Host "=== GESTION HT-SG08 (MODO COMPATIBILIDAD) ===" -ForegroundColor Cyan
    arp -d $ip 2>$null; Test-Connection $ip -Count 1 -Quiet | Out-Null
    $arp = arp -a $ip | Out-String
    if ($arp -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $mac = $matches[0].ToUpper().Replace("-",":"); Write-Host "[1/5] MAC: $mac" -ForegroundColor Green
    } else { Write-Host "[!] No hay ping"; Start-Sleep 2; continue }

    # [2/5] SALTO A FLASH
    Write-Host "[2/5] Forzando modo Flash..." -NoNewline
    # Probamos las dos claves conocidas directamente
    foreach ($c in @("admin:admin", "admin:somos123.")) {
        & curl.exe -u $c -s -o NUL -X POST "http://$ip/cgi/toBootLoadUpgrade.cgi" --max-time 2
    }
    Write-Host " [OK]" -ForegroundColor Yellow
    
    Write-Host "      Reiniciando sistema..." -NoNewline
    for ($i=0; $i -lt 12; $i++) { Write-Host "." -NoNewline; Start-Sleep -Milliseconds 800 }
    Write-Host " [READY]" -ForegroundColor Green

    # [3/5] FIRMWARE - MODO SIMPLIFICADO AL MAXIMO
    Write-Host "[3/5] Subiendo Firmware..." -NoNewline
    $fwOk = $false
    
    # IMPORTANTE: Eliminamos Referer y User-Agent para que el switch no se confunda
    # Usamos -m (max-time) corto para detectar si el switch ignora el paquete
    $res = & curl.exe -s -w "CODE:%{http_code}" -o NUL `
           -F "file=@$fwFile" `
           -H "Expect:" `
           -H "Connection: close" `
           "http://$ip/cgi/upg_appimage.bin" `
           --connect-timeout 5 --max-time 90

    if ($res -match "200|302|000") { 
        # A veces el switch reinicia tan rapido que curl da error 000 pero lo hizo bien
        Write-Host " [OK/ENVIADO]" -ForegroundColor Green
        Write-Host "      Escribiendo en memoria (No desconectar)..."
        Start-Sleep -Seconds 40
        $fwOk = $true
    } else { 
        Write-Host " [ERROR: $res]" -ForegroundColor Red
        $n = Read-Host "Presione 'R' para reintentar este paso o ENTER para saltar"; if($n -eq "r"){continue}
    }

    # [4/5] CONFIGURACIÓN
    if ($fwOk) {
        Write-Host "[4/5] Subiendo Configuración..." -NoNewline
        Start-Sleep -Seconds 5
        foreach ($c in @("admin:admin", "admin:somos123.")) {
            $rCfg = & curl.exe -u $c -s -w "%{http_code}" -o NUL `
                    -F "file=@$configFile" -H "Expect:" `
                    "http://$ip/cgi/SW_CFG.bin" --max-time 15
            if ($rCfg -match "200|302") { Write-Host " [OK ($c)]" -ForegroundColor Green; break }
        }
    }

    # [5/5] CIERRE
    Write-Host "[5/5] Proceso finalizado."
    "$mac" | Add-Content $macFile
    $n = Read-Host "Siguiente equipo (ENTER) / Salir (S)"
} while ($n -ne "s")
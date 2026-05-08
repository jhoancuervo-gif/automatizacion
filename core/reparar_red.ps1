# =====================================================================
# SCRIPT DE REPARACION DE RED - AUTOMATION STATION
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"

function Show-Header {
    Clear-Host
    Write-Host "  ==================================================" -ForegroundColor Magenta
    Write-Host "     HERRAMIENTA DE DIAGNOSTICO Y REPARACION DE RED " -ForegroundColor White
    Write-Host "  ==================================================" -ForegroundColor Magenta
    Write-Host ""
}

Show-Header
Write-Host "  [!] Esta herramienta ejecutara comandos de limpieza profunda." -ForegroundColor Yellow
Write-Host "  [!] Algunos cambios podrian requerir un REINICIO del PC." -ForegroundColor Red
Write-Host ""
Write-Host "  Opciones disponibles:" -ForegroundColor Cyan
Write-Host "  1. Limpieza Rapida (ARP, DNS, Cache)" -ForegroundColor White
Write-Host "  2. Reset Profundo (Winsock, Stack IP) - Requiere Reinicio" -ForegroundColor White
Write-Host "  3. Diagnostico de Conexion (Ping 192.168.1.1 / 10.1)" -ForegroundColor White
Write-Host "  0. Volver al Menu Principal" -ForegroundColor White
Write-Host ""

$opcion = Read-Host "  Seleccione una opcion"

switch ($opcion) {
    "1" {
        Show-Header
        Write-Host "  [*] Limpiando cache ARP (Direcciones MAC)..." -NoNewline
        arp -d * > $null
        Write-Host " [OK]" -ForegroundColor Green
        
        Write-Host "  [*] Limpiando cache DNS..." -NoNewline
        ipconfig /flushdns > $null
        Write-Host " [OK]" -ForegroundColor Green

        Write-Host "  [*] Limpiando tabla de rutas..." -NoNewline
        route -f > $null
        Write-Host " [OK]" -ForegroundColor Green

        Write-Host "`n  [+] Limpieza completada satisfactoriamente." -ForegroundColor Green
        Pause
    }
    "2" {
        Show-Header
        Write-Host "  [!] ATENCION: El PC debera reiniciarse despues de esto." -ForegroundColor Red
        $confirm = Read-Host "  ¿Desea continuar? (S/N)"
        if ($confirm -eq "S" -or $confirm -eq "s") {
            Write-Host "  [*] Reiniciando Winsock..." -NoNewline
            netsh winsock reset | Out-Null
            Write-Host " [OK]" -ForegroundColor Green
            
            Write-Host "  [*] Reiniciando Stack TCP/IP..." -NoNewline
            netsh int ip reset | Out-Null
            Write-Host " [OK]" -ForegroundColor Green

            Write-Host "`n  [!] EXITO: Se recomienda reiniciar el equipo ahora." -ForegroundColor Yellow
            $reboot = Read-Host "  ¿Reiniciar ahora? (S/N)"
            if ($reboot -eq "S" -or $reboot -eq "s") {
                Restart-Computer
            }
        }
    }
    "3" {
        Show-Header
        $TargetIPs = @("192.168.1.1", "192.168.10.1")
        foreach ($IP in $TargetIPs) {
            Write-Host "`n  [*] Verificando conexion con $IP..." -ForegroundColor Cyan
            if (Test-Connection -ComputerName $IP -Count 2 -Quiet) {
                Write-Host "  [+] EXITOSO: El equipo ($IP) responde al ping." -ForegroundColor Green
            } else {
                Write-Host "  [-] FALLIDO: No hay respuesta de $IP." -ForegroundColor Red
            }
        }
        Write-Host "`n  [!] SUGERENCIA:" -ForegroundColor Yellow
        Write-Host "  1. Verifique su IP fija (Rango 1.X o 10.X)."
        Write-Host "  2. Asegurese de que el cable este conectado."
        Write-Host "  3. Intente la Opcion 1 (Limpieza Rapida) para borrar el cache ARP."
        Pause
    }
    "0" { return }
}

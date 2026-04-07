# =====================================================================
# [PASO 0] GARANTIZAR PERMISOS DE ADMINISTRADOR
# =====================================================================
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Obtener los adaptadores de red activos
$interfaces = Get-NetAdapter | Where-Object Status -eq "Up"

if ($interfaces.Count -eq 0) {
    Write-Host "[-] No se detectaron adaptadores de red conectados." -ForegroundColor Red
    Pause; exit
}

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "   CONFIGURACIÓN IP POE (SOLUCIÓN TOTAL)  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Yellow

for ($i = 0; $i -lt $interfaces.Count; $i++) {
    Write-Host "[$i] $($interfaces[$i].Name) - $($interfaces[$i].InterfaceDescription)"
}

$choice = Read-Host "`nSeleccione el número del adaptador"

if ($choice -lt $interfaces.Count -and $choice -ge 0) {
    $adapterName = $interfaces[$choice].Name
    Write-Host "`nProcesando $adapterName..." -ForegroundColor Yellow

    try {
        # A. Forzar desactivación de DHCP
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Disabled -ErrorAction SilentlyContinue

        # B. LIMPIEZA PROFUNDA (El secreto de la estabilidad)
        Write-Host "[*] Eliminando IPs y Rutas antiguas..." -ForegroundColor Gray
        # Borra cualquier IP IPv4 existente
        Remove-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        # Borra cualquier Puerta de Enlace (Ruta por defecto) previa
        Remove-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

        # C. APLICAR IP Y MÁSCARA
        Write-Host "[+] Aplicando IP: 192.168.18.2 ..." -ForegroundColor Cyan
        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.18.2 -PrefixLength 24 -Confirm:$false -ErrorAction Stop

        # D. APLICAR PUERTA DE ENLACE POR SEPARADO (Para evitar conflictos)
        Write-Host "[+] Aplicando Gateway: 192.168.18.1 ..." -ForegroundColor Cyan
        New-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -NextHop 192.168.18.1 -ErrorAction Stop

        # E. Configurar DNS de Google (Opcional pero recomendado para que no falle el adaptador)
        Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses ("8.8.8.8") -ErrorAction SilentlyContinue

        Write-Host "`n[✔] ¡CONFIGURACIÓN EXITOSA!" -ForegroundColor Green
        Write-Host "IP: 192.168.18.2 | GW: 192.168.18.1" -ForegroundColor White
    }
    catch {
        Write-Host "`n[!] ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[?] Sugerencia: Desconecta y reconecta el cable de red y vuelve a intentar." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[-] Selección no válida." -ForegroundColor Red
}

Write-Host "`n[🔔] Presiona ENTER para finalizar..."
Pause
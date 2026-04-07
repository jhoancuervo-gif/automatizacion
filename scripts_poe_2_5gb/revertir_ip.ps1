# =========================================================
# SCRIPT: revertir_ip.ps1 (Restaurar DHCP)
# =========================================================

# Validación de Administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Obtener adaptadores conectados
$interfaces = Get-NetAdapter | Where-Object Status -eq "Up"

if ($interfaces.Count -eq 0) {
    Write-Host "[-] No se detectaron adaptadores conectados." -ForegroundColor Red
    return
}

Write-Host "--- SELECCIONE ADAPTADOR PARA VOLVER A DHCP ---" -ForegroundColor Cyan
for ($i = 0; $i -lt $interfaces.Count; $i++) {
    Write-Host "[$i] $($interfaces[$i].Name) - $($interfaces[$i].InterfaceDescription)"
}

$choice = Read-Host "`nIngrese el número del adaptador"

if ($choice -lt $interfaces.Count -and $choice -ge 0) {
    $adapterName = $interfaces[$choice].Name
    try {
        Write-Host "Limpiando configuracion en $adapterName..." -ForegroundColor Yellow
        # Habilitar DHCP e IP automática
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction Stop
        # Resetear DNS a modo automático
        Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction Stop
        
        Write-Host "`n[+] EXITO: El adaptador ahora esta en modo DHCP (Internet)." -ForegroundColor Green
    }
    catch {
        Write-Host "`n[-] Error al restaurar: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[-] Seleccion no valida." -ForegroundColor Red
}
# quitar_ip.ps1 - Limpieza TOTAL de IP y Gateway
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs  
    Exit  
}

$interfaces = Get-NetAdapter | Where-Object Status -eq "Up"
Write-Host "--- SELECCIONA EL ADAPTADOR PARA LIMPIEZA TOTAL ---" -ForegroundColor Cyan
for ($i = 0; $i -lt $interfaces.Count; $i++) {
    Write-Host "[$i] $($interfaces[$i].Name)"
}

$choice = Read-Host "`nIngresa el número"

if ($choice -lt $interfaces.Count -and $choice -ge 0) {
    $adapterName = $interfaces[$choice].Name
    $adapterIndex = $interfaces[$choice].InterfaceIndex
    Write-Host "Limpiando todos los campos en $adapterName..." -ForegroundColor Yellow
    
    # 1. Elimina todas las IPs estáticas
    Remove-NetIPAddress -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
    
    # 2. ELIMINA LA PUERTA DE ENLACE (Gateway) específicamente
    # Esto limpia el campo que se quedó pegado en tu imagen
    Remove-NetRoute -InterfaceIndex $adapterIndex -NextHop "192.168.18.1" -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $adapterIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

    # 3. Regresa el adaptador a modo DHCP (Automático)
    Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled
    Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses
    
    Write-Host "¡Limpieza completada! Todos los campos están en automático." -ForegroundColor Green
}
pause
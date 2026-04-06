if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs  
    Exit  
}
# 1. Obtener los adaptadores de red que están habilitados
$interfaces = Get-NetAdapter | Where-Object Status -eq "Up"

Write-Host "--- Selecciona el adaptador de red ---" -ForegroundColor Cyan
for ($i = 0; $i -lt $interfaces.Count; $i++) {
    Write-Host "[$i] $($interfaces[$i].Name) - $($interfaces[$i].InterfaceDescription)"
}

# 2. Elegir el índice del adaptador
$choice = Read-Host "`nIngresa el número del adaptador a configurar"

if ($choice -lt $interfaces.Count -and $choice -ge 0) {
    $adapterName = $interfaces[$choice].Name
    Write-Host "Configurando $adapterName..." -ForegroundColor Yellow

    # 3. Aplicar IP, Máscara (PrefixLength 24 es 255.255.255.0) y Puerta de enlace
    try {
        # Eliminamos cualquier configuración previa de IP estática/DHCP para evitar conflictos
        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.18.2 -PrefixLength 24 -DefaultGateway 192.168.18.1 -ErrorAction Stop
        
        Write-Host "¡Configuración aplicada con éxito!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Es posible que la IP ya esté configurada o necesites permisos de Administrador." -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
else {
    Write-Host "Selección inválida." -ForegroundColor Red
}

pause
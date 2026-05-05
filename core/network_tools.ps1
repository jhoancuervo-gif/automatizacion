function Set-PoEIP {
    param([string]$IP = "192.168.18.2", [string]$Gateway = "192.168.18.1")
    
    $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    if (-not $adapter) {
        Write-Host "  [-] No se detecto adaptador conectado." -ForegroundColor Red
        return $null
    }

    $adapterName = $adapter.Name
    Write-Host "  [+] Configurando IP fija ($IP) en $adapterName..." -ForegroundColor Cyan
    
    # Guardar estado actual (DHCP o Fija) para revertir luego
    $oldConfig = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 | Select-Object IPAddress, PrefixLength
    $isDhcp = (Get-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4).Dhcp -eq "Enabled"

    try {
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Disabled -ErrorAction SilentlyContinue
        Remove-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        
        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress $IP -PrefixLength 24 -Confirm:$false -ErrorAction Stop
        New-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -NextHop $Gateway -ErrorAction SilentlyContinue
        
        return @{ Adapter = $adapterName; IsDhcp = $isDhcp; OldConfig = $oldConfig }
    } catch {
        Write-Host "  [!] Error configurando IP: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Restore-IP {
    param($Config)
    if (-not $Config) { return }
    
    $adapterName = $Config.Adapter
    Write-Host "`n  [+] Restaurando red en $adapterName..." -ForegroundColor Yellow
    
    if ($Config.IsDhcp) {
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction SilentlyContinue
        Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction SilentlyContinue
    } else {
        # Si era fija, restaurar la que tenia (opcional, por ahora lo dejamos en DHCP por seguridad de internet)
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction SilentlyContinue
    }
    Write-Host "  [OK] Red restaurada." -ForegroundColor Green
}

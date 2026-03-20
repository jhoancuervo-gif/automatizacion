$targetAdapter = "Ethernet 2" # Cambia esto al nombre de tu puerto de pruebas

while ($true) {
    Clear-Host
    $adapter = Get-NetAdapter -Name $targetAdapter -ErrorAction SilentlyContinue
    
    if ($adapter) {
        $speed = $adapter.LinkSpeed
        $status = $adapter.Status

        Write-Host "=== MONITOREO DE NEGOCIACIÓN: $targetAdapter ===" -ForegroundColor Cyan
        
        if ($status -eq "Up") {
            if ($speed -eq "2.5 Gbps") {
                Write-Host "[ PASS ] NEGOCIACIÓN CORRECTA: $speed" -BackgroundColor Green -ForegroundColor Black
                [console]::Beep(1000, 200) # Pitido corto de éxito
            } elseif ($speed -eq "1 Gbps") {
                Write-Host "[ CHECK ] NEGOCIACIÓN LIMITADA: $speed" -BackgroundColor Yellow -ForegroundColor Black
            } else {
                Write-Host "[ FAIL ] NEGOCIACIÓN BAJA: $speed" -BackgroundColor Red
            }
        } else {
            Write-Host "[ WAIT ] DISPOSITIVO DESCONECTADO..." -ForegroundColor Gray
        }
    }
    Start-Sleep -Seconds 1
}
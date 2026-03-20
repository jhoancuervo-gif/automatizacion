# Ruta donde se guardará el log
$logPath = "$HOME\Desktop\log_negociacion.csv"

Write-Host "Esperando conexión para registro..." -ForegroundColor Cyan

while ($true) {
    $adapter = Get-NetAdapter -Name "Ethernet 2" # Ajustar nombre
    if ($adapter.Status -eq "Up") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $speed = $adapter.LinkSpeed
        
        # Guardar en CSV
        "$timestamp, $($adapter.Name), $speed" | Out-File -FilePath $logPath -Append
        
        Write-Host "✅ Registrado: $speed a las $timestamp" -ForegroundColor Green
        Write-Host "Desconecte el equipo para continuar..." -ForegroundColor Yellow
        
        # Esperar a que lo desconecten para no repetir el registro
        while ((Get-NetAdapter -Name "Ethernet 2").Status -eq "Up") { Start-Sleep -Seconds 1 }
        Write-Host "Puerto liberado. Siguiente equipo..." -ForegroundColor Gray
    }
    Start-Sleep -Seconds 1
}
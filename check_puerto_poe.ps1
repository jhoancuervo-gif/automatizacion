# =========================================================
# MONITOR DE NEGOCIACIÓN POE - FIJADO A ETHERNET 2
# =========================================================
$ErrorActionPreference = "SilentlyContinue"
$TargetAdapter = "Ethernet 2"

while ($true) {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "       MONITOREO DE NEGOCIACION: $TargetAdapter           " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Yellow

    # Buscamos específicamente el adaptador Ethernet 2
    $adapter = Get-NetAdapter -Name $TargetAdapter -ErrorAction SilentlyContinue

    if ($null -eq $adapter) {
        Write-Host "`n[!] ERROR: No se encuentra el adaptador '$TargetAdapter'." -ForegroundColor Red
        Write-Host "Verifique el nombre en 'Conexiones de Red'." -ForegroundColor Gray
    } 
    elseif ($adapter.Status -ne "Up") {
        Write-Host "`n[!] ESPERANDO CONEXION EN $TargetAdapter..." -ForegroundColor Gray
        Write-Host "Estado actual: $($adapter.Status)" -ForegroundColor Yellow
    } 
    else {
        $speed = $adapter.LinkSpeed
        
        # Lógica de Semáforo
        if ($speed -match "Gbps") {
            Write-Host "`n[OK] NEGOCIACION: $speed" -ForegroundColor Green
            Write-Host "ESTADO: EQUIPO OPERATIVO" -ForegroundColor Green
        } 
        elseif ($speed -match "Mbps") {
            # Extraemos el número de la velocidad (ej. "100 Mbps" -> 100)
            $speedValue = [int]($speed -replace "[^\d]", "")
            
            if ($speedValue -le 100) {
                Write-Host "`n[X] NEGOCIACION: $speed" -ForegroundColor Red
                Write-Host "----------------------------------------------------------" -ForegroundColor Red
                Write-Host "ERROR: Puerto Base 100. Equipo malo" -ForegroundColor White -BackgroundColor Red
                Write-Host "----------------------------------------------------------" -ForegroundColor Red
            } else {
                Write-Host "`n[-] NEGOCIACION INTERMEDIA: $speed" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "`n==========================================================" -ForegroundColor Yellow
    Write-Host "Presiona 'Ctrl+C' para detener el monitoreo."
    Start-Sleep -Seconds 2
}
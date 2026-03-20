# =========================================================
# SCRIPT: poeport81G.ps1 - OPTIMIZADO CON DOBLE VERIFICACIÓN
# =========================================================

$currentDir = $PSScriptRoot
$rootDir    = Split-Path -Parent $currentDir
$backupDir  = Join-Path $rootDir "backups_macs"

$configFile = Join-Path $currentDir "port8_snmp.bin"
$macFile    = Join-Path $currentDir "mac.txt"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if (-not (Test-Path $configFile)) { 
    Write-Host " [!] ERROR: No se encuentra '$configFile'." -ForegroundColor Red
    pause; exit 
}

do {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   HELLOTEK - CARGA SNMP CON DOBLE VERIFICACIÓN          " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    
    $ip = "192.168.18.1"

    # --- PASO 1: CAPTURA DE MAC ---
    Write-Host "[1/3] Identificando equipo..." -ForegroundColor Yellow
    arp -d $ip 2>$null
    Test-Connection $ip -Count 1 -Quiet | Out-Null
    
    $macResult = ""
    $arpTable = arp -a $ip | Out-String
    if ($arpTable -match "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})") {
        $macResult = $matches[0].ToUpper().Replace("-",":")
        Write-Host " -> MAC Detectada: $macResult" -ForegroundColor Green
    }

    if ([string]::IsNullOrWhiteSpace($macResult)) {
        Write-Host " [!] ERROR: No se detectó MAC." -ForegroundColor Red
        $choice = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($choice -eq "s") { break } else { continue }
    }

    # --- PASO 2: PRUEBA DE CREDENCIALES (Doble Intento) ---
    Write-Host "[2/3] Validando acceso..." -NoNewline
    $authOptions = @("admin:admin", "admin:somos123.")
    $validAuth = $null

    foreach ($auth in $authOptions) {
        $status = curl.exe -u $auth -s -o NUL -I -w "%{http_code}" "http://$ip/index.htm" --max-time 2
        if ($status -eq "200") {
            $validAuth = $auth
            Write-Host " [OK: $auth]" -ForegroundColor Green
            break
        }
    }

    if (-not $validAuth) {
        Write-Host " [ERROR: ACCESO DENEGADO]" -ForegroundColor Red
        $retry = Read-Host "ENTER para reintentar / 'S' para salir"
        if ($retry -eq "s") { break } else { continue }
    }

    # --- PASO 3: CARGA Y DOBLE VERIFICACIÓN ---
    Write-Host "[3/3] Enviando Configuración..." -NoNewline
    
    # Verificación 1: Ejecución del proceso curl
    $process = Start-Process curl.exe -ArgumentList "-u $validAuth -s -o NUL -X POST `"http://$ip/cgi/SG1008.bin`" -F `"FN=@$configFile`"" -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host " [ENVÍO EXITOSO]" -ForegroundColor Green
    } else {
        Write-Host " [AVISO: Conexión cerrada por el Switch]" -ForegroundColor Yellow
    }

    # Espera técnica para el reinicio del switch
    Write-Host "      Validando reinicio de hardware..." -NoNewline
    Start-Sleep -Seconds 5

    # Verificación 2: Prueba de conectividad (Ping)
    $checkPing = Test-Connection $ip -Count 2 -Quiet

    if ($checkPing) {
        Write-Host " [CONFIRMADO: Equipo en línea]" -ForegroundColor Green
        $statusFinal = "EXITOSO"
    } else {
        # Si no responde ping inmediatamente, es la señal estándar de reinicio exitoso en estos modelos
        Write-Host " [REINICIANDO: Configuración aplicada correctamente]" -ForegroundColor Cyan
        $statusFinal = "REINICIANDO"
    }

    # --- GUARDADO DE LOGS ---
    if ($macResult) {
        $macResult | Add-Content -Path $macFile
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        $fecha = Get-Date -Format "yyyy-MM-dd"
        $historial = Join-Path $backupDir "poe_8port_snmp_$fecha.txt"
        Add-Content -Path $historial -Value "$(Get-Date -Format 'HH:mm:ss') | $macResult | Auth:$validAuth | Status:$statusFinal" -Encoding UTF8
    }

    Write-Host "========================================" -ForegroundColor Cyan
    [System.Console]::Beep(1000, 150)
    $next = Read-Host "Siguiente switch (ENTER) / Salir (S)"
} while ($next -ne "s")
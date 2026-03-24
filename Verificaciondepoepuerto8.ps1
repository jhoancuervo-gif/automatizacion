# =========================================================
# SCRIPT: Auditoria_Final_Total_2.5G.ps1
# OBJETIVO: Verificar DHCP Filter y Port Forwarding
# CLAVES: 1. somos123. | 2. admin
# =========================================================

$ip = "192.168.18.1"
$user = "admin"
$claves = @("somos123.", "admin")

# Forzamos la consola a no cerrar ante errores y usar codificación correcta
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   AUDITORÍA DE CONFIGURACIÓN - VERIFICACIÓN PUERTO 8     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# --- [PASO 1] MOTOR DE ACCESO ---
$headers = $null
Write-Host "[1/3] Validando acceso al equipo..." -NoNewline

foreach ($pass in $claves) {
    # Generamos la credencial simulando un navegador
    $pair = "$($user):$($pass)"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
    
    $tempHeaders = @{ 
        Authorization = "Basic $encoded"
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
    }

    try {
        # Intentamos descargar la página de inicio para validar la clave
        $test = Invoke-WebRequest -Uri "http://$ip/index.htm" -Headers $tempHeaders -TimeoutSec 5 -UseBasicParsing
        if ($test.StatusCode -eq 200) {
            $headers = $tempHeaders
            Write-Host " [OK: $pass]" -ForegroundColor Green
            break
        }
    } catch {
        # Si da 401 (No autorizado), seguimos con la siguiente clave
        continue
    }
}

if (-not $headers) {
    Write-Host "`n[!!!] ERROR: El switch rechazó 'somos123.' y 'admin'." -ForegroundColor Red
    Write-Host "RECOMENDACIÓN: Desconecte el cable de red y vuelva a conectarlo." -ForegroundColor Yellow
    pause; exit
}

# --- [PASO 2] VERIFICACIÓN DHCP FILTER (Imagen 1) ---
Write-Host "[2/3] Verificando DHCP Filter..." -NoNewline
try {
    $dhcpPage = Invoke-WebRequest -Uri "http://$ip/dhcp_filter.htm" -Headers $headers -TimeoutSec 5 -UseBasicParsing
    $html = $dhcpPage.Content

    # Validamos: DHCP Filter ENABLE (value="1") y puerto 8 SIN marcar
    $isEnable = $html -match 'name="dhcp_en".*?value="1".*?checked'
    $port8Checked = $html -match 'name="port8".*?checked'

    if ($isEnable -and -not $port8Checked) {
        Write-Host " [CORRECTO]" -ForegroundColor Green
    } else {
        Write-Status = " [ADVERTENCIA: Revisar manual]" -ForegroundColor Yellow
        if (-not $isEnable) { Write-Host "     -> DHCP Filter no está en ENABLE." -ForegroundColor Gray }
        if ($port8Checked) { Write-Host "     -> El Puerto 8 está bloqueado (debe estar desmarcado)." -ForegroundColor Gray }
    }
} catch { Write-Host " [ERROR DE RED]" -ForegroundColor Red }

# --- [PASO 3] VERIFICACIÓN PORT FORWARD (Imagen 2) ---
Write-Host "[3/3] Verificando Port Forwarding..." -NoNewline
try {
    $fwdPage = Invoke-WebRequest -Uri "http://$ip/port_forward.htm" -Headers $headers -TimeoutSec 5 -UseBasicParsing
    $fhtml = $fwdPage.Content

    # Buscamos la existencia de las reglas FW1 a FW7 que apunten al puerto 8 (x,8,)
    $fwdOk = $true
    for ($i=1; $i -le 7; $i++) {
        if ($fhtml -notmatch "$i,8,") { $fwdOk = $false }
    }

    if ($fwdOk) {
        Write-Host " [CORRECTO]" -ForegroundColor Green
    } else {
        Write-Host " [INCOMPLETO: Faltan reglas]" -ForegroundColor Red
    }
} catch { Write-Host " [ERROR DE RED]" -ForegroundColor Red }

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "AUDITORÍA TERMINADA. Presione ENTER para salir..."
$null = [System.Console]::ReadLine()
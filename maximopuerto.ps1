$IP = "192.168.18.1"
$UrlPorts = "http://$IP/port_config.html"

# Credenciales a probar
$Creds = @("admin:admin", "admin:somos123.")

Function Test-Switch {
    Write-Host ">>> AUDITORÍA DE PUERTOS (MÉTODO DIRECTO) <<<" -ForegroundColor Cyan
    
    foreach ($Pair in $Creds) {
        Write-Host "[*] Intentando acceso con $Pair ..." -ForegroundColor Gray
        
        try {
            # Convertimos la credencial a formato Base64 (Requerido para Basic Auth)
            $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Pair)
            $Base64 = [System.Convert]::ToBase64String($Bytes)
            $Headers = @{ Authorization = "Basic $Base64" }

            # Intentamos entrar DIRECTAMENTE a la página de los puertos
            $Page = Invoke-WebRequest -Uri $UrlPorts -Headers $Headers -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            
            if ($Page.StatusCode -eq 200) {
                Write-Host "[+] ACCESO AUTORIZADO." -ForegroundColor Green
                Analizar-Puertos $Page.Content
                return # Salimos si funciona
            }
        } catch {
            Write-Host "[-] Intento fallido." -ForegroundColor Yellow
        }
    }
    Write-Host "❌ Error: No se pudo conectar. Verifica que el cable esté en un puerto de GESTIÓN." -ForegroundColor Red
}

Function Analizar-Puertos($HTML) {
    Write-Host "`nESTADO DE NEGOCIACIÓN:" -ForegroundColor White
    Write-Host "---------------------------------------"

    for ($n = 1; $n -le 8; $n++) {
        $PortID = "eth1.G" + $n
        if ($HTML -match "$PortID.*?>(.*?)<") {
            $Status = $Matches[1].Trim()
            
            $Col = "Red"
            if ($Status -eq "2.5G-FULL") { $Col = "Green" }
            elseif ($Status -eq "----") { $Col = "Gray" }

            Write-Host ("PUERTO {0}: {1}" -f $n, $Status) -ForegroundColor $Col
        }
    }
}

Test-Switch
Write-Host "`nFinalizado."
Read-Host "Presione ENTER para salir..."
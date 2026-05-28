# =====================================================================
# discord_notifier.ps1 - Helper para enviar errores a Discord desde PS
# =====================================================================
# Uso:
#   . "$RootPath\core\discord_notifier.ps1"
#   Send-DiscordError -Script "menu_principal/op8" -Message "Mensaje del error"
#
# Lee la URL del webhook desde la variable de entorno DISCORD_WEBHOOK_ERRORES
# (cargada por menu_principal.ps1 desde el .env). Silencioso si no esta
# configurada o si el envio falla (no rompe el script que la llama).
# =====================================================================

function Send-DiscordError {
    param(
        [Parameter(Mandatory = $true)][string]$Script,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $url = $env:DISCORD_WEBHOOK_ERRORES
    if (-not $url) { return }

    # Resolver el nombre amigable del equipo desde equipos.json (consistencia)
    $equipo = $env:COMPUTERNAME
    try {
        $here = $PSScriptRoot
        if (-not $here) { $here = (Get-Location).Path }
        $jsonPath = Join-Path $here "..\equipos.json"
        if (Test-Path $jsonPath) {
            $map = Get-Content $jsonPath -Raw | ConvertFrom-Json
            $nombre = $map.$env:COMPUTERNAME
            if ($nombre) { $equipo = $nombre }
        }
    }
    catch { }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Sanitizar el mensaje para JSON
        $msg = $Message
        if ($null -eq $msg) { $msg = "(sin detalle)" }
        $msg = $msg -replace '\\', '\\'
        $msg = $msg -replace '"', '\"'
        $msg = $msg -replace "`r", ''
        $msg = $msg -replace "`n", ' | '
        if ($msg.Length -gt 800) { $msg = $msg.Substring(0, 800) + '...' }

        $fecha = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        $usuario = $env:USERNAME

        # Color 15158332 = rojo (error). Sin emojis para evitar problemas
        # de codificacion del archivo .ps1 en PowerShell 5 (Windows-1252).
        $payload = '{"embeds":[{"title":"[ERROR] Falla en Script","color":15158332,"fields":[' +
                   '{"name":"Script","value":"**' + $Script + '**","inline":true},' +
                   '{"name":"Usuario","value":"**' + $usuario + '**","inline":true},' +
                   '{"name":"Equipo","value":"**' + $equipo + '**","inline":true},' +
                   '{"name":"Detalle del Error","value":"```' + $msg + '```","inline":false},' +
                   '{"name":"Fecha","value":"' + $fecha + '","inline":false}' +
                   '],"footer":{"text":"Sistema de Automatizacion - Soluciones Cuervo"}}]}'

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Content-Type", "application/json")
        $wc.UploadData($url, "POST", $bytes) | Out-Null
    }
    catch {
        # Silencio absoluto si Discord falla: no debemos romper el script principal
    }
}

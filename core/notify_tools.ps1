function Send-Notification {
    param(
        [string]$Title = "Automatización Cuervo",
        [string]$Message = "Proceso finalizado con éxito",
        [string]$Type = "Info" # Info, Warning, Error
    )

    Add-Type -AssemblyName System.Windows.Forms
    $global:notification = New-Object System.Windows.Forms.NotifyIcon
    
    # Usar icono del sistema según el tipo
    switch ($Type) {
        "Warning" { $icon = [System.Drawing.SystemIcons]::Warning }
        "Error"   { $icon = [System.Drawing.SystemIcons]::Error }
        default   { $icon = [System.Drawing.SystemIcons]::Information }
    }
    
    $global:notification.Icon = $icon
    $global:notification.Visible = $true
    $global:notification.ShowBalloonTip(5000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::$Type)
    
    # Limpieza suave para que no se quede el icono en la barra para siempre
    Start-Sleep -Seconds 6
    $global:notification.Dispose()
}

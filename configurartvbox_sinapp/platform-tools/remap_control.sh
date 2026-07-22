#!/system/bin/sh
echo "===$(date)=== [ARRANQUE] Centinela MDM despertando..." >> /data/local/remap.log

# Verificar disponibilidad de la app
cmd package list packages | grep -q com.android.mgstv && echo "$(date): [OK] Magis TV detectado." >> /data/local/remap.log || echo "$(date): [ALERTA] Magis TV no listo." >> /data/local/remap.log

# Trampa de salida real para capturar el apagado
trap 'echo "$(date): [REINICIO/APAGADO] El sistema ordeno detener el centinela. Guardando historial y cerrando." >> /data/local/remap.log; exit 0' SIGTERM SIGINT SIGHUP

# Bucle de escucha del control
while true; do
    getevent -c 1 /dev/input/event0 | grep -iq 01fe0172 && (
        echo "$(date): [EVENTO] Boton Google Play detectado. Lanzando Magis..." >> /data/local/remap.log
        am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n $(cmd package resolve-activity --brief com.android.mgstv | tail -n 1) >> /data/local/remap.log 2>&1
    )
    sleep 0.5
done

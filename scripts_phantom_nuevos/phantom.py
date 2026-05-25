#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
import sys
import json
import urllib.request
from datetime import datetime
from config import Config

import sys as _sys
_sys.path.insert(0, str(Config.BASE_DIR / "core"))
from mac_backup import MacBackup

_mac_backup = None

EQUIPO_MAPEO = {
    "MPC-1OCAK8IK9CP": "Rey",
    "DESKTOP-PT8UMBI": "Cuervonv",
    "ALVARO": "Alvaro",
    "DESKTOP-4D3P5N2": "Esteban",
    "MPC-17KT4458H7R": "Kevin",
    "DESKTOP-7D3G6V0": "Felipe",
    "DESKTOP-R1IDN86": "Paula Andrea",
    "MPC-71225UVI7HG": "Bryan",
    "USUARIO-IO29QUF": "FlechasJuan",
    "DESKTOP-5FNCEON": "Yeison",
    "WINDOWS-OBOHUKI": "Santiago",
    "MPC-A5584AEIOOK": "Oscar",
    "MPC-175K2LHCBFV": "Juan Marin",
    "DESKTOP-A-VALLE": "Jhon Vallejo"
}

def get_alias():
    """Obtiene el nombre mapeado del equipo actual"""
    hostname = os.getenv('COMPUTERNAME', 'Desconocido').upper()
    return EQUIPO_MAPEO.get(hostname, hostname)

def send_ingreso():
    """Notifica al canal de ingreso cuando alguien abre el script"""
    if not Config.WEBHOOK_INGRESO:
        return
    try:
        nombre_visual = get_alias()
        data = {
            "embeds": [{
                "title": "🟢 Ingreso al Script",
                "color": 5763719,  # Verde
                "fields": [
                    {"name": "📋 Script", "value": "**Phantom Nuevos**", "inline": True},
                    {"name": "💻 Operador", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "⏰ Hora de ingreso", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        req = urllib.request.Request(Config.WEBHOOK_INGRESO, data=json.dumps(data).encode('utf-8'),
                                     headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            pass
    except Exception:
        pass

def send_webhook(macs, meta):
    """Envía un resumen de las MACs flasheadas al canal de producción"""
    if not Config.WEBHOOK_PRODUCCION or not macs:
        return

    try:
        nombre_visual = get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs])
        
        data = {
            "embeds": [{
                "title": "👻 Lote de Phantoms Nuevos Flasheados",
                "color": 3066993,  # Verde
                "fields": [
                    {"name": "🔢 Equipos Procesados", "value": f"**{len(macs)} / {meta}**", "inline": True},
                    {"name": "💻 Procesado por", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "📍 Direcciones MAC", "value": lista_macs, "inline": False},
                    {"name": "⏰ Fecha", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        
        req = urllib.request.Request(Config.WEBHOOK_PRODUCCION, data=json.dumps(data).encode('utf-8'),
                                     headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            pass
    except Exception:
        pass

# Registro de la sesión
sesion_actual = []

async def process_device(ip, retries=3):
    """Procesa el equipo con lógica de reintentos"""
    for intento in range(1, retries + 1):
        try:
            options = asyncssh.SSHClientConnectionOptions(
                known_hosts=None, 
                login_timeout=8, # Tiempo de espera por intento
                signature_algs=['ssh-rsa', 'ssh-dss']
            )
            
            async with asyncssh.connect(ip, username='root', password=Config.SSH_PASSWORD, options=options) as conn:
                # Si conecta, extraemos MAC
                result = await conn.run("uci show network.@device[1].macaddr", check=True)
                mac_match = re.search(r"macaddr='([0-9a-fA-F:]{17})'", result.stdout)
                
                if mac_match:
                    mac = mac_match.group(1).upper()
                    
                    if mac in sesion_actual:
                        return "ESPERANDO_DESCONEXION", None

                    print(f"\n✨ [Intento {intento}] ¡Conectado! MAC: {mac}")
                    print(f"📤 Subiendo firmware...")
                    await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/Firmware_PHANTOM.bin'))
                    
                    sesion_actual.append(mac)
                    if _mac_backup:
                        _mac_backup.save(mac)
                    with open(Config.MAC_FILE, "w", encoding="utf-8") as f:
                        for m in sesion_actual:
                            f.write(f"{m}\n")
                    
                    print(f"🚀 Ejecutando flasheo...")
                    try:
                        await conn.run("sysupgrade -n /tmp/Firmware_PHANTOM.bin")
                    except: pass
                    
                    return "OK", mac
        except (asyncssh.Error, OSError):
            if intento < retries:
                # Silencio en la consola mientras reintenta
                await asyncio.sleep(2)
            else:
                return "SIN_CONEXION", None
    return "SIN_CONEXION", None

async def main():
    global _mac_backup
    _mac_backup = MacBackup(Config.CURRENT_DIR, "PHANTOM_NUEVOS", mac_file=Config.MAC_FILE)

    # Notificar ingreso al canal de Discord
    send_ingreso()

    # REGLA DE ORO: Limpiar raíz al iniciar
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()

    print(f"\n==========================================")
    print(f"   PHANTOM NUEVOS - MODO REINTENTOS 3X")
    print(f"==========================================")
    
    try:
        meta_input = input("❓ ¿Cuantos equipos procesarás en este lote?: ")
        meta = int(meta_input) if meta_input.isdigit() else 1
    except ValueError:
        meta = 1

    print(f"\n📡 Escaneando {Config.DEVICE_IP}...")
    print(f"📊 Meta: {meta} equipos | 🛡️ Reintentos: 3 por equipo")
    print(f"------------------------------------------\n")

    try:
        while len(sesion_actual) < meta:
            total = len(sesion_actual)
            restantes = meta - total
            
            # Línea de estado dinámica
            sys.stdout.write(f"\r[📶] Procesados: {total} | Faltan: {restantes} | Buscando equipo...")
            sys.stdout.flush()
            
            estado, mac_res = await process_device(Config.DEVICE_IP)
            
            if estado == "OK":
                print(f"\n✅ Equipo #{len(sesion_actual)} finalizado correctamente.")
                if len(sesion_actual) < meta:
                    print(f"🔔 CAMBIE EL EQUIPO...")
                    # Tiempo para que el usuario desconecte y el puerto se limpie
                    await asyncio.sleep(10) 
            
            elif estado == "ESPERANDO_DESCONEXION":
                await asyncio.sleep(2)
            else:
                # Reintento de ciclo de escaneo
                await asyncio.sleep(1)

        print(f"\n\n==========================================")
        print(f"🎉 ¡PROCESO COMPLETADO! {meta}/{meta} equipos listos.")
        print(f"📂 Archivo 'macs.txt' actualizado en la raíz.")
        print(f"==========================================")
        
        send_webhook(sesion_actual, meta)
        if _mac_backup:
            _mac_backup.export_session()

    except KeyboardInterrupt:
        print(f"\n\n🛑 PROCESO DETENIDO POR EL USUARIO.")
        if _mac_backup:
            _mac_backup.export_session()

if __name__ == "__main__":
    asyncio.run(main())
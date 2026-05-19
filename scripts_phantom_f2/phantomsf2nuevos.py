#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
import sys
import shutil
import json
import urllib.request
from datetime import datetime
from config import Config

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
    "MPC-175K2LHCBFV": "Juan Marin"
}

def get_alias():
    """Obtiene el nombre mapeado del equipo actual"""
    hostname = os.getenv('COMPUTERNAME', 'Desconocido')
    return EQUIPO_MAPEO.get(hostname, hostname)

def send_webhook(macs, meta):
    """Envía un resumen de las MACs flasheadas a Discord"""
    if not Config.WEBHOOK_URL or not macs:
        return

    try:
        nombre_visual = get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs])
        
        data = {
            "embeds": [{
                "title": "👻 Lote de Phantoms F2 Nuevos Flasheados",
                "color": 3066993, # Verde
                "fields": [
                    {"name": "🔢 Equipos Procesados", "value": f"**{len(macs)} / {meta}**", "inline": True},
                    {"name": "💻 Procesado por", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "📍 Direcciones MAC", "value": lista_macs, "inline": False},
                    {"name": "⏰ Fecha", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        
        req = urllib.request.Request(Config.WEBHOOK_URL, data=json.dumps(data).encode('utf-8'), 
                                   headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            pass
    except Exception:
        pass

# Registro de la sesión
sesion_actual = []


async def process_device(ip, retries=3):
    """Procesa el equipo con lógica de reintentos"""
    if not Config.FIRMWARE_PATH.exists():
        print(f"❌ ERROR: No se encuentra el firmware en {Config.FIRMWARE_PATH}")
        return "ERROR_LOCAL", None

    for intento in range(1, retries + 1):
        try:
            options = asyncssh.SSHClientConnectionOptions(
                known_hosts=None,
                login_timeout=8,
                signature_algs=['ssh-rsa', 'ssh-dss']
            )

            async with asyncssh.connect(ip, username='root', password=Config.SSH_PASSWORD, options=options) as conn:
                # 1. Extraer MAC y verificar espacio en un solo comando para ahorrar latencia
                result = await conn.run("uci show network.@device[1].macaddr; echo '---'; df -k /tmp", check=True)
                mac_match = re.search(r"macaddr='([0-9a-fA-F:]{17})'", result.stdout)

                if mac_match:
                    mac = mac_match.group(1).upper()

                    if mac in sesion_actual:
                        return "ESPERANDO_DESCONEXION", None

                    print(f"\n✨ [Intento {intento}] ¡Conectado! MAC: {mac}")
                    
                    # 1. Registro inmediato (Historial F2 y Sesión)
                    ruta_backup = Config.BACKUP_DIR / "Macs_phantom_f2_historial.txt"
                    with open(ruta_backup, "a", encoding="utf-8") as f:
                        f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {mac}\n")

                    sesion_actual.append(mac)
                    with open(Config.MAC_FILE, "w", encoding="utf-8") as f:
                        for m in sesion_actual:
                            f.write(f"{m}\n")

                    # 2. Verificar espacio en /tmp (ya descargado en el paso 1)
                    try:
                        # Extraemos la parte de df del output conjunto
                        df_output = result.stdout.split('---')[1].strip() if '---' in result.stdout else ""
                        lines = df_output.splitlines()
                        if len(lines) > 1:
                            parts = lines[1].split()
                            available_kb = int(parts[3])
                            file_size_kb = Config.FIRMWARE_PATH.stat().st_size / 1024
                            if available_kb < file_size_kb:
                                print(f"❌ ERROR: Espacio insuficiente en /tmp. Disponible: {available_kb}KB, Requerido: {int(file_size_kb)}KB")
                                return "ERROR_ESPACIO", None
                    except:
                        pass 

                    # 3. Subir firmware
                    print(f"📤 Subiendo firmware ({Config.FIRMWARE_PATH.name})...")
                    target_path = "/tmp/fw.bin"
                    await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, target_path))
                    
                    # 4. Verificar subida
                    check_file = await conn.run(f"ls -l {target_path}")
                    if target_path not in check_file.stdout:
                        print(f"❌ ERROR: El firmware no se encuentra en el equipo después de subirlo.")
                        continue

                    # 5. Flashear
                    print(f"🚀 Ejecutando flasheo...")
                    try:
                        # Ejecutamos con un timeout corto para capturar errores de validación inmediatos
                        # Si el equipo se reinicia, la conexión se perderá y saltará al except
                        flash_res = await conn.run(f"sysupgrade -F -n {target_path}", timeout=10)
                        
                        if flash_res.exit_status != 0:
                            # Si el error contiene "will update anyway", es un éxito (el force funcionó)
                            if "will update anyway" in flash_res.stdout or "will update anyway" in flash_res.stderr:
                                print(f"⚠️  Advertencia de compatibilidad saltada. Flasheo iniciado...")
                            else:
                                print(f"❌ ERROR: El equipo rechazó el firmware.")
                                print(f"Detalle: {flash_res.stdout} {flash_res.stderr}")
                                return "ERROR_FLASH", None
                    except (asyncssh.Error, OSError, asyncio.TimeoutError):
                        # La pérdida de conexión es normal durante un sysupgrade exitoso
                        pass

                    return "OK", mac
        except (asyncssh.Error, OSError) as e:
            if intento < retries:
                await asyncio.sleep(1)
            else:
                return "SIN_CONEXION", None
    return "SIN_CONEXION", None


async def main():
    # REGLA DE ORO: Respaldar sesión previa y limpiar raíz
    if Config.MAC_FILE.exists() and Config.MAC_FILE.stat().st_size > 0:
        try:
            fecha_str = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_session = Config.BACKUP_DIR / f"macs_previas_{fecha_str}.txt"
            shutil.copy(Config.MAC_FILE, backup_session)
            print(f"📦 Respaldo de sesión previa creado: {backup_session.name}")
        except Exception as e:
            print(f"⚠️  No se pudo crear el respaldo de sesión: {e}")

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
                    # Tiempo reducido: espera breve para limpiar puerto, la validación inteligente hará el resto
                    await asyncio.sleep(2)

            elif estado == "ESPERANDO_DESCONEXION":
                await asyncio.sleep(1)
            else:
                # Reintento de ciclo de escaneo mucho más rápido para polling agresivo
                await asyncio.sleep(0.5)

        print(f"\n\n==========================================")
        print(f"🎉 ¡PROCESO COMPLETADO! {meta}/{meta} equipos listos.")
        print(f"📂 Archivo 'macs.txt' actualizado en la raíz.")
        print(f"==========================================")
        
        # Enviar notificación final a Discord
        send_webhook(sesion_actual, meta)

    except KeyboardInterrupt:
        print(f"\n\n🛑 PROCESO DETENIDO POR EL USUARIO.")


if __name__ == "__main__":
    asyncio.run(main())
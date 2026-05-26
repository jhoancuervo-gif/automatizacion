#!/usr/bin/env python3
import asyncio
import asyncssh
import time
import re
import os
import sys
from datetime import datetime
from config import Config

import sys as _sys
_sys.path.insert(0, str(Config.BASE_DIR / "core"))
from mac_backup import MacBackup
from discord_notifier import DiscordNotifier

discord = DiscordNotifier()

# Registro de la sesión
sesion_actual = []

async def process_device(ip, retries=3):
    """Lógica de conexión con 3 reintentos y flasheo forzado"""
    for intento in range(1, retries + 1):
        try:
            options = asyncssh.SSHClientConnectionOptions(
                known_hosts=None, 
                login_timeout=8,
                signature_algs=['ssh-rsa', 'ssh-dss']
            )
            
            async with asyncssh.connect(ip, username='root', password=Config.SSH_PASSWORD, options=options) as conn:
                # 1. Obtener MAC (Lógica de orb2.py)
                result = await conn.run("uci show network.@device[1].macaddr")
                output = result.stdout
                
                # Extraer MAC con el regex exacto
                mac_match = re.search(r"'([0-9a-fA-F:]{17})'", output)
                if not mac_match:
                    return "ERROR_MAC"

                mac = mac_match.group(1).upper()
                
                # Si ya se procesó, no reintentamos ni flasheamos
                if mac in sesion_actual:
                    return "YA_PROCESADO"

                print(f"\n✨ [Intento {intento}] Equipo detectado: {mac}")
                
                # 2. Subir firmware forzado
                print(f"📤 Subiendo firmware: {Config.FIRMWARE_PATH.name}...")
                await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/somosORB2-PROD.bin'))
                
                # 3. Registrar en archivos
                registrar_mac(mac)
                
                # 4. Flashear con fuerza (-F)
                print(f"🚀 Iniciando Flasheo Forzado (-F)... No desconecte.")
                try:
                    # El comando -F ignora chequeos de board id y fuerza la carga
                    await conn.run("sysupgrade -F -n /tmp/somosORB2-PROD.bin")
                except:
                    pass # El reinicio cortará la conexión
                
                return "OK"

        except (asyncssh.Error, OSError):
            if intento < retries:
                # Si falla la conexión, esperamos 3 segundos y reintentamos
                await asyncio.sleep(3)
            else:
                return "FALLO_CONEXION"
    return "FALLO_CONEXION"

_mac_backup = None


def registrar_mac(mac):
    """Guarda en macs.txt (raíz) y en backups_macs centralizado"""
    sesion_actual.append(mac)
    if _mac_backup:
        _mac_backup.save(mac)
    with open(Config.MAC_FILE, "a", encoding="utf-8") as f:
        f.write(f"{mac}\n")

async def main():
    global _mac_backup
    _mac_backup = MacBackup(Config.CURRENT_DIR, "ORBE_NUEVAS", mac_file=Config.MAC_FILE)

    discord.send_ingreso("Orbes Nuevas")

    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()

    print(f"\n==========================================")
    print(f"   ORBES NUEVAS - MODO FLASH FORZADO (-F)")
    print(f"==========================================")
    
    # Selección de meta
    meta_input = input("❓ ¿Cuántas Orbes procesarás hoy?: ")
    meta = int(meta_input) if meta_input.isdigit() else 1
    
    print(f"\n📡 Monitoreando {Config.DEVICE_IP}...")
    print(f"🛡️  Reintentos: 3 por equipo | Forzado: Activado")
    print(f"------------------------------------------\n")

    try:
        while len(sesion_actual) < meta:
            total = len(sesion_actual)
            sys.stdout.write(f"\r[📶] Listas: {total}/{meta} | Buscando Orbe en {Config.DEVICE_IP}...")
            sys.stdout.flush()
            
            resultado = await process_device(Config.DEVICE_IP)
            
            if resultado == "OK":
                print(f"\n✅ Equipo #{len(sesion_actual)} finalizado.")
                if len(sesion_actual) < meta:
                    print(f"🔔 CAMBIE EL EQUIPO (Esperando desconexión)...")
                    await asyncio.sleep(12) # Tiempo extra para desconectar
            
            elif resultado == "YA_PROCESADO":
                # Esperar a que el usuario cambie el equipo ya hecho
                await asyncio.sleep(2)
            
            else:
                # Si fallaron los 3 intentos o no hay equipo, reintentar ciclo
                await asyncio.sleep(1)

        print(f"\n\n==========================================")
        print(f"🎉 ¡LOTE COMPLETADO! {meta}/{meta} Orbes listas.")
        print(f"📂 MACs disponibles en la raíz para verificar.")
        print(f"==========================================")
        discord.send_webhook(sesion_actual, meta, "Orbes Nuevas")
        if _mac_backup:
            _mac_backup.export_session()

    except KeyboardInterrupt:
        print(f"\n\n🛑 PROCESO DETENIDO POR EL USUARIO")
        discord.send_webhook(sesion_actual, meta, "Orbes Nuevas", is_interrupted=True)
        if _mac_backup:
            _mac_backup.export_session()
            
    except Exception as e:
        print(f"\n\n🚨 ERROR CRÍTICO: {e}")
        discord.send_error("Orbes Nuevas", str(e))

if __name__ == "__main__":
    asyncio.run(main())
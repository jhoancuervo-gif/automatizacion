#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
from datetime import datetime
from config import Config

sesion_actual = []


async def process_device(ip):
    try:
        async with asyncssh.connect(ip, username='root', password=Config.SSH_PASSWORD, known_hosts=None) as conn:
            # Comando original para Phantom
            result = await conn.run("uci show network.@device[1].macaddr", check=True)
            mac_match = re.search(r"macaddr='([0-9a-fA-F:]{17})'", result.stdout)

            if mac_match:
                mac = mac_match.group(1).upper()

                # Subir Firmware
                await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/Firmware_PHANTOM.bin'))

                # --- LÓGICA DE GUARDADO ---

                # 1. Guardar en BACKUP (Historial completo)
                ruta_backup = Config.BACKUP_DIR / "Macs_phantom_reintegrof2.txt"
                with open(ruta_backup, "a", encoding="utf-8") as f:
                    f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {mac}\n")

                # 2. Actualizar lista de sesión
                sesion_actual.append(mac)

                # 3. Escribir en la RAÍZ (macs.txt) - Sobrescribe con lo actual
                with open(Config.MAC_FILE, "w", encoding="utf-8") as f:
                    for m in sesion_actual:
                        f.write(f"{m}\n")

                # Flashear
                print(f" -> 🚀 Flasheando...", end="", flush=True)
                try:
                    await conn.run("sysupgrade -n /tmp/Firmware_PHANTOM-F2.bin")
                except:
                    pass

                return True, mac
            return False, "No MAC"
    except Exception as e:
        return False, str(e)


async def main():
    print(f"\n🚀 PHANTOM REINTEGRO - MOTOR SINCRONIZADO")

    # LIMPIEZA DE ARRANQUE: Asegura que el archivo de la raíz empiece vacío
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()

    ips = [f"{Config.IP_BASE}{i}" for i in range(Config.IP_START, Config.IP_END + 1)]
    input(f"\n[!] Presione ENTER para iniciar en {len(ips)} IPs...")

    for ip in ips:
        print(f"📡 {ip}...", end=" ", flush=True)
        exito, resultado = await process_device(ip)
        if exito:
            print(f"✅ OK ({resultado})")
        else:
            print(f"❌ Error o Salto")

    if sesion_actual:
        print(f"\n✨ Proceso terminado. {len(sesion_actual)} MACs listas en la raíz.")


if __name__ == "__main__":
    asyncio.run(main())
#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
from datetime import datetime
from config import Config

async def process_orbe(ip):
    try:
        options = asyncssh.SSHClientConnectionOptions(
            known_hosts=None,
            signature_algs=['ssh-rsa', 'ssh-dss']
        )

        async with asyncssh.connect(
            ip, 
            username='root', 
            password=Config.SSH_PASSWORD, 
            options=options,
            login_timeout=15
        ) as conn:
            
            print(f" -> 🔑 Acceso Concedido", end="", flush=True)
            
            # Extraer MAC
            result = await conn.run("uci get network.wan.macaddr")
            mac = result.stdout.strip().upper()
            
            if not mac or "not found" in mac.lower():
                result = await conn.run("uci show network.@device[1].macaddr")
                mac_match = re.search(r"macaddr='([0-9a-fA-F:]{17})'", result.stdout)
                mac = mac_match.group(1).upper() if mac_match else None

            if not mac: return False, "MAC_NO_DETECTADA"
            print(f" -> 🔍 MAC: {mac}", end="", flush=True)

            # Subir firmware
            print(f" -> 📤 Subiendo...", end="", flush=True)
            await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/somosORB2-PROD.bin'))

            # --- LÓGICA DE GUARDADO Y BACKUP (Estilo POE) ---
            # 1. Guardar en macs.txt de la raíz
            with open(Config.MAC_FILE, 'a', encoding='utf-8') as f:
                f.write(f"{mac}\n")
            
            # 2. Guardar en el Historial de Backup
            fecha = datetime.now().strftime("%Y-%m-%d")
            hora = datetime.now().strftime("%H:%M:%S")
            historial_path = Config.BACKUP_DIR / f"orbe_reintegro_historial_{fecha}.txt"
            with open(historial_path, 'a', encoding='utf-8') as f:
                f.write(f"{hora} | Orbe Reintegro | {mac}\n")
            
            # Flashear
            print(f" -> 🚀 Flasheando...", end="", flush=True)
            try:
                await conn.run("sysupgrade -n -F /tmp/somosORB2-PROD.bin")
            except: pass
                
            return True, mac

    except Exception as e:
        return False, f"SSH_ERROR ({str(e)[:15]})"

async def main():
    print(f"\n🚀 ORBE REINTEGRO - MODO LIMPIEZA Y BACKUP")
    print(f"📡 Rango: {Config.IP_BASE}{Config.IP_START} al {Config.IP_BASE}{Config.IP_END}")
    
    # IMPORTANTE: Limpiamos macs.txt de la raíz al iniciar
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()
    else:
        open(Config.MAC_FILE, 'w').close()

    ips = [f"{Config.IP_BASE}{i}" for i in range(Config.IP_START, Config.IP_END + 1)]
    input(f"\n[!] Presione ENTER para iniciar proceso en {len(ips)} equipos...")
    
    for ip in ips:
        print(f"📡 {ip}", end="", flush=True)
        exito, resultado = await process_orbe(ip)
        if exito:
            print(f" ✅ TERMINADO")
        else:
            print(f" ❌ FALLÓ: {resultado}")

# --- BLOQUE DE RETORNO SEGURO ---
if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado por el usuario.")
    except Exception as e:
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        if Config.MAC_FILE.exists() and os.path.getsize(Config.MAC_FILE) > 0:
            print("\n[+] Abriendo reporte de MACs en el Bloc de notas...")
            try: os.startfile(Config.MAC_FILE)
            except: pass
        
        input("\n[🔔] Presione ENTER para volver al menú principal...")
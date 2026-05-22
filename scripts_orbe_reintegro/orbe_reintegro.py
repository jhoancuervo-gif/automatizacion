#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
import socket
from datetime import datetime
from config import Config

import sys as _sys
_sys.path.insert(0, str(Config.BASE_DIR / "core"))
from mac_backup import MacBackup

_mac_backup = None

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

async def scan_active_ips(target_range):
    """
    Usa Nmap para encontrar equipos vivos rápidamente.
    """
    # -sn: Ping scan
    cmd = f"nmap -sn --min-parallelism 100 --max-rtt-timeout 150ms {target_range} -oG -"
    try:
        process = await asyncio.create_subprocess_shell(
            cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, _ = await process.communicate()
        if process.returncode == 0:
            return re.findall(r"Host: (\d+\.\d+\.\d+\.\d+)", stdout.decode())
    except Exception:
        pass
    return []

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

            with open(Config.MAC_FILE, 'a', encoding='utf-8') as f:
                f.write(f"{mac}\n")
            if _mac_backup:
                _mac_backup.save(mac)

            # Flashear (Mantenemos tu lógica original exacta)
            print(f" -> 🚀 Flasheando...", end="", flush=True)
            try:
                # Quitamos el & y dejamos que el comando se ejecute como en tu original
                await conn.run("sysupgrade -n -F /tmp/somosORB2-PROD.bin")
            except: 
                pass
                
            return True, mac

    except Exception as e:
        return False, f"SSH_ERROR ({str(e)[:15]})"

async def main():
    global _mac_backup
    _mac_backup = MacBackup(Config.CURRENT_DIR, "ORBE_REINTEGRO", mac_file=Config.MAC_FILE)

    print(f"\n🚀 ORBE REINTEGRO - MODO NMAP EFICIENTE")
    
    mi_ip = get_local_ip()
    gateway_ip = f"{Config.IP_BASE}1"
    target_range = f"{Config.IP_BASE}0/24" 
    
    # Limpiar macs.txt de la raíz al iniciar
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()
    else:
        Config.MAC_FILE.touch()

    try:
        input_user = input("\n¿Cuántos equipos quieres procesar en este lote? (Default 1): ")
        objetivo = int(input_user) if input_user.strip() else 1
    except ValueError:
        objetivo = 1

    print(f"🔍 Escaneando red para encontrar {objetivo} equipos activos...")
    
    procesados_exitosos = 0
    ya_intentados = {mi_ip, gateway_ip}
    
    while procesados_exitosos < objetivo:
        # Escaneo rápido con Nmap
        activas = await scan_active_ips(target_range)
        
        # Filtrar IPs que no hemos tocado
        candidatas = [ip for ip in activas if ip not in ya_intentados]
        
        if not candidatas:
            print(".", end="", flush=True)
            await asyncio.sleep(2)
            continue

        for ip in candidatas:
            if procesados_exitosos >= objetivo:
                break
                
            print(f"📡 {ip}", end="", flush=True)
            exito, resultado = await process_orbe(ip)
            
            ya_intentados.add(ip)
            
            if exito:
                procesados_exitosos += 1
                print(f" ✅ TERMINADO")
            else:
                print(f" ❌ FALLÓ: {resultado}")

        if procesados_exitosos < objetivo:
            print(f"\n⏳ Llevamos {procesados_exitosos}/{objetivo}. Re-escaneando red...")

    print(f"\n\n✨ Proceso finalizado. {procesados_exitosos} equipos completados.")
    if _mac_backup:
        _mac_backup.export_session()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado.")
        if _mac_backup:
            _mac_backup.export_session()
    finally:
        if Config.MAC_FILE.exists() and os.path.getsize(Config.MAC_FILE) > 0:
            try: os.startfile(Config.MAC_FILE)
            except: pass
        input("\n[🔔] Presione ENTER para salir...")

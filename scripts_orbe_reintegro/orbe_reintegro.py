#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
import socket
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
    "MPC-175K2LHCBFV": "Juan Marin",
    "DESKTOP-A-VALLE": "Jhon Vallejo"
}

def get_alias():
    """Obtiene el nombre mapeado del equipo actual"""
    hostname = os.getenv('COMPUTERNAME', 'Desconocido')
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
                "color": 5763719,
                "fields": [
                    {"name": "📋 Script", "value": "**Orbe Reintegro**", "inline": True},
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

def send_webhook(macs, tipo="Orbe Reintegro"):
    """Envía un resumen de las MACs flasheadas a Discord"""
    if not Config.WEBHOOK_PRODUCCION or not macs:
        return

    try:
        nombre_visual = get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs])
        
        data = {
            "embeds": [{
                "title": f"🔮 Lote de {tipo} Flasheados",
                "color": 3447003, # Azul
                "fields": [
                    {"name": "🔢 Equipos Procesados", "value": f"**{len(macs)}**", "inline": True},
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

            # --- LÓGICA DE GUARDADO Y BACKUP ---
            with open(Config.MAC_FILE, 'a', encoding='utf-8') as f:
                f.write(f"{mac}\n")
            
            fecha = datetime.now().strftime("%Y-%m-%d")
            hora = datetime.now().strftime("%H:%M:%S")
            historial_path = Config.BACKUP_DIR / f"orbe_reintegro_historial_{fecha}.txt"
            
            if not Config.BACKUP_DIR.exists():
                Config.BACKUP_DIR.mkdir(parents=True)

            with open(historial_path, 'a', encoding='utf-8') as f:
                f.write(f"{hora} | Orbe Reintegro | {mac}\n")
            
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
    print(f"\n🚀 ORBE REINTEGRO - MODO NMAP EFICIENTE")
    
    # Notificar ingreso al canal de Discord
    send_ingreso()

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
    macs_procesadas = []
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
                macs_procesadas.append(resultado)
                print(f" ✅ TERMINADO")
            else:
                print(f" ❌ FALLÓ: {resultado}")

        if procesados_exitosos < objetivo:
            print(f"\n⏳ Llevamos {procesados_exitosos}/{objetivo}. Re-escaneando red...")

    print(f"\n\n✨ Proceso finalizado. {procesados_exitosos} equipos completados.")
    if macs_procesadas:
        send_webhook(macs_procesadas)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado.")
    finally:
        if Config.MAC_FILE.exists() and os.path.getsize(Config.MAC_FILE) > 0:
            try: os.startfile(Config.MAC_FILE)
            except: pass
        input("\n[🔔] Presione ENTER para salir...")

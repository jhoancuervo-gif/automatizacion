#!/usr/bin/env python3
import asyncio
import asyncssh
import os
import re
import sys
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
    "USUARIO-IO29QUF": "FlechasJuan"
}

def get_alias():
    """Obtiene el nombre mapeado del equipo actual"""
    hostname = os.getenv('COMPUTERNAME', 'Desconocido')
    return EQUIPO_MAPEO.get(hostname, hostname)

def send_webhook(macs, tipo="Reintegro"):
    """Envía un resumen de las MACs flasheadas a Discord"""
    if not Config.WEBHOOK_URL or not macs:
        return

    try:
        nombre_visual = get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs])
        
        data = {
            "embeds": [{
                "title": f"👻 Lote de Phantoms {tipo} Flasheados",
                "color": 3447003, # Azul para Reintegro
                "fields": [
                    {"name": "🔢 Equipos Procesados", "value": f"**{len(macs)}**", "inline": True},
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

sesion_actual = []
print_lock = asyncio.Lock()
file_lock = asyncio.Lock()

async def scan_network():
    """Escanea la red buscando dispositivos con el puerto 22 abierto (SSH)."""
    # Escaneo de toda la red /24
    target = f"{Config.IP_BASE}0/24" if Config.IP_BASE.endswith('.') else f"{Config.IP_BASE}.0/24"
    
    async with print_lock:
        print(f"🔍 Escaneando red {target} en busca de equipos (Puerto 22)...")
    
    try:
        # Detectar IPs locales del PC para omitirlas
        hostname = socket.gethostname()
        local_ips = socket.gethostbyname_ex(hostname)[2]
        
        process = await asyncio.create_subprocess_exec(
            'nmap', '-p', '22', '--open', '-n', '-T5', target, '-oG', '-',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, _ = await process.communicate()
        
        output = stdout.decode()
        # Solo capturar IPs que tienen el puerto open
        ips_encontradas = list(set(re.findall(r"Host: (\d+\.\d+\.\d+\.\d+).*Ports:.*22/open", output)))
        
        # Filtrar la IP propia del PC
        ips = [ip for ip in ips_encontradas if ip not in local_ips]
        
        # Informar qué IPs se omitieron si se encontraron
        omitted = [ip for ip in ips_encontradas if ip in local_ips]
        if omitted:
            async with print_lock:
                print(f"ℹ️ Omitiendo IP local del PC: {', '.join(omitted)}")
                
        return ips
    except Exception as e:
        async with print_lock:
            print(f"❌ Error durante el escaneo: {e}")
        return []

async def process_device(ip, semaphore):
    async with semaphore:
        async with print_lock:
            print(f"📡 {ip}...", end=" ", flush=True)
            
        try:
            # Timeout de conexión para no quedar bloqueados
            async with asyncssh.connect(ip, username='root', password=Config.SSH_PASSWORD, known_hosts=None, connect_timeout=10) as conn:
                # Comando original para Phantom
                result = await conn.run("uci show network.@device[1].macaddr", check=True)
                mac_match = re.search(r"macaddr='([0-9a-fA-F:]{17})'", result.stdout)
                
                if mac_match:
                    mac = mac_match.group(1).upper()
                    
                    # Subir Firmware
                    await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/Firmware_PHANTOM.bin'))
                    
                    # --- LÓGICA DE GUARDADO CON LOCK ---
                    async with file_lock:
                        # 1. Guardar en BACKUP (Historial completo)
                        ruta_backup = Config.BACKUP_DIR / "Macs_phantom_reintegro.txt"
                        with open(ruta_backup, "a", encoding="utf-8") as f:
                            f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | {mac}\n")
                        
                        # 2. Actualizar lista de sesión
                        sesion_actual.append(mac)

                        # 3. Escribir en la RAÍZ (macs.txt) - Sobrescribe con lo actual
                        with open(Config.MAC_FILE, "w", encoding="utf-8") as f:
                            for m in sesion_actual:
                                f.write(f"{m}\n")
                    
                    # Flashear
                    async with print_lock:
                        print(f"🚀 Flasheando...", end="", flush=True)
                    
                    try:
                        # Usamos run sin esperar el cierre total ya que el reboot corta la conexión
                        await conn.run("sysupgrade -n /tmp/Firmware_PHANTOM.bin", timeout=5)
                    except: pass
                        
                    async with print_lock:
                        print(f" ✅ OK ({mac})")
                    
                    return True
                
                async with print_lock:
                    print(f" ❌ No MAC")
                return False
                
        except Exception as e:
            async with print_lock:
                print(f" ❌ Error: {str(e)[:30]}")
            return False

async def main():
    print(f"\n🚀 PHANTOM REINTEGRO - MOTOR ULTRA-RÁPIDO (PARALELO)")
    
    # LIMPIEZA DE ARRANQUE
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()

    # ESCANEO DINÁMICO
    ips = await scan_network()
    
    if not ips:
        print("❌ No se encontraron equipos activos en la red.")
        input("\nPresione ENTER para salir...")
        return

    print(f"✅ Se encontraron {len(ips)} equipos.")
    input(f"\n[!] Presione ENTER para iniciar el procesamiento en paralelo...")
    
    # PROCESAMIENTO EN PARALELO
    # Semaphore limita las conexiones simultáneas para no saturar. 
    # Se ha aumentado a 30 por solicitud del usuario.
    semaphore = asyncio.Semaphore(30)
    tasks = [process_device(ip, semaphore) for ip in ips]
    
    await asyncio.gather(*tasks)

    if sesion_actual:
        print(f"\n✨ Proceso terminado. {len(sesion_actual)} MACs listas en la raíz.")
        # Enviar notificación final
        send_webhook(sesion_actual)
    else:
        print(f"\n⚠️ No se procesó ninguna MAC correctamente.")
        
    input("\nPresione ENTER para finalizar...")

if __name__ == "__main__":
    # Asegurar que la consola maneje UTF-8 para los emojis
    if sys.platform == "win32":
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\nAbortado por el usuario.")
        sys.exit(0)
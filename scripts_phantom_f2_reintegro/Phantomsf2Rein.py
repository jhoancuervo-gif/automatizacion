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

def send_webhook(macs, tipo="F2 Reintegro"):
    """Envía un resumen de las MACs flasheadas a Discord"""
    if not Config.WEBHOOK_URL or not macs:
        return

    try:
        nombre_visual = get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs])
        
        data = {
            "embeds": [{
                "title": f"👻 Lote de Phantoms {tipo} Flasheados",
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
        
        req = urllib.request.Request(Config.WEBHOOK_URL, data=json.dumps(data).encode('utf-8'), 
                                   headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            pass
    except Exception:
        pass

sesion_actual = []
print_lock = asyncio.Lock()
file_lock = asyncio.Lock()


async def check_port(ip, port, timeout=0.8):
    try:
        reader, writer = await asyncio.wait_for(asyncio.open_connection(ip, port), timeout=timeout)
        writer.close()
        await writer.wait_closed()
        return ip
    except:
        return None

async def scan_network(cantidad):
    """Escanea la red buscando dispositivos con el puerto 22 abierto (SSH), de forma similar a PS1."""
    ips_encontradas = set()
    intentos = 0
    
    # Detectar IP local para omitirla
    hostname = socket.gethostname()
    try:
        local_ips = socket.gethostbyname_ex(hostname)[2]
    except Exception:
        local_ips = []
        
    base_ip = Config.IP_BASE if Config.IP_BASE.endswith('.') else f"{Config.IP_BASE}."
    
    async with print_lock:
        print(f"\n🔍 MODO CENTINELA: Esperando a que {cantidad} equipos estén listos para Flashear...")
        
    while len(ips_encontradas) < cantidad:
        tasks = []
        # Rango de 200 a 250 igual que en PS1
        for i in range(200, 251):
            ip = f"{base_ip}{i}"
            if ip in local_ips or ip in ips_encontradas:
                continue
            tasks.append(check_port(ip, 22))
            
        resultados = await asyncio.gather(*tasks)
        nuevas_ips = [res for res in resultados if res]
        
        for ip in nuevas_ips:
            ips_encontradas.add(ip)
            async with print_lock:
                print(f"  [+] SSH LISTO: {ip} ({len(ips_encontradas)}/{cantidad})")
                
        if len(ips_encontradas) < cantidad:
            intentos += 1
            faltan = cantidad - len(ips_encontradas)
            async with print_lock:
                print(f"  ⏳ Faltan {faltan} equipos. Buscando de nuevo... (Intento {intentos})")
            await asyncio.sleep(2)
            
            if intentos >= 15:
                # Prompt bloqueante en la consola
                forzar = input(f"\n⚠️ Han pasado 30s. ¿Forzar ejecución con los {len(ips_encontradas)} encontrados? (S/N): ")
                if forzar.strip().lower() == 's':
                    break
                intentos = 0
                
    return list(ips_encontradas)


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
                    await asyncssh.scp(str(Config.FIRMWARE_PATH), (conn, '/tmp/somos-openwrt-24.10.5-somosfw-mediatek-filogic-somos_phantomf2.bin'))

                    # --- LÓGICA DE GUARDADO CON LOCK ---
                    async with file_lock:
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
                    async with print_lock:
                        print(f"🚀 Flasheando...", end="", flush=True)

                    try:
                        # Usamos run sin esperar el cierre total ya que el reboot corta la conexión
                        await conn.run("sysupgrade -n /tmp/somos-openwrt-24.10.5-somosfw-mediatek-filogic-somos_phantomf2.bin", timeout=5)
                    except:
                        pass

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

    # LIMPIEZA DE ARRANQUE: Asegura que el archivo de la raíz empiece vacío
    if Config.MAC_FILE.exists():
        open(Config.MAC_FILE, 'w').close()

    try:
        cantidad_input = input("¿Equipos para este lote?: ")
        cantidad = int(cantidad_input)
    except ValueError:
        cantidad = 1

    # ESCANEO DINÁMICO
    ips = await scan_network(cantidad)

    if not ips:
        print("❌ No se encontraron equipos activos en la red.")
        input("\nPresione ENTER para salir...")
        return

    print(f"\n🚀 Iniciando procesamiento de {len(ips)} equipos simultáneamente...")

    # PROCESAMIENTO EN PARALELO
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

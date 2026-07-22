import requests
import time
import subprocess
import re
import os
import sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "core"))
from mac_backup import MacBackup
from discord_notifier import DiscordNotifier

# =====================================================================
# CONFIGURACIÓN DEL SISTEMA (V33 STABLE + LOTE SIMULTÁNEO)
# =====================================================================
BASE_IP = "192.168.18.1"
PASSWORDS = ["admin", "somos123."]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FW_FILE = os.path.join(BASE_DIR, "upg_appimage.bin")
CONFIG_FILE = os.path.join(BASE_DIR, "port8_snmp.bin") # Archivo configuracion
LOG_FILE = os.path.join(BASE_DIR, "log_masivo.txt")
MACS_FILE = os.path.join(BASE_DIR, "mac.txt") 
MAX_WORKERS = 10 

if sys.stdout.encoding != 'utf-8':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

class Colors:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    END = '\033[0m'
    BOLD = '\033[1m'

def log(msg, color=Colors.END):
    clean_msg = msg.encode('ascii', 'ignore').decode('ascii')
    print(f"{color}{msg}{Colors.END}")
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {clean_msg}\n")
    except: pass

def obtener_mac(ip):
    try:
        res = subprocess.run(["arp", "-a", ip], capture_output=True, text=True)
        match = re.search(r"([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})", res.stdout)
        return match.group(0).upper().replace("-", ":") if match else None
    except: return None

def verify_http(ip, timeout=0.6):
    try:
        r = requests.get(f"http://{ip}/index.htm", timeout=timeout)
        return r.status_code in [200, 401]
    except: return False

def verify_http_auth(ip, user, pwd):
    try:
        r = requests.get(f"http://{ip}/index.htm", auth=(user, pwd), timeout=1.5)
        return r.status_code == 200
    except: return False

def esperar_pulso_reinicio(ip, prefix, max_down=15):
    start_down = time.time()
    while (time.time() - start_down) < max_down:
        if not verify_http(ip, timeout=0.4): break
        time.sleep(0.5)
    
    start_up = time.time()
    while (time.time() - start_up) < 45:
        if verify_http(ip): return True
        time.sleep(1.5)
    return False

def esperar_equipo_original(ip, max_wait=30):
    start = time.time()
    while (time.time() - start) < max_wait:
        if verify_http(ip): return True
        time.sleep(1)
    return False

def preparar_flash(session, ip):
    """Paso previo indispensable en Hellotek antes de subir el binario"""
    try:
        url = f"http://{ip}/cgi/toBootLoadUpgrade.cgi"
        session.post(url, timeout=5)
        time.sleep(2)
        return True
    except:
        return False

def subir_archivo_turbo(session, url, file_path, prefix):
    try:
        if not os.path.exists(file_path):
            log(f"{prefix}Error: No se encuentra el archivo {file_path}", Colors.RED)
            return False

        filename = os.path.basename(file_path)
        with open(file_path, 'rb') as f:
            files = {'FN': (filename, f, 'application/octet-stream')}
            r = session.post(url, files=files, timeout=70)
            return r.status_code == 200
    except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
        return True 
    except Exception as e:
        log(f"{prefix}Excepción en subida: {e}", Colors.RED)
        return False

def subir_archivo_resiliente(session, url, file_path, prefix):
    for i in range(3):
        if subir_archivo_turbo(session, url, file_path, prefix):
            return True
        log(f"{prefix}Reintentando subida (Intento {i+2})...", Colors.YELLOW)
        time.sleep(3)
    return False

def flash_process_stable(dev):
    ip = dev['ip']
    prefix = f"[{ip}] "
    time.sleep(int(ip.split('.')[-1]) % 5 * 0.5)
    
    try:
        s = requests.Session()
        s.auth = dev['auth']
        s.headers.update({"Connection": "close"})
        
        # 1. PREPARAR FLASH
        log(f"{prefix}Preparando Flash...", Colors.CYAN)
        preparar_flash(s, ip)

        # 2. FIRMWARE
        log(f"{prefix}Subiendo FW...", Colors.YELLOW)
        if subir_archivo_resiliente(s, f"http://{ip}/cgi/upg_appimage.bin", FW_FILE, prefix):
            log(f"{prefix}Procesando Firmware (esperando 20s)...", Colors.CYAN)
            time.sleep(20)
            esperar_pulso_reinicio(ip, prefix, max_down=15)
        else: 
            log(f"{prefix}Fallo en subida de FW", Colors.RED)
            return False

        # 3. CONFIGURACIÓN
        log(f"{prefix}Subiendo Configuración...", Colors.YELLOW)
        if subir_archivo_resiliente(s, f"http://{ip}/cgi/SG1008.bin", CONFIG_FILE, prefix):
            time.sleep(4)
            esperar_pulso_reinicio(ip, prefix, max_down=10)
        else: 
            log(f"{prefix}Fallo en subida de Config", Colors.RED)
            return False

        # 4. SEGURIDAD Y REINICIO
        log(f"{prefix}Aplicando seguridad final...", Colors.CYAN)
        headers_sec = {"Referer": f"http://{ip}/usermng.htm"}
        data = {"U": "admin", "NU": "admin", "P1": "somos123.", "P2": "somos123."}

        for _ in range(3):
            if verify_http_auth(ip, "admin", "somos123."):
                log(f"{prefix}INTEGRIDAD OK.", Colors.GREEN)
                dev['auth'] = ("admin", "somos123.")
                return True
            try:
                s.post(f"http://{ip}/cgi/usermng.cgi", data=data, headers=headers_sec, timeout=5)
                time.sleep(3)
            except: pass
            
        return False
    except Exception as e:
        log(f"{prefix}Error critico en flash_process: {e}", Colors.RED)
        return False

def main():
    discord = DiscordNotifier()
    discord.send_ingreso("Switch PoE 1Gb Masivo")
    
    backup = MacBackup(BASE_DIR, "POE_1GB_MASIVO")
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{Colors.CYAN}==========================================================")
    print(f"   HELLOTEK - V33 STABLE (LOTE SIMULTÁNEO SEGURO)         ")
    print(f"=========================================================={Colors.END}")

    try:
        target = int(input(f"\nEquipos en lote: "))
    except KeyboardInterrupt:
        discord.send_webhook([], 0, "Switch PoE 1Gb Masivo", is_interrupted=True)
        return
    except: return

    discovered = []
    ip_index = 3
    
    log(f"\n--- FASE 1: DISPERSIÓN CONTINUA ---", Colors.BOLD)
    log("Iniciando escaneo del switch...", Colors.YELLOW)
    
    while len(discovered) < target:
        auth = None
        try:
            r = requests.get(f"http://{BASE_IP}/index.htm", auth=("admin", PASSWORDS[0]), timeout=0.4)
            if r.status_code == 200:
                auth = ("admin", PASSWORDS[0])
            elif r.status_code == 401:
                r2 = requests.get(f"http://{BASE_IP}/index.htm", auth=("admin", PASSWORDS[1]), timeout=0.4)
                if r2.status_code == 200:
                    auth = ("admin", PASSWORDS[1])
        except:
            pass 

        if auth:
            mac = obtener_mac(BASE_IP)
            
            if mac and not any(d['mac'] == mac for d in discovered):
                temp_ip = f"192.168.18.{ip_index}"
                payload = {"IP": temp_ip, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
                
                try: 
                    requests.post(f"http://{BASE_IP}/cgi/sysipset.cgi", auth=auth, data=payload, timeout=0.5)
                except: pass
                
                discovered.append({"mac": mac, "ip": temp_ip, "auth": auth})
                ip_index += 1
                log(f" [✔] INYECTADO: {mac} -> {temp_ip} | Procesando siguiente...", Colors.GREEN)
                
                if os.name == 'nt':
                    subprocess.run(["arp", "-d", BASE_IP], capture_output=True)
                
                time.sleep(1.5) 
                    
        time.sleep(0.2) 

    log(f"\n--- FASE 1.5: VERIFICACIÓN CONCURRENTE ---", Colors.BOLD)
    log("Asegurando IPs operativas...", Colors.CYAN)
    
    def verificar_y_esperar(dev):
        if esperar_equipo_original(dev['ip'], max_wait=20):
            return dev
        return None

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        equipos_listos = list(executor.map(verificar_y_esperar, discovered))
    
    discovered = [dev for dev in equipos_listos if dev is not None]
    
    if len(discovered) < target:
        log(f"Advertencia: Solo {len(discovered)} de {target} equipos levantaron correctamente.", Colors.YELLOW)
        if len(discovered) == 0: return

    log(f"\n--- FASE 2: CONFIGURACIÓN SEGURA ---", Colors.BOLD)
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        results = list(executor.map(flash_process_stable, discovered))
    
    for i in range(len(discovered)):
        discovered[i]['status'] = "EXITO" if results[i] else "FALLO"

    log(f"\n--- FASE 3: REVERSIÓN BLINDADA ---", Colors.YELLOW)
    payload_reversion = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
    
    for dev in discovered:
        url = f"http://{dev['ip']}/cgi/sysipset.cgi"
        for _ in range(3):
            try: 
                requests.post(url, auth=dev['auth'], data=payload_reversion, timeout=2)
                break
            except (requests.exceptions.ReadTimeout, requests.exceptions.ConnectionError):
                break
            except:
                time.sleep(0.5)
        time.sleep(0.3)

    log(f"\n--- FASE 4: AUDITORÍA Y BARRIDO FINAL ---", Colors.CYAN)
    time.sleep(3)
    
    # SEGURO EXPLICITO: Re-verificación estricta de IPs
    for dev in discovered:
        temp_ip = dev['ip']
        url = f"http://{temp_ip}/cgi/sysipset.cgi"
        
        # Si la IP temporal responde, reintentamos hasta 3 veces forzar su regreso
        intento = 0
        while verify_http(temp_ip, timeout=0.8) and intento < 3:
            intento += 1
            log(f" [!] {temp_ip} aún responde en IP temporal. Re-aplicando reversión (Intento {intento})...", Colors.YELLOW)
            try:
                requests.post(url, auth=dev['auth'], data=payload_reversion, timeout=2)
            except Exception:
                pass
            
            if os.name == 'nt':
                subprocess.run(["arp", "-d", temp_ip], capture_output=True)
            time.sleep(2)
        
        if not verify_http(temp_ip, timeout=0.5):
            log(f" [OK] {dev['mac']} ({temp_ip}) regresó exitosamente a {BASE_IP}.", Colors.GREEN)
        else:
            log(f" [ALERTA] {dev['mac']} sigue respondiendo en {temp_ip}.", Colors.RED)

        # Guardado de Backup independiente del estado de red
        if dev.get('status') == "EXITO":
            backup.save(dev['mac'], dev['status'])

    backup.export_session()
    
    exitos = [dev['mac'] for dev in discovered if dev.get('status') == "EXITO"]
    discord.send_webhook(exitos, target, "Switch PoE 1Gb Masivo")
    
    print(f"\n{Colors.GREEN}PROCESO FINALIZADO CON ÉXITO.{Colors.END}")
    for dev in discovered:
        c = Colors.GREEN if dev.get('status') == "EXITO" else Colors.RED
        print(f" MAC: {dev['mac']} | Status: {c}{dev.get('status', 'DESCONOCIDO')}{Colors.END}")
    input("\nENTER para salir...")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n🛑 PROCESO DETENIDO POR EL USUARIO.")
        try:
            d = DiscordNotifier()
            d.send_webhook([], 0, "Switch PoE 1Gb Masivo", is_interrupted=True)
        except: pass
    except Exception as e:
        print(f"\n\n🚨 ERROR CRÍTICO: {e}")
        try:
            d = DiscordNotifier()
            d.send_error("Switch PoE 1Gb Masivo", str(e))
        except: pass
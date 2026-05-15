import requests
import time
import subprocess
import re
import os
import sys
from concurrent.futures import ThreadPoolExecutor

# =====================================================================
# CONFIGURACIÓN DEL SISTEMA (V33 STABLE + LOTE SIMULTÁNEO 2.5Gb)
# =====================================================================
BASE_IP = "192.168.18.1"
PASSWORDS = ["admin", "somos123."]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FW_FILE = os.path.join(BASE_DIR, "upg_appimage2.bin")
CONFIG_FILE = os.path.join(BASE_DIR, "Configmanage2.bin")
LOG_FILE = os.path.join(BASE_DIR, "log_masivo_2.5gb.txt")
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
    # Lectura nativa Windows
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

def esperar_pulso_reinicio(ip, prefix, max_down=12):
    start_down = time.time()
    while (time.time() - start_down) < max_down:
        if not verify_http(ip, timeout=0.3): break
        time.sleep(0.3)
    
    start_up = time.time()
    while (time.time() - start_up) < 40:
        if verify_http(ip, timeout=0.5): return True
        time.sleep(0.7) # Polleo más rápido para detectar el retorno
    return False

def esperar_equipo_original(ip, max_wait=30):
    start = time.time()
    while (time.time() - start) < max_wait:
        if verify_http(ip): return True
        time.sleep(1)
    return False

def subir_archivo_turbo(session, url, file_path, prefix):
    try:
        with open(file_path, 'rb') as f:
            # Para 2.5G el campo debe ser 'file'
            r = session.post(url, files={'file': f}, timeout=75, headers={"Expect": ""})
            return r.status_code in [200, 302]
    except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
        return True # El switch suele reiniciar inmediatamente
    except: return False

def subir_archivo_resiliente(session, url, file_path, prefix):
    for i in range(2):
        if subir_archivo_turbo(session, url, file_path, prefix):
            return True
        log(f"{prefix}Reintentando subida (Intento {i+2})...", Colors.YELLOW)
        time.sleep(2)
    return False

def flash_process_stable(dev):
    ip = dev['ip']
    prefix = f"[{ip}] "
    time.sleep(int(ip.split('.')[-1]) % 5 * 0.5)
    
    try:
        with requests.Session() as s:
            s.auth = dev['auth']
            s.headers.update({"Connection": "close"})
            
            # 0. Preparación
            try:
                log(f"{prefix}Activando modo Flash...", Colors.YELLOW)
                s.post(f"http://{ip}/cgi/toBootLoadUpgrade.cgi", timeout=3)
                time.sleep(8)
            except Exception as e:
                with open(LOG_FILE, "a", encoding="utf-8") as f:
                    f.write(f"[{time.strftime('%H:%M:%S')}] {prefix}Excepción en modo Flash (ignorado): {e}\n")

            # 1. FW
            log(f"{prefix}Subiendo FW (2.5Gb)...", Colors.YELLOW)
            if subir_archivo_resiliente(s, f"http://{ip}/cgi/upg_appimage.bin", FW_FILE, prefix):
                log(f"{prefix}FW Enviado. Grabando...", Colors.CYAN)
                time.sleep(5)
                esperar_pulso_reinicio(ip, prefix, max_down=10)
            else: return False

            # 2. Config
            log(f"{prefix}Subiendo Config (2.5Gb)...", Colors.YELLOW)
            # El endpoint correcto para 2.5G es SW_CFG.bin
            if subir_archivo_resiliente(s, f"http://{ip}/cgi/SW_CFG.bin", CONFIG_FILE, prefix):
                time.sleep(2) # Reducido de 5s a 2s
                esperar_pulso_reinicio(ip, prefix, max_down=6) # max_down reducido
            else: return False

            # 3. Seguridad
            log(f"{prefix}Verificando clave...", Colors.CYAN)
            for _ in range(3):
                if verify_http_auth(ip, "admin", "somos123."):
                    log(f"{prefix}INTEGRIDAD OK.", Colors.GREEN)
                    dev['auth'] = ("admin", "somos123.")
                    return True
                try:
                    auth_temp = ("admin", "admin")
                    data = {"U": "admin", "NU": "admin", "P1": "somos123.", "P2": "somos123."}
                    requests.post(f"http://{ip}/cgi/usermng.cgi", auth=auth_temp, data=data, timeout=5)
                    time.sleep(2)
                except: pass
                
            return False
    except: return False

def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{Colors.CYAN}==========================================================")
    print(f"   HELLOTEK - 2.5Gb STABLE (LOTE SIMULTÁNEO SEGURO)       ")
    print(f"=========================================================={Colors.END}")

    try:
        target = int(input(f"\nEquipos en lote: "))
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
                
                # Vaciado de caché ARP para evitar quedarse colgado en el mismo equipo
                if os.name == 'nt':
                    try:
                        res_arp = subprocess.run(["arp", "-d", BASE_IP], capture_output=True, text=True)
                        if res_arp.returncode != 0:
                            with open(LOG_FILE, "a", encoding="utf-8") as f:
                                f.write(f"[{time.strftime('%H:%M:%S')}] Advertencia ARP: {res_arp.stderr.strip() or 'Fallo silencioso'}\n")
                    except Exception as e:
                        with open(LOG_FILE, "a", encoding="utf-8") as f:
                            f.write(f"[{time.strftime('%H:%M:%S')}] Error en ARP: {e}\n")
                
                # Pausa optimizada
                time.sleep(1.0) 
                    
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
    for dev in discovered:
        url = f"http://{dev['ip']}/cgi/sysipset.cgi"
        payload = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
        for _ in range(2): # Doble intento de seguridad
            try: 
                requests.post(url, auth=dev['auth'], data=payload, timeout=2)
                break
            except (requests.exceptions.ReadTimeout, requests.exceptions.ConnectionError):
                break # Si corta la conexión, es porque aplicó el cambio con éxito
            except:
                time.sleep(1)
        time.sleep(0.5) # Evita colapsar el switch con 10 IPs simultáneas

    log(f"\n--- FASE 4: AUDITORÍA Y REGISTRO ---", Colors.CYAN)
    time.sleep(5)
    with open(MACS_FILE, "a") as f_mac:
        for dev in discovered:
            if verify_http(dev['ip']): # Reintento de rescate si el equipo sigue atascado
                url = f"http://{dev['ip']}/cgi/sysipset.cgi"
                payload = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
                try: requests.post(url, auth=dev['auth'], data=payload, timeout=3)
                except: pass
            else:
                if dev['status'] == "EXITO":
                    f_mac.write(f"{dev['mac']}\n")
                log(f" [OK] {dev['ip']} regresó al origen.", Colors.GREEN)

    print(f"\n{Colors.GREEN}PROCESO FINALIZADO CON ÉXITO.{Colors.END}")
    for dev in discovered:
        c = Colors.GREEN if dev['status'] == "EXITO" else Colors.RED
        print(f" MAC: {dev['mac']} | Status: {c}{dev['status']}{Colors.END}")
    input("\nENTER para salir...")

if __name__ == "__main__":
    main()

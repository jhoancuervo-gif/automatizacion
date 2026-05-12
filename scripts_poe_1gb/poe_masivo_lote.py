import requests
import time
import subprocess
import re
import os
import sys
from concurrent.futures import ThreadPoolExecutor

# =====================================================================
# CONFIGURACIÓN DEL SISTEMA (V37 - GUARANTEED RETURN)
# =====================================================================
BASE_IP = "192.168.18.1"
PASSWORDS = ["admin", "somos123."]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FW_FILE = os.path.join(BASE_DIR, "upg_appimage.bin")
CONFIG_FILE = os.path.join(BASE_DIR, "Configmanage.bin")
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

def verify_http(ip, timeout=0.5):
    try:
        r = requests.get(f"http://{ip}/index.htm", timeout=timeout)
        return r.status_code in [200, 401]
    except: return False

def verify_http_auth(ip, user, pwd):
    try:
        r = requests.get(f"http://{ip}/index.htm", auth=(user, pwd), timeout=1.0)
        return r.status_code == 200
    except: return False

def esperar_pulso_reinicio_med(ip, prefix, max_down=10):
    start_down = time.time()
    while (time.time() - start_down) < max_down:
        if not verify_http(ip, timeout=0.3): break
        time.sleep(0.5)
    
    start_up = time.time()
    while (time.time() - start_up) < 40:
        if verify_http(ip): return True
        time.sleep(1)
    return False

def subir_archivo_turbo(session, url, file_path, prefix):
    try:
        with open(file_path, 'rb') as f:
            r = session.post(url, files={'FN': f}, timeout=60)
            return r.status_code == 200
    except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
        return True 
    except: return False

def flash_process_guaranteed(dev):
    ip = dev['ip']
    prefix = f"[{ip}] "
    time.sleep((int(ip.split('.')[-1]) % 5) * 0.3)
    
    try:
        s = requests.Session()
        s.auth = dev['auth']
        s.headers.update({"Connection": "close"})
        
        # 1. FW
        log(f"{prefix}Subiendo FW...", Colors.YELLOW)
        if subir_archivo_turbo(s, f"http://{ip}/cgi/upg_appimage.bin", FW_FILE, prefix):
            esperar_pulso_reinicio_med(ip, prefix, max_down=10)
        else: return False

        # 2. Config
        log(f"{prefix}Subiendo Config...", Colors.YELLOW)
        if subir_archivo_turbo(s, f"http://{ip}/cgi/SG1008.bin", CONFIG_FILE, prefix):
            time.sleep(2)
            esperar_pulso_reinicio_med(ip, prefix, max_down=6)
        else: return False

        # 3. Seguridad
        log(f"{prefix}Chequeando clave...", Colors.CYAN)
        for _ in range(3):
            if verify_http_auth(ip, "admin", "somos123."):
                log(f"{prefix}OK.", Colors.GREEN)
                dev['auth'] = ("admin", "somos123.")
                return True
            try:
                auth_temp = ("admin", "admin")
                data = {"U": "admin", "NU": "admin", "P1": "somos123.", "P2": "somos123."}
                requests.post(f"http://{ip}/cgi/usermng.cgi", auth=auth_temp, data=data, timeout=5)
                time.sleep(1.5)
            except: pass
        return False
    except: return False

def revertir_ip(ip, auth):
    """Orden de cambio de IP simple"""
    url = f"http://{ip}/cgi/sysipset.cgi"
    payload = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
    try: requests.post(url, auth=auth, data=payload, timeout=3)
    except: pass

def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{Colors.CYAN}==========================================================")
    print(f"   HELLOTEK - V37 (GUARANTEED RETURN - MAX 10)           ")
    print(f"=========================================================={Colors.END}")

    target = 0
    while target <= 0 or target > 10:
        try:
            line = input(f"\nCantidad de equipos (Máximo 10): ")
            target = int(line)
            if target > 10: print(f"{Colors.RED}[!] Máximo 10 equipos.{Colors.END}")
            elif target <= 0: print(f"{Colors.RED}[!] Ingrese un número válido.{Colors.END}")
        except ValueError: print(f"{Colors.RED}[!] Ingrese un número entero.{Colors.END}")

    discovered = []
    ip_index = 3
    
    log(f"\n--- FASE 1: DISPERSIÓN ---", Colors.BOLD)
    while len(discovered) < target:
        subprocess.run(["arp", "-d", BASE_IP], capture_output=True)
        auth = None
        for pwd in PASSWORDS:
            try:
                r = requests.get(f"http://{BASE_IP}/index.htm", auth=("admin", pwd), timeout=1.2)
                if r.status_code == 200:
                    auth = ("admin", pwd)
                    break
            except: continue
            
        if auth:
            subprocess.run(["ping", "-n", "1", "-w", "300", BASE_IP], capture_output=True)
            res = subprocess.run(["arp", "-a", BASE_IP], capture_output=True, text=True)
            match = re.search(r"([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})", res.stdout)
            mac = match.group(0).upper().replace("-", ":") if match else None
            
            if mac and not any(d['mac'] == mac for d in discovered):
                temp_ip = f"192.168.18.{ip_index}"
                try:
                    requests.post(f"http://{BASE_IP}/cgi/sysipset.cgi", auth=auth, 
                                 data={"IP": temp_ip, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}, timeout=4)
                    discovered.append({"mac": mac, "ip": temp_ip, "auth": auth})
                    ip_index += 1
                    log(f" [✔] {mac} -> {temp_ip}", Colors.GREEN)
                    time.sleep(0.5)
                except: pass
        time.sleep(0.8)

    log(f"\n--- FASE 2: CONFIGURACIÓN ---", Colors.BOLD)
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        results = list(executor.map(flash_process_guaranteed, discovered))
    
    for i in range(len(discovered)):
        discovered[i]['status'] = "EXITO" if results[i] else "FALLO"

    log(f"\n--- FASE 3: REVERSIÓN INICIAL ---", Colors.YELLOW)
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for dev in discovered:
            executor.submit(revertir_ip, dev['ip'], dev['auth'])

    log(f"\n--- FASE 4: AUDITORÍA DE GARANTÍA (BARRIDO DE RANGO) ---", Colors.CYAN)
    time.sleep(5)
    # Barrido de seguridad por todo el rango posible (3 al 12)
    for _reintento in range(2):
        for ip_check in range(3, 13):
            target_ip = f"192.168.18.{ip_check}"
            subprocess.run(["arp", "-d", target_ip], capture_output=True)
            if verify_http(target_ip, timeout=0.4):
                log(f" [!] Detectado equipo en {target_ip}. Forzando regreso...", Colors.RED)
                # Intentamos con ambas claves posibles
                for pwd in PASSWORDS:
                    revertir_ip(target_ip, ("admin", pwd))
                time.sleep(1)
        time.sleep(2)

    # Registro de MACs
    with open(MACS_FILE, "a") as f_mac:
        for dev in discovered:
            if dev['status'] == "EXITO":
                f_mac.write(f"{dev['mac']}\n")

    print(f"\n{Colors.GREEN}PROCESO FINALIZADO.{Colors.END}")
    for dev in discovered:
        c = Colors.GREEN if dev['status'] == "EXITO" else Colors.RED
        print(f" MAC: {dev['mac']} | Status: {c}{dev['status']}{Colors.END}")
    input("\nENTER para finalizar...")

if __name__ == "__main__":
    main()

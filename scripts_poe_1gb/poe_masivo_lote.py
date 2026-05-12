import requests
import time
import subprocess
import re
import os
import sys
from concurrent.futures import ThreadPoolExecutor

# =====================================================================
# CONFIGURACIÓN DEL SISTEMA (V32 - HARDENED PASSWORD EDITION)
# =====================================================================
BASE_IP = "192.168.18.1"
PASSWORDS = ["admin", "somos123."]
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FW_FILE = os.path.join(BASE_DIR, "upg_appimage.bin")
CONFIG_FILE = os.path.join(BASE_DIR, "Configmanage.bin")
LOG_FILE = os.path.join(BASE_DIR, "log_masivo.txt")

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
        r = requests.get(f"http://{ip}/index.htm", auth=(user, pwd), timeout=1.2)
        return r.status_code == 200
    except: return False

def esperar_pulso_reinicio(ip, prefix, max_down=10):
    start_down = time.time()
    while (time.time() - start_down) < max_down:
        if not verify_http(ip, timeout=0.3): break
        time.sleep(0.3)
    
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

def flash_process_hardened(dev):
    ip = dev['ip']
    prefix = f"[{ip}] "
    try:
        s = requests.Session()
        s.auth = dev['auth']
        s.headers.update({"Connection": "close"})
        
        # 1. FW
        log(f"{prefix}Subiendo FW...", Colors.YELLOW)
        if subir_archivo_turbo(s, f"http://{ip}/cgi/upg_appimage.bin", FW_FILE, prefix):
            esperar_pulso_reinicio(ip, prefix, max_down=10)
        else: return False

        # 2. Config
        log(f"{prefix}Subiendo Config...", Colors.YELLOW)
        if subir_archivo_turbo(s, f"http://{ip}/cgi/SG1008.bin", CONFIG_FILE, prefix):
            # Pausa de estabilidad post-config
            time.sleep(3)
            esperar_pulso_reinicio(ip, prefix, max_down=5)
        else: return False

        # 3. Cambio de Clave Obligatorio
        log(f"{prefix}Verificando clave...", Colors.CYAN)
        # Probamos si ya es 'somos123.'
        if verify_http_auth(ip, "admin", "somos123."):
            log(f"{prefix}INTEGRIDAD OK.", Colors.GREEN)
            dev['auth'] = ("admin", "somos123.")
            return True
        
        # Si no es, probamos con 'admin' para cambiarla manualmente
        log(f"{prefix}Clave actual es 'admin'. Forzando cambio...", Colors.YELLOW)
        try:
            auth_temp = ("admin", "admin")
            data = {"U": "admin", "NU": "admin", "P1": "somos123.", "P2": "somos123."}
            r = requests.post(f"http://{ip}/cgi/usermng.cgi", auth=auth_temp, data=data, timeout=5)
            time.sleep(1)
            if verify_http_auth(ip, "admin", "somos123."):
                log(f"{prefix}INTEGRIDAD OK (Forzada).", Colors.GREEN)
                dev['auth'] = ("admin", "somos123.")
                return True
        except: pass
            
        log(f"{prefix}FALLO: No se pudo establecer la clave 'somos123.'.", Colors.RED)
        return False
    except: return False

def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{Colors.CYAN}==========================================================")
    print(f"   HELLOTEK - V32 (HARDENED PASSWORD)                    ")
    print(f"=========================================================={Colors.END}")

    try:
        target = int(input(f"\nCantidad de equipos en lote: "))
    except: return

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
                payload = {"IP": temp_ip, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
                try: requests.post(f"http://{BASE_IP}/cgi/sysipset.cgi", auth=auth, data=payload, timeout=4)
                except: pass
                
                if esperar_equipo_nitro(temp_ip, 15):
                    discovered.append({"mac": mac, "ip": temp_ip, "auth": auth})
                    ip_index += 1
                    log(f" [✔] {mac} -> {temp_ip}", Colors.GREEN)
                    time.sleep(1)
        time.sleep(1)

    log(f"\n--- FASE 2: CONFIGURACIÓN Y SEGURIDAD ---", Colors.BOLD)
    with ThreadPoolExecutor(max_workers=len(discovered)) as executor:
        results = list(executor.map(flash_process_hardened, discovered))
    
    for i in range(len(discovered)):
        discovered[i]['status'] = "EXITO" if results[i] else "FALLO"

    log(f"\n--- FASE 3: REVERSIÓN ---", Colors.YELLOW)
    for dev in discovered:
        url = f"http://{dev['ip']}/cgi/sysipset.cgi"
        payload = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
        try: requests.post(url, auth=dev['auth'], data=payload, timeout=3)
        except: pass

    log(f"\n--- FASE 4: AUDITORÍA ---", Colors.CYAN)
    time.sleep(4)
    for dev in discovered:
        if verify_http(dev['ip']):
            log(f" [!] {dev['ip']} ocupada. Reintentando...", Colors.RED)
            url = f"http://{dev['ip']}/cgi/sysipset.cgi"
            payload = {"IP": BASE_IP, "MK": "255.255.255.0", "GW": "0.0.0.0", "MV": "1"}
            try: requests.post(url, auth=dev['auth'], data=payload, timeout=3)
            except: pass
        else:
            log(f" [OK] {dev['ip']} libre.", Colors.GREEN)

    print(f"\n{Colors.GREEN}PROCESO FINALIZADO.{Colors.END}")
    for dev in discovered:
        c = Colors.GREEN if dev['status'] == "EXITO" else Colors.RED
        print(f" MAC: {dev['mac']} | Status: {c}{dev['status']}{Colors.END}")
    input("\nENTER para salir...")

def esperar_equipo_nitro(ip, max_wait=30):
    start = time.time()
    while (time.time() - start) < max_wait:
        if verify_http(ip): return True
        time.sleep(1)
    return False

if __name__ == "__main__":
    main()

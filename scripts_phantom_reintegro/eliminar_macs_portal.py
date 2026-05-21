import os
import shutil
import requests
import time
import threading
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from concurrent.futures import ThreadPoolExecutor, as_completed

# =========================
# CONFIGURACIÓN
# =========================
load_dotenv()

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(SCRIPT_DIR)
MAC_FILE_PATH = os.path.join(PARENT_DIR, "macs.txt")

USERNAME = os.getenv("ISP_USERNAME")
PASSWORD = os.getenv("ISP_PASSWORD")

# 🔥 HILOS DE EJECUCIÓN (Workers)
# 5 es un número seguro para no saturar el servidor del ISP y evitar bloqueos por Firewall.
MAX_WORKERS = 10

if not USERNAME or not PASSWORD:
    print("❌ ERROR: Faltan las credenciales en el archivo .env")
    exit(1)

BASE_URL = "https://isp.somosinternet.com"
LOGIN_URL = f"{BASE_URL}/admin/login/"
DEVICE_BASE_URL = f"{BASE_URL}/admin/config/device/"
MAC_SEARCH_URL = f"{DEVICE_BASE_URL}?q="

# Bloqueo para que los prints de diferentes hilos no se mezclen en pantalla
print_lock = threading.Lock()

# =========================
# FUNCIONES AUXILIARES
# =========================
def normalize_mac(mac):
    clean_mac = ''.join(c for c in mac if c.isalnum()).upper()
    if len(clean_mac) == 12:
        return ':'.join(clean_mac[i:i + 2] for i in range(0, 12, 2))
    return None

def read_and_clean_macs():
    try:
        if not os.path.exists(MAC_FILE_PATH):
            print(f"❌ El archivo no existe en: {MAC_FILE_PATH}")
            return []

        with open(MAC_FILE_PATH, 'r', encoding='utf-8') as file:
            lines = file.readlines()

        seen = set()
        unique_macs = []
        for line in lines:
            line_clean = line.strip()
            if not line_clean or line_clean.startswith('=') or 'RESULTADOS' in line_clean or 'Total' in line_clean:
                continue
            
            parts = line_clean.split('|') if '|' in line_clean else line_clean.split()
            if parts:
                mac_candidate = parts[0].strip()
                mac = normalize_mac(mac_candidate)
                if mac and mac not in seen:
                    seen.add(mac)
                    unique_macs.append(mac)

        if unique_macs:
            print(f"📊 Total MACs únicas detectadas en el archivo: {len(unique_macs)}")

        return unique_macs
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return []

def login_session():
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    try:
        resp = session.get(LOGIN_URL, timeout=30)
        soup = BeautifulSoup(resp.text, 'html.parser')
        csrf_token = soup.find('input', {'name': 'csrfmiddlewaretoken'})

        if not csrf_token:
            return None

        payload = {
            "username": USERNAME,
            "password": PASSWORD,
            "csrfmiddlewaretoken": csrf_token['value'],
            "next": "/admin/"
        }
        login_resp = session.post(LOGIN_URL, data=payload, headers={"Referer": LOGIN_URL}, timeout=30)

        if "admin" in login_resp.url or "logout" in login_resp.text.lower() or "cerrar sesión" in login_resp.text.lower():
            print("   ✅ [LOGIN] Sesión conectada y verificada.")
            return session
        return None
    except Exception as e:
        print(f"   ❌ [LOGIN] Error de red: {e}")
        return None

# =========================
# LÓGICAS DE BORRADO (Rápido y Respaldo)
# =========================
def fallback_classic_delete(session, mac, search_url, search_soup, logs):
    try:
        device_href = None
        for a in search_soup.find_all("a", href=True):
            href = a['href']
            if href.startswith("/admin/config/device/") and href.endswith("/change/"):
                device_href = href
                break
                
        if not device_href:
            return "ERROR_ENLACE_PERFIL"

        device_url = urljoin(BASE_URL, device_href)
        device_resp = session.get(device_url, timeout=30)
        device_soup = BeautifulSoup(device_resp.text, "html.parser")

        deactivate_btn = device_soup.find("input", {"name": "_deactivate"})
        if deactivate_btn:
            logs.append("   ⚙️ (Respaldo) Desactivando equipo desde perfil...")
            csrf = device_soup.find("input", {"name": "csrfmiddlewaretoken"})['value']
            payload = {"csrfmiddlewaretoken": csrf, "_deactivate": "Deactivate"}
            session.post(device_url, data=payload, headers={"Referer": device_url}, timeout=30)
            
            # Recargar perfil tras desactivar
            device_resp = session.get(device_url, timeout=30)
            device_soup = BeautifulSoup(device_resp.text, "html.parser")

        delete_link_node = device_soup.find("a", class_="deletelink")
        if not delete_link_node:
            return "ERROR_BOTON_DELETE_FALTANTE"

        logs.append("   🗑️ (Respaldo) Procesando formulario de borrado...")
        delete_confirm_url = urljoin(BASE_URL, delete_link_node['href'])
        confirm_resp = session.get(delete_confirm_url, timeout=30)
        confirm_soup = BeautifulSoup(confirm_resp.text, "html.parser")

        form = confirm_soup.find("form")
        if not form:
            return "ERROR_FORMULARIO_RESPALDO"

        action_url = urljoin(delete_confirm_url, form.get("action", ""))
        confirm_payload = {}
        for inp in form.find_all("input"):
            if inp.get("name"):
                confirm_payload[inp.get("name")] = inp.get("value", "")

        confirm_payload["post"] = "yes"
        confirm_payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")

        session.post(action_url, data=confirm_payload, headers={"Referer": delete_confirm_url}, allow_redirects=False, timeout=30)

        # Verificación exacta
        time.sleep(1)
        verify_resp = session.get(search_url, timeout=30)
        if "0 results" in verify_resp.text or "/change/" not in verify_resp.text:
            return "SUCCESS"
        else:
            return "ERROR_EQUIPO_RESISTENTE"

    except Exception as e:
        return f"ERROR_RESPALDO_{e}"

def process_single_mac(session, mac, idx, total):
    """Función de trabajo (Worker) ejecutada en paralelo por cada MAC"""
    logs = [f"\n🔍 [{idx}/{total}] Procesando dispositivo: {mac}"]
    try:
        search_url = MAC_SEARCH_URL + mac
        resp = session.get(search_url, timeout=30)

        soup = BeautifulSoup(resp.text, "html.parser")
        checkbox = soup.find("input", {"name": "_selected_action"})
        
        if not checkbox:
            logs.append("   🔍 MAC no encontrada en la lista general del portal.")
            _flush_logs(logs)
            return mac, "NOT_FOUND"
            
        device_id = checkbox.get("value")
        
        # INTENTO A: Acción Masiva
        logs.append("   🚀 Intentando acción rápida 'Delete selected device'...")
        csrf_token = soup.find("input", {"name": "csrfmiddlewaretoken"})
        csrf_value = csrf_token['value'] if csrf_token else session.cookies.get("csrftoken", "")

        payload = {
            "csrfmiddlewaretoken": csrf_value,
            "action": "delete_selected",
            "_selected_action": device_id,
            "select_across": "0",
            "index": "0"
        }
        
        action_resp = session.post(DEVICE_BASE_URL, data=payload, headers={"Referer": search_url}, timeout=30)
        action_soup = BeautifulSoup(action_resp.text, "html.parser")

        form = None
        for f in action_soup.find_all("form"):
            if f.find("input", {"name": "action", "value": "delete_selected"}):
                form = f
                break
        
        if form:
            logs.append("   ✅ Acción rápida permitida. Confirmando...")
            confirm_payload = {}
            for inp in form.find_all("input"):
                if inp.get("name"):
                    confirm_payload[inp.get("name")] = inp.get("value", "")

            confirm_payload["post"] = "yes"
            action_url = urljoin(action_resp.url, form.get("action", ""))
            session.post(action_url, data=confirm_payload, headers={"Referer": action_resp.url}, allow_redirects=False, timeout=30)
            
            # Verificación
            time.sleep(1)
            verify_resp = session.get(search_url, timeout=30)
            verify_soup = BeautifulSoup(verify_resp.text, "html.parser")
            if not verify_soup.find("input", {"value": device_id}):
                logs.append("   ✅ ¡Eliminado exitosamente! (Rápido)")
                _flush_logs(logs)
                return mac, "SUCCESS"

        # INTENTO B: Respaldo Clásico
        logs.append("   ⚠️ Protección detectada por el portal. Cambiando a método clásico...")
        status = fallback_classic_delete(session, mac, search_url, soup, logs)
        
        if status == "SUCCESS":
            logs.append("   ✅ ¡Eliminado exitosamente! (Clásico)")
        else:
            logs.append(f"   ❌ Falló la eliminación. Causa: {status}")
            
        _flush_logs(logs)
        return mac, status

    except Exception as e:
        logs.append(f"   ❌ Error interno: {e}")
        _flush_logs(logs)
        return mac, f"ERROR_INTERNO_{e}"

def _flush_logs(logs):
    """Imprime todos los mensajes de una MAC a la vez para que no se crucen en consola."""
    with print_lock:
        for log in logs:
            print(log)

# =========================
# FLUJO PRINCIPAL
# =========================
def main():
    print("=" * 60)
    print(" ELIMINAR MACS PORTAL (SISTEMA HÍBRIDO + PARALELO MULTIHILO)")
    print("=" * 60)
    
    macs = read_and_clean_macs()
    if not macs:
        print("❌ No hay MACs válidas para procesar en macs.txt.")
        input("\nPresione una tecla para terminar...")
        return

    session = login_session()
    if not session:
        print("❌ No se pudo iniciar sesión.")
        return

    print(f"\n⚡ Iniciando procesamiento en paralelo ({MAX_WORKERS} hilos simultáneos)...")
    print("Por favor espera, los resultados irán apareciendo...\n")

    exitos = errores = no_encontradas = 0
    total_macs = len(macs)

    # 🚀 LA MAGIA DEL PARALELISMO OCURRE AQUÍ
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # Enviamos todas las MACs al "Pool" de trabajadores al mismo tiempo
        futures = []
        for idx, mac in enumerate(macs, 1):
            futures.append(executor.submit(process_single_mac, session, mac, idx, total_macs))
        
        # A medida que los trabajadores terminan, recolectamos sus resultados
        for future in as_completed(futures):
            mac, status = future.result()
            
            if status == "SUCCESS":
                exitos += 1
            elif status == "NOT_FOUND":
                no_encontradas += 1
            else:
                errores += 1

    # RESUMEN FINAL
    print(f"\n📊 RESUMEN DE LA EJECUCIÓN:")
    print(f"   Total evaluadas: {total_macs}")
    print(f"   ✅ Eliminadas con éxito: {exitos}")
    print(f"   ❌ Errores detectados: {errores}")
    print(f"   🔍 No encontradas en el portal: {no_encontradas}")
    print("=" * 60)

    input("\nPresione una tecla para finalizar...")

if __name__ == "__main__":
    main()
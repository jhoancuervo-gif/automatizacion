    #!/usr/bin/env python3
import os
import sys
import time
import requests
import argparse
import shutil
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from urllib.parse import urljoin
from logger_tools import log_to_master

# Configuración Global
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

USERNAME = os.getenv("ISP_USERNAME")
PASSWORD = os.getenv("ISP_PASSWORD")
BASE_URL = os.getenv("PORTAL_URL", "https://isp.somosinternet.com").rstrip('/')
LOGIN_URL = f"{BASE_URL}/admin/login/"
SEARCH_URL = f"{BASE_URL}/admin/config/device/?q="

def normalize_mac(mac):
    clean_mac = ''.join(c for c in mac if c.isalnum()).upper()
    if len(clean_mac) == 12:
        return ':'.join(clean_mac[i:i + 2] for i in range(0, 12, 2))
    return clean_mac

def login_session():
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    try:
        res = session.get(LOGIN_URL, timeout=10)
        soup = BeautifulSoup(res.text, 'html.parser')
        csrf = soup.find('input', {'name': 'csrfmiddlewaretoken'})['value']
        payload = {
            'username': USERNAME,
            'password': PASSWORD,
            'csrfmiddlewaretoken': csrf,
            'next': '/admin/'
        }
        session.post(LOGIN_URL, data=payload, headers={'Referer': LOGIN_URL})
        return session
    except Exception as e:
        print(f"❌ Error de Login: {e}")
        return None

def verify_macs(mac_file):
    print(f"\n[📡] INICIANDO VERIFICACIÓN EN PORTAL...")
    if not os.path.exists(mac_file):
        print(f"❌ No existe el archivo: {mac_file}")
        return

    with open(mac_file, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip() and '|' not in line]

    session = login_session()
    if not session: return

    for mac in macs:
        res = session.get(f"{SEARCH_URL}{mac}")
        encontrada = '/change/' in res.url or BeautifulSoup(res.text, 'html.parser').select_one('#result_list')
        status = "🟩 ENCONTRADA" if encontrada else "⬜ NO ENCONTRADA"
        print(f" > {mac} -> {status}")
        log_to_master("PORTAL_VERIFY", mac, "ENCONTRADA" if encontrada else "NO ENCONTRADA")

def delete_macs(mac_file):
    print(f"\n[🗑️] INICIANDO ELIMINACIÓN EN PORTAL...")
    # Lógica simplificada basada en el script original de eliminación
    # (Se implementa una versión robusta pero concisa)
    if not os.path.exists(mac_file):
        print(f"❌ No existe el archivo: {mac_file}")
        return

    with open(mac_file, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip() and '|' not in line]

    session = login_session()
    if not session: return

    for mac in macs:
        print(f"🔍 Procesando {mac}...", end=" ", flush=True)
        res = session.get(f"{SEARCH_URL}{mac}")
        soup = BeautifulSoup(res.text, 'html.parser')
        
        # Buscar el link de edición
        link = soup.select_one('#result_list th.field-name a') or soup.select_one('#result_list th.field-mac_address a')
        if not link:
            print("❌ No encontrada")
            continue
            
        details_url = urljoin(BASE_URL, link['href'])
        det_res = session.get(details_url)
        det_soup = BeautifulSoup(det_res.text, 'html.parser')
        
        # Buscar botón de eliminación
        action_btn = det_soup.select_one('.deletelink')
        if not action_btn:
            print("❌ No se puede eliminar (no hay botón)")
            continue
            
        btn_val = (action_btn.get("value") or action_btn.text).strip().lower()
        success = False
        
        # PASO 1: SI ES DEACTIVATE
        if "deactivate" in btn_val:
            form_id = action_btn.get("form")
            target_form = det_soup.find("form", id=form_id) if form_id else action_btn.find_parent("form")
            if target_form:
                payload = {inp.get("name"): inp.get("value", "") for inp in target_form.find_all("input") if inp.get("name")}
                payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")
                action = target_form.get("action")
                post_url = urljoin(details_url, action) if action else details_url
                session.post(post_url, data=payload, headers={"Referer": details_url})
                time.sleep(1)
                
                # Recargar para buscar el botón Delete
                det_res = session.get(details_url)
                det_soup = BeautifulSoup(det_res.text, 'html.parser')
                action_btn = det_soup.select_one('.deletelink')
                if action_btn:
                    btn_val = (action_btn.get("value") or action_btn.text).strip().lower()

        # PASO 2: SI ES DELETE
        if action_btn and ("delete" in btn_val or "eliminar" in btn_val):
            if action_btn.name == "a" and action_btn.get("href"):
                delete_url = urljoin(details_url, action_btn.get("href"))
                del_page = session.get(delete_url)
                del_soup = BeautifulSoup(del_page.text, "html.parser")
                
                target_form = None
                for f in del_soup.find_all("form"):
                    if f.get("id") == "logout-form": continue
                    if f.find("input", {"name": "csrfmiddlewaretoken"}):
                        target_form = f
                        break
                        
                if target_form:
                    payload = {inp.get("name"): inp.get("value", "") for inp in target_form.find_all(["input", "button"]) if inp.get("name")}
                    payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")
                    payload["post"] = "yes"
                    payload["force_delete"] = "true"
                    action = target_form.get("action")
                    post_url = urljoin(delete_url, action) if action else delete_url
                    session.post(post_url, data=payload, headers={"Referer": delete_url}, allow_redirects=False)
                    success = True
            elif action_btn.name in ["input", "button"]:
                form_id = action_btn.get("form")
                target_form = det_soup.find("form", id=form_id) if form_id else action_btn.find_parent("form")
                if target_form:
                    payload = {inp.get("name"): inp.get("value", "") for inp in target_form.find_all("input") if inp.get("name")}
                    payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")
                    payload["post"] = "yes"
                    payload["force_delete"] = "true"
                    action = target_form.get("action")
                    post_url = urljoin(details_url, action) if action else details_url
                    session.post(post_url, data=payload, headers={"Referer": details_url}, allow_redirects=False)
                    success = True

        if success:
            print("✅ ELIMINADA")
            log_to_master("PORTAL_DELETE", mac, "ELIMINADA_OK")
        else:
            print("❌ Falló eliminación")
            log_to_master("PORTAL_DELETE", mac, "FALLO_ELIMINACION")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Herramientas de Portal ISP")
    parser.add_argument("action", choices=["verify", "delete"], help="Acción a realizar")
    parser.add_argument("--file", required=True, help="Ruta al archivo macs.txt")
    
    args = parser.parse_args()
    
    if args.action == "verify":
        verify_macs(args.file)
    elif args.action == "delete":
        delete_macs(args.file)

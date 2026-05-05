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
        del_link = det_soup.select_one('.deletelink')
        if not del_link:
            print("❌ No se puede eliminar (¿ya desactivada?)")
            continue
            
        # Seguir flujo de eliminación
        confirm_url = urljoin(details_url, del_link['href'])
        conf_res = session.get(confirm_url)
        conf_soup = BeautifulSoup(conf_res.text, 'html.parser')
        
        # Formulario de confirmación
        csrf = conf_soup.find('input', {'name': 'csrfmiddlewaretoken'})['value']
        post_data = {'csrfmiddlewaretoken': csrf, 'post': 'yes'}
        
        del_res = session.post(confirm_url, data=post_data, headers={'Referer': confirm_url})
        if del_res.status_code == 200:
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

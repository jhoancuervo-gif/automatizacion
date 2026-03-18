#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from config import PortalConfig, Config

def login_session():
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0'})
    try:
        res = session.get(PortalConfig.LOGIN_URL)
        soup = BeautifulSoup(res.text, 'html.parser')
        csrf = soup.find('input', {'name': 'csrfmiddlewaretoken'})['value']
        payload = {
            'username': PortalConfig.USERNAME,
            'password': PortalConfig.PASSWORD,
            'csrfmiddlewaretoken': csrf,
            'next': '/admin/'
        }
        session.post(PortalConfig.LOGIN_URL, data=payload, headers={'Referer': PortalConfig.LOGIN_URL})
        return session
    except Exception: return None

def main():
    print(f"\n==========================================")
    print(f"   ELIMINACIÓN PORTAL (RAÍZ: macs.txt)")
    print(f"==========================================")
    
    if not Config.MAC_FILE.exists():
        print(f"❌ No se encontró macs.txt en la raíz.")
        return

    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip()]

    if not macs:
        print("📭 Nada que eliminar (archivo vacío).")
        return

    session = login_session()
    if not session: 
        print("❌ Error de acceso al portal.")
        return

    print(f"🔐 Sesión iniciada. Procesando {len(macs)} equipos...\n")

    for mac in macs:
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        delete_url = None
        
        if '/change/' in res.url:
            delete_url = res.url.replace('/change/', '/delete/')
        else:
            soup = BeautifulSoup(res.text, 'html.parser')
            link = soup.select_one('#result_list tbody tr th a')
            if link:
                delete_url = f"{PortalConfig.PORTAL_URL}{link.get('href').replace('change/', 'delete/')}"

        if delete_url:
            c_res = session.get(delete_url)
            c_soup = BeautifulSoup(c_res.text, 'html.parser')
            csrf = c_soup.find('input', {'name': 'csrfmiddlewaretoken'})['value']
            session.post(delete_url, data={'post': 'yes', 'csrfmiddlewaretoken': csrf}, headers={'Referer': delete_url})
            print(f" > {mac} -> 🗑️ BORRADA")
        else:
            print(f" > {mac} -> ⚠️ NO ENCONTRADA")
            
    print("\n==========================================")
    print("✅ PROCESO DE ELIMINACIÓN FINALIZADO")
    print("==========================================")

# --- BLOQUE DE RETORNO SEGURO ---
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado por el usuario.")
    except Exception as e:
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        input("\n[🔔] Presione ENTER para volver al menú principal...")
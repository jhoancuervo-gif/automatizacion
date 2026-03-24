#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from config import PortalConfig, Config

def login_session():
    """Establece sesión en el portal capturando el token CSRF inicial."""
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0'})
    try:
        res = session.get(PortalConfig.LOGIN_URL)
        soup = BeautifulSoup(res.text, 'html.parser')

        csrf_tag = soup.find('input', {'name': 'csrfmiddlewaretoken'})
        if not csrf_tag:
            return None

        csrf = csrf_tag['value']
        payload = {
            'username': PortalConfig.USERNAME,
            'password': PortalConfig.PASSWORD,
            'csrfmiddlewaretoken': csrf,
            'next': '/admin/'
        }
        session.post(PortalConfig.LOGIN_URL, data=payload, headers={'Referer': PortalConfig.LOGIN_URL})
        return session
    except Exception:
        return None

def main():
    print(f"\n==========================================")
    print(f"   DESACTIVACIÓN PORTAL (RAÍZ: macs.txt)")
    print(f"==========================================")

    if not Config.MAC_FILE.exists():
        print(f"❌ No se encontró macs.txt en la raíz.")
        return

    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip()]

    if not macs:
        print("📭 Nada que procesar (archivo vacío).")
        return

    session = login_session()
    if not session:
        print("❌ Error de acceso al portal (Verifique credenciales o conexión).")
        return

    print(f"🔐 Sesión iniciada. Procesando {len(macs)} equipos...\n")

    for mac in macs:
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        deactivate_url = None

        # CORRECCIÓN: Ahora buscamos el endpoint 'deactivate' en lugar de 'delete'
        if '/change/' in res.url:
            deactivate_url = res.url.replace('/change/', '/deactivate/')[cite: 4]

        else:
            soup = BeautifulSoup(res.text, 'html.parser')
            link = soup.select_one('#result_list tbody tr th a')
            if link:
                href = link.get('href')
                # Cambiamos la sustitución de la URL para apuntar a desactivación
                deactivate_url = f"{PortalConfig.PORTAL_URL}{href.replace('change/', 'deactivate/')}"[cite: 4]

        # --- BLOQUE DE DESACTIVACIÓN ACTUALIZADO ---
        if deactivate_url:
            c_res = session.get(deactivate_url)
            c_soup = BeautifulSoup(c_res.text, 'html.parser')

            csrf_tag = c_soup.find('input', {'name': 'csrfmiddlewaretoken'})

            if csrf_tag:
                csrf = csrf_tag['value']
                # Confirmamos la desactivación enviando el POST al nuevo endpoint
                session.post(deactivate_url, data={'post': 'yes', 'csrfmiddlewaretoken': csrf},
                             headers={'Referer': deactivate_url})[cite: 4]
                print(f" > {mac} -> ⚪ DESACTIVADA")
            else:
                print(f" > {mac} -> ❌ ERROR: No se pudo cargar el formulario de desactivación.")
        else:
            print(f" > {mac} -> ⚠️ NO ENCONTRADA")

    print("\n==========================================")
    print("✅ PROCESO DE DESACTIVACIÓN FINALIZADO")
    print("==========================================")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado por el usuario.")
    except Exception as e:
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        input("\n[🔔] Presione ENTER para volver al menú principal...")
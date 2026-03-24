#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
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
        # 1. Buscar el equipo
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        soup = BeautifulSoup(res.text, 'html.parser')
        
        change_url = res.url if '/change/' in res.url else None
        if not change_url:
            link = soup.select_one('#result_list tbody tr th a')
            if link:
                change_url = urljoin(res.url, link.get('href'))
        
        if not change_url:
            print(f" > {mac} -> ⚠️ NO ENCONTRADA")
            continue

        # 2. Entrar a la página de edición
        res_edit = session.get(change_url)
        soup_edit = BeautifulSoup(res_edit.text, 'html.parser')
        
        # BUSQUEDA: Buscamos el input de tipo submit con valor 'Deactivate' y clase 'deletelink'
        deactivate_input = soup_edit.find('input', {'value': 'Deactivate', 'class': 'deletelink'})
        
        if deactivate_input:
            # Identificamos el ID del formulario al que pertenece el botón
            form_id = deactivate_input.get('form')
            deactivate_form = soup_edit.find('form', {'id': form_id})
            
            if deactivate_form:
                # Obtenemos la URL de acción del formulario
                action_url = urljoin(change_url, deactivate_form.get('action', 'deactivate/'))
                
                # Capturamos el token CSRF necesario para el POST
                csrf_token = deactivate_form.find('input', {'name': 'csrfmiddlewaretoken'})['value']
                
                # 3. Enviar la desactivación (Simulando el clic en el botón)
                post_data = {
                    'csrfmiddlewaretoken': csrf_token,
                    'post': 'yes'
                }
                
                session.post(action_url, data=post_data, headers={'Referer': change_url})
                print(f" > {mac} -> ⚪ DESACTIVADA")
            else:
                # Ruta de respaldo si el formulario no tiene ID explícito
                fallback_url = change_url.replace('/change/', '/deactivate/')
                csrf_token = soup_edit.find('input', {'name': 'csrfmiddlewaretoken'})['value']
                session.post(fallback_url, data={'post': 'yes', 'csrfmiddlewaretoken': csrf_token}, headers={'Referer': change_url})
                print(f" > {mac} -> ⚪ DESACTIVADA (Ruta alternativa)")
        else:
            print(f" > {mac} -> ❌ ERROR: No se encontró el botón 'Deactivate' en la página.")

    print("\n==========================================")
    print("✅ PROCESO DE DESACTIVACIÓN FINALIZADO")
    print("==========================================")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        input("\n[🔔] Presione ENTER para volver al menú principal...")
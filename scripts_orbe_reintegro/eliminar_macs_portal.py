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

        # Validación de seguridad para el login
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
    print(f"   ELIMINACIÓN PORTAL (RAÍZ: macs.txt)")
    print(f"==========================================")

    # 1. Verificar si existe el archivo de MACs
    if not Config.MAC_FILE.exists():
        print(f"❌ No se encontró macs.txt en la raíz.")
        return

    # 2. Leer y limpiar las MACs del archivo
    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip()]

    if not macs:
        print("📭 Nada que eliminar (archivo vacío).")
        return

    # 3. Iniciar sesión
    session = login_session()
    if not session:
        print("❌ Error de acceso al portal (Verifique credenciales en .env o conexión).")
        return

    print(f"🔐 Sesión iniciada. Procesando {len(macs)} equipos...\n")

    for mac in macs:
        # Buscamos el equipo en el portal
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        delete_url = None

        # Caso A: El portal nos redirige directo al objeto (vista de cambio)
        if '/change/' in res.url:
            delete_url = res.url.replace('/change/', '/delete/')

        # Caso B: El portal nos muestra una lista de resultados
        else:
            soup = BeautifulSoup(res.text, 'html.parser')
            link = soup.select_one('#result_list tbody tr th a')
            if link:
                href = link.get('href')
                delete_url = f"{PortalConfig.PORTAL_URL}{href.replace('change/', 'delete/')}"

        # --- BLOQUE DE ELIMINACIÓN CORREGIDO ---
        if delete_url:
            c_res = session.get(delete_url)
            c_soup = BeautifulSoup(c_res.text, 'html.parser')

            # Buscamos el token de confirmación de forma SEGURA
            csrf_tag = c_soup.find('input', {'name': 'csrfmiddlewaretoken'})

            if csrf_tag:
                csrf = csrf_tag['value']
                # Enviamos la confirmación de borrado
                session.post(delete_url, data={'post': 'yes', 'csrfmiddlewaretoken': csrf},
                             headers={'Referer': delete_url})
                print(f" > {mac} -> 🗑️ BORRADA")
            else:
                # Si encontró el link pero no pudo cargar el formulario de borrado
                print(f" > {mac} -> ❌ ERROR: Sesión expirada o permisos insuficientes para borrar.")
        else:
            # Si el link de borrado nunca se encontró
            print(f" > {mac} -> ⚠️ NO ENCONTRADA (Verifique si la MAC existe en el portal)")

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
        # Este bloque ahora atrapará cualquier otro error sin cerrar la ventana de golpe
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        input("\n[🔔] Presione ENTER para volver al menú principal...")
#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
from config import PortalConfig, Config

def login_session():
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0'})
    try:
        res = session.get(PortalConfig.LOGIN_URL, timeout=15)
        soup = BeautifulSoup(res.text, 'html.parser')
        token_input = soup.find('input', {'name': 'csrfmiddlewaretoken'})
        if not token_input:
            print("❌ No se encontró el token CSRF (¿portal caído o cambió la página de login?).")
            return None
        csrf = token_input['value']
        payload = {
            'username': PortalConfig.USERNAME,
            'password': PortalConfig.PASSWORD,
            'csrfmiddlewaretoken': csrf,
            'next': '/admin/'
        }
        post = session.post(PortalConfig.LOGIN_URL, data=payload, headers={'Referer': PortalConfig.LOGIN_URL}, timeout=15)
        # Si seguimos en /login/, las credenciales fueron rechazadas
        if '/login/' in post.url:
            print("❌ Credenciales rechazadas por el portal. Revise ISP_USERNAME / ISP_PASSWORD en el archivo .env")
            return None
        return session
    except requests.exceptions.Timeout:
        print("❌ Tiempo de espera agotado al contactar el portal (red lenta o portal caído). Intente de nuevo.")
        return None
    except requests.exceptions.ConnectionError:
        print("❌ No se pudo conectar al portal (sin internet o portal inaccesible).")
        return None
    except Exception as e:
        print(f"❌ Error inesperado en login: {type(e).__name__} -> {e}")
        return None

def main():
    print(f"\n==========================================")
    print(f"   VERIFICACIÓN ESTRICTA EN PORTAL")
    print(f"==========================================")
    
    if not Config.MAC_FILE.exists():
        print(f"❌ No existe macs.txt en la raíz.")
        return

    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip()]

    session = login_session()
    if not session:
        # El detalle del error ya fue impreso por login_session()
        return

    print(f"📡 Verificando {len(macs)} equipos...\n")

    for mac in macs:
        # Normalizamos la MAC para la búsqueda
        mac_clean = mac.replace(":", "").replace(".", "").replace("-", "")
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        soup = BeautifulSoup(res.text, 'html.parser')
        
        encontrada = False
        
        # 1. Si redirige directo a la edición, es positivo
        if '/change/' in res.url:
            encontrada = True
        
        # 2. Si hay una tabla de resultados, buscamos la MAC dentro de las celdas (<td> o <th>)
        else:
            tabla = soup.select_one('#result_list')
            if tabla:
                # Solo marcamos como encontrada si el texto de la MAC está DENTRO de la tabla de resultados
                texto_tabla = tabla.get_text().upper()
                if mac in texto_tabla or mac_clean in texto_tabla:
                    encontrada = True

        # Salida visual
        if encontrada:
            print(f" > {mac} -> 🟩 ENCONTRADA")
        else:
            print(f" > {mac} -> ⬜ NO ENCONTRADA")

    print(f"\n==========================================")

if __name__ == "__main__":
    main()
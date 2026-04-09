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
    except Exception:
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
        print("❌ Error de Login.")
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
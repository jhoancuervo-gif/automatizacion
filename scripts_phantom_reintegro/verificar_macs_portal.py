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
    print(f"   VERIFICACIÓN PHANTOM - MODO PRECISO")
    print(f"==========================================")
    
    if not Config.MAC_FILE.exists():
        print(f"❌ No existe macs.txt en la raíz.")
        return

    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        macs = [line.strip().split(' ')[0].upper() for line in f if line.strip()]

    if not macs:
        print("⚠️ El archivo macs.txt está vacío.")
        return

    print(f"Iniciando sesión en el portal...")
    session = login_session()
    if not session:
        print("❌ Error de conexión o credenciales.")
        return
    print(f"✅ Sesión iniciada. Verificando {len(macs)} equipos...\n")

    for mac in macs:
        mac_clean = mac.replace(":", "").replace(".", "").replace("-", "")
        
        res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
        soup = BeautifulSoup(res.text, 'html.parser')
        
        encontrada = False
        texto_pagina = res.text.upper()
        
        # --- ESCANEO REFORZADO Y PRECISO ---
        
        # 1. Filtro estricto: Descartar inmediatamente si la página indica que no hay nada
        if "0 DISPOSITIVOS" in texto_pagina or "0 RESULTADOS" in texto_pagina:
            encontrada = False
            
        # 2. Redirección directa: Si el portal entra directo a la página de edición del equipo
        elif '/change/' in res.url:
            encontrada = True
            
        # 3. Verificación de tabla real: Buscar solo en las filas (tr) de la tabla de resultados
        else:
            filas = soup.select('#result_list tbody tr')
            if filas:
                for fila in filas:
                    texto_fila = fila.get_text().upper()
                    # Validar que la MAC esté en la fila y que no sea una fila de "No se encontraron resultados"
                    if (mac in texto_fila or mac_clean in texto_fila) and "NO ENCONTR" not in texto_fila:
                        encontrada = True
                        break

        # Salida visual
        if encontrada:
            print(f" > {mac} -> 🟩 ENCONTRADA")
        else:
            print(f" > {mac} -> 🟥 NO ESTÁ EN EL PORTAL")

if __name__ == "__main__":
    main()
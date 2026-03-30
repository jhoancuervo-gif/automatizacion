import re
import time
import requests
from requests.auth import HTTPBasicAuth
from config.config import *

def extraer_mac_real(ip, user, password):
    # Configuración de URL y credenciales
    url = f"http://{ip}/lanset.htm"
    auth = HTTPBasicAuth(user, password)

    # Simulación de navegador para evitar bloqueos
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Referer': f'http://{ip}/index.htm',
    }

    # Bucle de reintentos (hasta 5 veces)
    for i in range(5):
        try:
            print(f"Intentando conectar a {ip} (Intento {i+1}/5)...")
            res = requests.get(url, auth=auth, headers=headers, timeout=10)

            # Si la conexión es exitosa
            if res.status_code == 200:
                # 1. Buscar MAC precedida específicamente por el texto 'MAC Address'
                match = re.search(r'MAC Address.*?([0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2})', res.text, re.S | re.I)
                if match:
                    return match.group(1).upper()

                # 2. Búsqueda general de cualquier MAC que no sea nula (00:00) ni de broadcast (FF:FF)
                todas_las_macs = re.findall(r'([0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2}[:][0-9A-Fa-f]{2})', res.text)
                for m in todas_las_macs:
                    if not m.startswith("00:00") and not m.upper().startswith("FF:FF"):
                        return m.upper()

                print(f"Página cargada pero no se encontró texto de MAC en el HTML.")
            
            # Manejo de errores de autenticación y recursos
            elif res.status_code == 401:
                print(f"Error 401: Usuario o contraseña incorrectos ({user}:{password}).")
            elif res.status_code == 404:
                print(f"Error 404: La página /lanset.htm no existe en este switch.")
            else:
                print(f"Error HTTP {res.status_code} no esperado.")

        # Manejo de fallos de red/tiempo de espera
        except requests.exceptions.RequestException as e:
            print(f"Error de conexión: {e}. Reintentando...")
        
        # Pausa antes del siguiente intento
        time.sleep(5)

    return "Fallo de lectura"
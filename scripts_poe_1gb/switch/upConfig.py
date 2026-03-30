from config.config import *
import requests
from requests.auth import HTTPBasicAuth
import urllib3
import os

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


async def config():
    if not os.path.exists(FILE_CONFIG):
        print(f"[!] No se encuentra el archivo {FILE_CONFIG}")
        return

    auth = HTTPBasicAuth(USER, PASS)
    session = requests.Session()
    session.headers.update({
        'Referer': f'{BASE_URL}/config_manage.html',
        'Origin': BASE_URL
    })

    try:
        print(f"[*] Leyendo binario {FILE_CONFIG}...")
        with open(FILE_CONFIG, 'rb') as f:
            bin_data = f.read()

        url_destino = f"{BASE_URL}/cgi/SW_CFG.bin"
        files = {'FN': (FILE_CONFIG, bin_data, 'application/octet-stream')}

        print(f"[*] Enviando archivo a {url_destino}...")

        try:
            # CORRECCIÓN: Se añade timeout=30 para evitar que el script se quede colgado
            res = session.post(url_destino, files=files, auth=auth, timeout=30)

            if res.status_code == 200:
                print("\n" + "=" * 50)
                print("¡CONFIGURACIÓN ENVIADA CON ÉXITO!")
                print("=" * 50)
            else:
                print(f"[!] El servidor respondió con código: {res.status_code}")

        except (requests.exceptions.ReadTimeout, requests.exceptions.ConnectionError):
            print("\n" + "=" * 50)
            print("¡PROCESO COMPLETADO!")
            print("El switch ha cortado la conexión para aplicar los cambios.")
            print("=" * 50)

    except Exception as e:
        print(f"\n[!] Error en Etapa 2: {e}")

    finally:
        session.close()
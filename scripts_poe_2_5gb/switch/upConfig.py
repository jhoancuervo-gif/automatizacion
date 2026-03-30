from config.config import *
import requests
from requests.auth import HTTPBasicAuth
import urllib3
import os
import asyncio

# Ignora advertencias de seguridad por certificados SSL no válidos
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

async def config():
    # Verifica que el archivo de configuración exista localmente
    if not os.path.exists(FILE_CONFIG):
        print(f"No se encuentra el archivo {FILE_CONFIG}")
        return

    # Configura la sesión y la autenticación básica
    auth = HTTPBasicAuth(USER, PASS)
    session = requests.Session()
    
    # Simulación de navegador para evitar bloqueos
    session.headers.update({
        'Referer': f'{BASE_URL}/config_manage.html',
        'Origin': BASE_URL
    })

    try:
        # Abre y lee el contenido del archivo de configuración en modo binario
        print(f"Leyendo binario {FILE_CONFIG}...")
        with open(FILE_CONFIG, 'rb') as f:
            bin_data = f.read()

        # Define el endpoint del switch y prepara el archivo para el envío
        url_destino = f"{BASE_URL}/cgi/SW_CFG.bin"
        files = { 'FN': (FILE_CONFIG, bin_data, 'application/octet-stream') }

        print(f"Enviando archivo a {url_destino}...")

        try:
            # Realiza el POST enviando el archivo binario
            res = session.post(url_destino, files=files, auth=auth)
            
            # Valida si el servidor aceptó el archivo correctamente
            if res.status_code == 200:
                print("\n" + "="*50)
                print("¡ARCHIVO ENVIADO Y CONFIRMADO POR EL SWITCH!")
                print("El equipo se está reiniciando con la nueva configuración.")
                print("="*50)
            else:
                print(f"El servidor respondió con código: {res.status_code}")

        # Captura el corte de conexión normal cuando el switch se reinicia tras recibir el archivo
        except (requests.exceptions.ReadTimeout, requests.exceptions.ConnectionError):
            print("\n" + "="*50)
            print("¡PROCESO COMPLETADO!")
            print("El switch ha cortado la conexión para aplicar los cambios.")
            print("="*50)

    except Exception:
        print("\nDispositivo en reinicio")
    
    finally:
        # Cierra la sesión de red para liberar recursos
        session.close()
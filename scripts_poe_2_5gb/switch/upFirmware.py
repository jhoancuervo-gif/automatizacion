import os
import time
import requests
from requests.auth import HTTPBasicAuth
import urllib3

# Importación de credenciales y rutas desde el archivo de configuración
from config.config import *

# Desactiva advertencias de certificados SSL no verificados
urllib3.disable_warnings()


# Configuración de sesión con autenticación básica y headers globales
session = requests.Session()
session.auth = HTTPBasicAuth(USER, PASS)

session.headers.update({
    "User-Agent": "Mozilla/5.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Connection": "keep-alive"
})

def preparar_sesion():
    # Navega por las páginas iniciales para establecer cookies y estado.
    print("[*] Preparando sesión web")
    session.get(BASE_URL, timeout=10)
    session.get(f"{BASE_URL}/frame.htm", timeout=10)
    session.get(f"{BASE_URL}/upgrade.htm", timeout=10)

def activar_bootloader():
    # Envía la instrucción para poner el dispositivo en modo actualización.
    print("[*] Activando bootloader REAL")

    r = session.post(
        f"{BASE_URL}/cgi/toBootLoadUpgrade.cgi",
        data="", 
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Referer": f"{BASE_URL}/upgrade.htm",
            "Origin": BASE_URL
        },
        timeout=10
    )

    print("status trigger:", r.status_code)

    if r.status_code != 200:
        print("[!] ERROR: no entró en modo upgrade")
        return False

    print("[+] Bootloader activado correctamente")
    time.sleep(2)
    return True

def subir_firmware():
    # Carga el archivo binario del firmware al dispositivo.
    if not os.path.exists(FILE_FIRMWARE):
        raise Exception("Firmware no encontrado")

    print("[*] Subiendo firmware...")

    with open(FILE_FIRMWARE, "rb") as f:
        # Prepara el archivo para el envío multipart/form-data
        files = {"FN": (os.path.basename(FILE_FIRMWARE), f, "application/octet-stream")}

        try:
            r = session.post(
                f"{BASE_URL}/cgi/upg_appimage.bin",
                files=files,
                headers={
                    "Referer": f"{BASE_URL}/upgrade.htm",
                    "Origin": BASE_URL
                },
                timeout=600 # Timeout largo para permitir la transferencia
            )
            print("upload status:", r.status_code)

        except requests.exceptions.ConnectionError:
            # El switch suele cortar la conexión al recibir el archivo y reiniciar
            print("\n[+] Switch cerró conexión -> firmware aceptado")
            return True

        except requests.exceptions.ReadTimeout:
            # Timeout esperado si el dispositivo deja de responder para flashear
            print("\n[+] Timeout -> switch aplicando firmware")
            return True

    return False

async def mainFirmware():
    # Orquestador principal del proceso de actualización.
    try:
        preparar_sesion()

        if not activar_bootloader():
            return

        if subir_firmware():
            print("\n[+] Firmware subido correctamente, el switch se está reiniciando...")
        return True 

    finally:
        # Asegura el cierre de la sesión incluso si hay errores
        session.close()
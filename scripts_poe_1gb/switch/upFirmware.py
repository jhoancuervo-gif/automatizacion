import os
import time
import requests
from requests.auth import HTTPBasicAuth
import urllib3
from config.config import *

urllib3.disable_warnings()

session = requests.Session()
session.auth = HTTPBasicAuth(USER, PASS)
session.headers.update({
    "User-Agent": "Mozilla/5.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Connection": "keep-alive"
})

def preparar_sesion():
    print("[*] Preparando sesión web")
    try:
        session.get(BASE_URL, timeout=10)
        session.get(f"{BASE_URL}/frame.htm", timeout=10)
        session.get(f"{BASE_URL}/upgrade.htm", timeout=10)
    except: pass

def activar_bootloader():
    print("[*] Activando bootloader REAL")
    try:
        r = session.post(
            f"{BASE_URL}/cgi/toBootLoadUpgrade.cgi",
            data="",
            headers={"Referer": f"{BASE_URL}/upgrade.htm"},
            timeout=10 # Timeout para evitar bloqueos
        )
        if r.status_code == 200:
            print("[+] Bootloader activado correctamente")
            time.sleep(2)
            return True
    except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
        # El switch corta la conexión al entrar en modo upgrade
        print("[+] Conexión cerrada por el switch (Bootloader Activo)")
        return True
    return False

def subir_firmware():
    if not os.path.exists(FILE_FIRMWARE):
        print(f"[!] Error: Firmware {FILE_FIRMWARE} no encontrado")
        return False

    print("[*] Subiendo firmware...")
    with open(FILE_FIRMWARE, "rb") as f:
        files = {"FN": (os.path.basename(FILE_FIRMWARE), f, "application/octet-stream")}
        try:
            r = session.post(f"{BASE_URL}/cgi/upg_appimage.bin", files=files, timeout=600)
            return True
        except (requests.exceptions.ConnectionError, requests.exceptions.ReadTimeout):
            print("\n[+] Firmware aceptado (el switch se está reiniciando)")
            return True
    return False

async def mainFirmware():
    try:
        preparar_sesion()
        if activar_bootloader():
            time.sleep(3)
            return subir_firmware()
        return False
    finally:
        session.close()
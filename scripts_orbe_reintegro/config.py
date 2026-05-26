import os
from pathlib import Path
from dotenv import load_dotenv

# Localizar la raíz del proyecto (sube un nivel desde la carpeta de Orbes)
BASE_DIR = Path(__file__).parent.parent.absolute()
CURRENT_DIR = Path(__file__).parent.absolute()

# Cargar el .env que está en la raíz
load_dotenv(BASE_DIR / ".env", encoding='latin-1')

class Config:
    """Configuración Unificada Orbe"""
    BASE_DIR = BASE_DIR
    # Archivos en la Raíz
    MAC_FILE = BASE_DIR / "macs.txt"
    BACKUP_DIR = BASE_DIR / "backups_macs"
    TEMP_SESION = BASE_DIR / "mac_orbe_reintegro.txt"
    
    if not BACKUP_DIR.exists(): BACKUP_DIR.mkdir(parents=True)

    # Configuración de Red (Prioriza lo que diga el .env)
    IP_BASE = os.getenv("IP_BASE", "192.168.10.")
    IP_START = int(os.getenv("ORBE_IP_START", os.getenv("IP_START", "200")))
    IP_END = int(os.getenv("ORBE_IP_END", os.getenv("IP_END", "215")))
    
    SSH_PASSWORD = os.getenv("SSH_PASSWORD", "M7h$)Fw3|;63*h?ET")
    FIRMWARE_PATH = CURRENT_DIR / "somosORB2-PROD.bin"

    # Notificaciones Discord
    WEBHOOK_INGRESO    = os.getenv("DISCORD_WEBHOOK_INGRESO", "")
    WEBHOOK_PRODUCCION = os.getenv("DISCORD_WEBHOOK_PRODUCCION", "")

class PortalConfig:
    """Configuración del Portal"""
    PORTAL_URL = os.getenv("PORTAL_URL", "").rstrip('/')
    LOGIN_URL = f"{PORTAL_URL}/admin/login/"
    SEARCH_URL = f"{PORTAL_URL}/admin/config/device/?q="
    USERNAME = os.getenv("ISP_USERNAME")
    PASSWORD = os.getenv("ISP_PASSWORD")
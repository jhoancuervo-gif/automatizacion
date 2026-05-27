import os
from pathlib import Path
from dotenv import load_dotenv

# Ubicación de las carpetas (Sube un nivel a la raíz)
BASE_DIR = Path(__file__).resolve().parent.parent
CURRENT_DIR = Path(__file__).resolve().parent

load_dotenv(BASE_DIR / ".env", encoding='latin-1')

class Config:
    """Configuración Maestra Única de Cuervo"""
    BASE_DIR = BASE_DIR
    # 1. El archivo maestro acumulativo
    MAC_FILE = BASE_DIR / "macs.txt"
    
    # 2. Carpeta única para reportes y backups
    BACKUP_DIR = BASE_DIR / "backups_macs"
    if not BACKUP_DIR.exists(): BACKUP_DIR.mkdir(parents=True)
    
    # 3. ARCHIVOS TEMPORALES (Se sobrescriben y se abren al finalizar)
    TEMP_REINTEGRO = BASE_DIR / "mac_phantomf2_reintegro.txt"
    TEMP_VERIFICAR = BASE_DIR / "mac_verificadas.txt"
    TEMP_ELIMINAR = BASE_DIR / "mac_eliminadas.txt"

    # Configuración de red
    IP_BASE = os.getenv("IP_BASE", "192.168.10.")
    IP_START = int(os.getenv("IP_START", "212"))
    IP_END = int(os.getenv("IP_END", "215"))
    SSH_PASSWORD = os.getenv("SSH_PASSWORD", "M7h$)Fw3|;63*h?ET")
    FIRMWARE_PATH = CURRENT_DIR / "somos-openwrt-24.10.5-somosfw-mediatek-filogic-somos_phantomf2.bin"
    # Notificaciones Discord
    WEBHOOK_INGRESO    = os.getenv("DISCORD_WEBHOOK_INGRESO", "")
    WEBHOOK_PRODUCCION = os.getenv("DISCORD_WEBHOOK_PRODUCCION", "")

class PortalConfig:
    """Configuración para el Portal ISP"""
    USERNAME = os.getenv("ISP_USERNAME")
    PASSWORD = os.getenv("ISP_PASSWORD")
    PORTAL_URL = os.getenv("PORTAL_URL", "").rstrip('/')
    LOGIN_URL = f"{PORTAL_URL}/admin/login/"
    SEARCH_URL = f"{PORTAL_URL}/admin/config/device/?q="
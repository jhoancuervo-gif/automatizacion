import os
from pathlib import Path
from dotenv import load_dotenv

BASE_DIR = Path(__file__).parent.parent.absolute()
CURRENT_DIR = Path(__file__).parent.absolute()

load_dotenv(BASE_DIR / '.env', encoding='latin-1')

class Config:
    """Configuración para Orbes Nuevas"""
    BASE_DIR = BASE_DIR
    CURRENT_DIR = CURRENT_DIR
    
    BACKUP_DIR = BASE_DIR / "backups_macs"
    if not BACKUP_DIR.exists(): BACKUP_DIR.mkdir(parents=True)
    
    MAC_FILE = BASE_DIR / "macs.txt"
    
    SSH_PASSWORD = os.getenv("SSH_PASSWORD", "M7h$)Fw3|;63*h?ET")
    DEVICE_IP = os.getenv("DEVICE_IP", "192.168.1.1")
    
    # CAMBIO: Firmware específico para Orbes
    FIRMWARE_PATH = CURRENT_DIR / "somosORB2-PROD.bin"

class PortalConfig:
    USERNAME = os.getenv("ISP_USERNAME")
    PASSWORD = os.getenv("ISP_PASSWORD")
    PORTAL_URL = os.getenv("PORTAL_URL")
    LOGIN_URL = f"{PORTAL_URL}/admin/login/"
    SEARCH_URL = f"{PORTAL_URL}/admin/config/device/?q="
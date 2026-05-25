import os
from pathlib import Path
from dotenv import load_dotenv

# Detectar la raíz (donde está tu archivo .env)
BASE_DIR = Path(__file__).parent.parent.absolute()
CURRENT_DIR = Path(__file__).parent.absolute()

load_dotenv(BASE_DIR / '.env')

class Config:
    """Configuración para Phantom Nuevos"""
    BASE_DIR = BASE_DIR
    CURRENT_DIR = CURRENT_DIR
    
    # Archivos Globales (En la raíz)
    BACKUP_DIR = BASE_DIR / "backups_macs"
    if not BACKUP_DIR.exists(): BACKUP_DIR.mkdir(parents=True)
    
    MAC_FILE = BASE_DIR / "macs.txt"
    
    # ARCHIVO TEMPORAL PARA PHANTOM NUEVOS
    TEMP_NUEVOS = BASE_DIR / "mac_phantom_nuevos.txt"
    TEMP_VERIFICAR = BASE_DIR / "mac_verificadas_nuevos.txt"
    
    # Configuración de dispositivo
    SSH_PASSWORD = os.getenv("SSH_PASSWORD", "M7h$)Fw3|;63*h?ET")
    DEVICE_IP = os.getenv("F2_DEVICE_IP", "192.168.10.1")
    
    # Firmware local
    FIRMWARE_PATH = CURRENT_DIR / "somos-openwrt-24.10.5-somosfw-mediatek-filogic-somos_phantomf2.bin"

    # Notificaciones Discord
    WEBHOOK_INGRESO    = os.getenv("DISCORD_WEBHOOK_INGRESO", "")
    WEBHOOK_PRODUCCION = os.getenv("DISCORD_WEBHOOK_PRODUCCION", "")

class PortalConfig:
    """Configuración del Portal ISP"""
    USERNAME = os.getenv("ISP_USERNAME")
    PASSWORD = os.getenv("ISP_PASSWORD")
    PORTAL_URL = os.getenv("PORTAL_URL", "").rstrip('/')
    LOGIN_URL = f"{PORTAL_URL}/admin/login/"
    SEARCH_URL = f"{PORTAL_URL}/admin/config/device/?q="
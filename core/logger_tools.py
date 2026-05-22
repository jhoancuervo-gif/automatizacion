"""Compatibilidad: delega en mac_backup (familia = modulo)."""
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE_DIR)
from mac_backup import MacBackup, normalize_mac

MASTER_LOG = os.path.join(BASE_DIR, "..", "backups_macs", "produccion_master.csv")


def log_to_master(modulo, mac, resultado, script_dir=None):
    """Guarda un registro en el CSV maestro de produccion."""
    if script_dir is None:
        script_dir = os.path.join(BASE_DIR, "..")
    backup = MacBackup(script_dir, modulo)
    backup.save(mac, resultado)

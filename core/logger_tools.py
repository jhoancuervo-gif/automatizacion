import os
import csv
from datetime import datetime

# Ruta al CSV maestro en backups_macs
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MASTER_LOG = os.path.join(BASE_DIR, "..", "backups_macs", "produccion_master.csv")

def log_to_master(modulo, mac, resultado):
    """Guarda un registro en el CSV maestro de produccion"""
    now = datetime.now()
    fecha = now.strftime("%Y-%m-%d")
    hora = now.strftime("%H:%M:%S")
    
    # Crear archivo con encabezados si no existe
    if not os.path.exists(MASTER_LOG):
        with open(MASTER_LOG, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(["Fecha", "Hora", "Modulo", "MAC", "Resultado"])
            
    try:
        with open(MASTER_LOG, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow([fecha, hora, modulo, mac, resultado])
    except Exception as e:
        print(f"⚠️ Error al escribir en el log maestro: {e}")

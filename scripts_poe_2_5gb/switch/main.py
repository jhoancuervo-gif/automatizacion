import asyncio
from datetime import datetime
import os

# Importación de módulos personalizados para cada etapa del proceso
from extractMac import extraer_mac_real
from upFirmware import mainFirmware
from upConfig import config
from changePassword import password
from online import esperar_reinicio_switch
from config.config import *

async def main():
    # Solicita al usuario el número de dispositivos a procesar en serie
    op = int(input("Selecione la cantidad de switch : "))

    for i in range(op):
        # Pausa de cortesía entre dispositivos para evitar colisiones de red
        if i != 0:
            print("Tiempo de esperar 10s para conectar al siguiente switch")
            await asyncio.sleep(10)

        print(f"\n--- Procesando Switch {i+1} ---")

        # --- SECCIÓN: Registro de MAC ---
        print("Extrayendo MAC desde la tabla del sistema...")
        await asyncio.sleep(5)
        mac = extraer_mac_real(IP, USER, PASS)

        if mac != "FALLO_TOTAL_LECTURA":
            existe = False
            # Verifica si la MAC ya fue procesada anteriormente consultando el log
            if os.path.exists("log_macs.txt"):
                with open("log_macs.txt", "r") as r:
                    if mac in r.read():
                        existe = True
            
            if existe:
                print(f"AVISO: MAC {mac} ya registrada")
            else:
                # Registra la nueva MAC con marca de tiempo
                print(f"MAC Detectada: {mac}")
                with open("log_macs.txt", "a") as f:
                    timestamp = datetime.now().strftime('%H:%M:%S')
                    f.write(f"\n[{timestamp}] MAC: {mac}")

        # --- ETAPA 1: Actualización de Firmware ---
        print("\n===== ETAPA 1: FIRMWARE =====")
        firmware_ok = await mainFirmware()
        if not firmware_ok:
            print("Firmware falló → saltando switch")
            continue # Salta al siguiente switch si esta etapa crítica falla
            
        print("Esperando reinicio tras firmware...")
        # Bloquea la ejecución hasta que el switch responda PING o HTTP (max 3 min)
        if not esperar_reinicio_switch(IP, timeout_maximo=180):
            print("Switch no volvió tras firmware")
            continue
        await asyncio.sleep(3)

        # --- ETAPA 2: Carga de Configuración ---
        print("\n===== ETAPA 2: CONFIG =====")
        await config()
        print("Esperando reinicio tras config...")
        # Segundo reinicio necesario para aplicar los cambios de configuración
        if not esperar_reinicio_switch(IP, timeout_maximo=180):
            print("Switch no volvió tras config")
            continue
        await asyncio.sleep(1)

        # --- ETAPA 3: Cambio de Credenciales Final ---
        print("\n===== ETAPA 3: PASSWORD =====")
        password()
        print(f"--- Switch {i+1} FINALIZADO ---\n")

if __name__ == "__main__":
    # Inicia el bucle de eventos asíncrono
    asyncio.run(main())
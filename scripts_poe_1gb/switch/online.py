import platform
import subprocess
import time
import sys

def comprobar_ping(ip, intentos=1, delay=3):
    # Detecta el sistema operativo para usar el parámetro de ping correcto
    # Windows usa '-n', Linux/Unix usa '-c'
    parametro = "-n" if platform.system().lower() == "windows" else "-c"
    
    # Construcción del comando de sistema
    comando = ["ping", parametro, str(intentos), ip]
    
    try:
        # Ejecuta el ping ocultando la salida en consola
        # Retorna True si el dispositivo responde (returncode 0)
        resultado = subprocess.run(comando, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return resultado.returncode == 0
    except Exception:
        return False

def esperar_reinicio_switch(ip, timeout_maximo=180):

    print(f"Esperando que {ip} reinicie...")

    inicio=time.time()
    se_cayo=False
    ya_estaba_vivo=False

    # Verificar estado inicial
    if comprobar_ping(ip):
        ya_estaba_vivo=True
        print("Switch ya está online, esperando que se caiga y vuelva...")

    while time.time()-inicio < timeout_maximo:

        vivo=comprobar_ping(ip)

        if not vivo:
            se_cayo=True

        if se_cayo and vivo:
            print("\nSwitch reiniciado correctamente")
            return True

        # Si ya estaba vivo desde el principio y lleva más de 30 segundos, asumir que ya reinició
        if ya_estaba_vivo and (time.time()-inicio > 30):
            print("\nSwitch ya está online (reiniciado rápidamente)")
            return True

        time.sleep(3)
        print(".",end="",flush=True)

    print("\nTimeout esperando reinicio")
    return False
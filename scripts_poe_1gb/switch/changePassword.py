import requests
from requests.auth import HTTPBasicAuth
import urllib3
from config.config import *

# Desactiva advertencias de certificados SSL no verificados
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def password():
    print(f"Corrigiendo envío para usuario '{NUEVO_USER}'...")
    # Configuración de autenticación básica con credenciales actuales
    auth = HTTPBasicAuth(USER, PASS)

    # Datos del formulario para cambiar usuario y contraseña
    payload = [
        ('U', PASS),    # Contraseña actual
        ('NU', NUEVO_USER),    # Nuevo nombre de usuario
        ('U', NUEVA_PASS),     # Nueva contraseña
        ('U', NUEVA_PASS),     # Confirmación de nueva contraseña
        ('Apply', 'Apply')     # Simulación de clic en el botón
    ]

    # Simulación de navegador para evitar bloqueos
    headers = {
        'Referer': f'http://{IP}/user_manage.html',
        'Content-Type': 'application/x-www-form-urlencoded'
    }

    try:
        # Envío de la petición POST al CGI de gestión de usuarios
        url = f"http://{IP}/cgi/usermng.cgi"
        res = requests.post(url, data=payload, auth=auth, headers=headers, timeout=10)

        # Verificación de éxito mediante códigos de alerta o texto en respuesta
        if "alertIdx = 5" in res.text or "success" in res.text.lower():
            print("\n" + "="*50)
            print("¡ÉXITO TOTAL! EL USUARIO FUE CAMBIADO ")
            print(f" Ahora puedes entrar con {NUEVO_USER} / {NUEVA_PASS}")
            print("="*50)
            # Guarda los cambios permanentemente en la configuración del switch
            requests.post(f"http://{IP}/cgi/config_manage.cgi", data={'m0':'1','Apply':'Apply'}, auth=auth)
        
        # Manejo de error específico por contraseñas no coincidentes
        elif "alertIdx = 3" in res.text:
            print("ERROR: El switch sigue diciendo que las claves no coinciden.")
        else:
            print(f"Respuesta del switch: {res.text[:200]}...")

    # Captura de cualquier error durante la ejecución del proceso
    except Exception as e:
        print(f"Error: {e}")
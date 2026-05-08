#!/usr/bin/env python3
import requests
import re
from bs4 import BeautifulSoup
from config import PortalConfig, Config

def login_session():
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0'})
    try:
        res = session.get(PortalConfig.LOGIN_URL)
        soup = BeautifulSoup(res.text, 'html.parser')
        csrf = soup.find('input', {'name': 'csrfmiddlewaretoken'})['value']
        payload = {
            'username': PortalConfig.USERNAME,
            'password': PortalConfig.PASSWORD,
            'csrfmiddlewaretoken': csrf,
            'next': '/admin/'
        }
        session.post(PortalConfig.LOGIN_URL, data=payload, headers={'Referer': PortalConfig.LOGIN_URL})
        return session
    except Exception:
        return None


def main():
    print(f"\n==========================================")
    print(f"   VERIFICACIÓN PORTAL - MODO PRECISO")
    print(f"==========================================")

    if not Config.MAC_FILE.exists():
        print(f"❌ No existe macs.txt en la raíz.")
        return

    # --- MEJORA: Patrón Regex para detectar formatos de MAC comunes ---
    # Detecta: 00:AA:BB:CC:DD:EE, 00-AA-BB-CC-DD-EE, 00AABBCCDDEE o 00aa.bbcc.ddee
    patron_mac = re.compile(
        r'([0-9A-Fa-f]{2}[:-]?){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4})')

    macs = []
    with open(Config.MAC_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Buscamos si hay una MAC válida en la línea
            match = patron_mac.search(line)
            if match:
                # Extraemos solo la MAC encontrada y la normalizamos a mayúsculas
                mac_encontrada = match.group(0).upper()
                macs.append(mac_encontrada)

    if not macs:
        print("⚠️ No se encontraron direcciones MAC válidas en macs.txt.")
        return

    print(f"Iniciando sesión en el portal...")
    session = login_session()
    if not session:
        print("❌ Error de conexión o credenciales.")
        return
    print(f"✅ Sesión iniciada. Verificando {len(macs)} equipos...\n")

    count_encontradas = 0
    count_no_encontradas = 0

    for mac in macs:
        # Limpieza para búsqueda interna si el portal requiere formato plano
        mac_clean = mac.replace(":", "").replace(".", "").replace("-", "")

        try:
            res = session.get(f"{PortalConfig.SEARCH_URL}{mac}")
            soup = BeautifulSoup(res.text, 'html.parser')

            encontrada = False
            texto_pagina = res.text.upper()

            # Lógica de detección según respuesta del portal
            if "0 DISPOSITIVOS" in texto_pagina or "0 RESULTADOS" in texto_pagina:
                encontrada = False
            elif '/change/' in res.url:
                encontrada = True
            else:
                filas = soup.select('#result_list tbody tr')
                if filas:
                    for fila in filas:
                        texto_fila = fila.get_text().upper()
                        # Verificamos si la MAC original o la limpia aparecen en la fila
                        if (mac in texto_fila or mac_clean in texto_fila) and "NO ENCONTR" not in texto_fila:
                            encontrada = True
                            break

            if encontrada:
                print(f" > {mac} -> 🟩 ENCONTRADA")
                count_encontradas += 1
            else:
                print(f" > {mac} -> 🟥 NO ESTÁ EN EL PORTAL")
                count_no_encontradas += 1

        except Exception as e:
            print(f" > {mac} -> ⚠️ ERROR AL CONSULTAR: {e}")
            count_no_encontradas += 1

    print("\n==========================================")
    print("✅ PROCESO DE VERIFICACIÓN FINALIZADO")
    print("==========================================")


# --- BLOQUE DE RETORNO SEGURO ---
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n⚠️ Proceso cancelado por el usuario.")
    except Exception as e:
        print(f"\n❌ Ocurrió un error inesperado: {e}")
    finally:
        input("\n[🔔] Presione ENTER para volver al menú principal...")
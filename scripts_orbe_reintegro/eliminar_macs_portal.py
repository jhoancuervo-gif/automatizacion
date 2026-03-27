import os
import shutil
import requests
import time
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from dotenv import load_dotenv

# =========================
# CONFIGURACIÓN
# =========================
load_dotenv()

USERNAME = os.getenv("ISP_USERNAME")
PASSWORD = os.getenv("ISP_PASSWORD")
MAC_FILE_PATH = os.getenv("MAC_FILE_PATH", r"C:\Phantom_script_ssh\macs.txt")

BASE_URL = "https://isp.somosinternet.com"
LOGIN_URL = f"{BASE_URL}/admin/login/"
MAC_SEARCH_URL = f"{BASE_URL}/admin/config/device/?q="
DEVICE_BASE_URL = f"{BASE_URL}/admin/config/device/"


# =========================
# FUNCIONES AUXILIARES
# =========================
def normalize_mac(mac):
    """Normaliza la MAC a formato 00:11:22:33:44:55"""
    clean_mac = ''.join(c for c in mac if c.isalnum()).upper()
    if len(clean_mac) == 12:
        return ':'.join(clean_mac[i:i + 2] for i in range(0, 12, 2))
    return clean_mac


def read_and_clean_macs():
    try:
        with open(MAC_FILE_PATH, 'r', encoding='utf-8') as file:
            original_lines = [line.strip() for line in file if line.strip()]

        if not original_lines:
            print("❌ El archivo MAC.txt está vacío")
            return [], []

        seen = set()
        unique_macs = []
        for line in original_lines:
            mac = normalize_mac(line.split(' ')[0].strip())
            if mac not in seen:
                seen.add(mac)
                unique_macs.append(mac)

        backup_path = f"{MAC_FILE_PATH}.backup.{int(time.time())}"
        shutil.copy(MAC_FILE_PATH, backup_path)
        print(f"📦 Backup creado: {backup_path}")

        return unique_macs, original_lines
    except Exception as e:
        print(f"❌ Error leyendo archivo: {e}")
        return [], []


def login_session():
    """Inicia sesión y retorna el objeto session"""
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})

    try:
        resp = session.get(LOGIN_URL)
        soup = BeautifulSoup(resp.text, 'html.parser')
        csrf_token = soup.find('input', {'name': 'csrfmiddlewaretoken'})

        if not csrf_token:
            print("   ❌ [LOGIN] No se encontró token CSRF")
            return None

        payload = {
            "username": USERNAME,
            "password": PASSWORD,
            "csrfmiddlewaretoken": csrf_token['value'],
            "next": "/admin/"
        }

        login_resp = session.post(LOGIN_URL, data=payload, headers={"Referer": LOGIN_URL})

        if "admin" in login_resp.url or "logout" in login_resp.text.lower() or "cerrar sesión" in login_resp.text.lower():
            print("   ✅ [LOGIN] Sesión conectada y verificada.")
            return session
        else:
            print("   ❌ [LOGIN] Credenciales incorrectas o bloqueo de seguridad.")
            return None
    except Exception as e:
        print(f"   ❌ [LOGIN] Error de red: {e}")
        return None


def extract_details(soup):
    """Extrae OS, Created y Modified"""
    os_val = created_val = modified_val = "N/A"
    for row in soup.select("div.form-row"):
        label = row.find("label")
        if not label: continue
        text = label.get_text(strip=True).lower()

        if "operating system" in text and os_val == "N/A":
            readonly = row.find("div", class_="readonly")
            if readonly:
                os_val = readonly.get_text(strip=True)
            else:
                inp = row.find("input")
                if inp and inp.get("value"): os_val = inp.get("value").strip()
        elif "created" in text and created_val == "N/A":
            val = row.find("div", class_="readonly")
            if val: created_val = val.get_text(strip=True)
        elif "modified" in text and modified_val == "N/A":
            val = row.find("div", class_="readonly")
            if val: modified_val = val.get_text(strip=True)

        if os_val != "N/A" and created_val != "N/A" and modified_val != "N/A":
            break
    return os_val, created_val, modified_val


# =========================
# LÓGICA DE VALIDACIÓN Y ELIMINACIÓN
# =========================
def process_mac(session, mac):
    try:
        search_url = MAC_SEARCH_URL + mac
        resp = session.get(search_url)

        if "login" in resp.url.lower():
            print("   ⚠️ Detectada expulsión de sesión. Reconectando...")
            session = login_session()
            if not session: return "session_error", None, session
            resp = session.get(search_url)

        soup = BeautifulSoup(resp.text, "html.parser")
        table = soup.find("table")

        if not table: return "not_found", None, session

        mac_cells = table.find_all("td", class_="field-mac_address")
        if not mac_cells: return "not_found", None, session

        displayed_mac = normalize_mac(mac_cells[0].get_text())
        if displayed_mac != mac: return "mismatch", None, session

        # Entramos a los detalles del dispositivo
        name_cell = table.find("th", class_="field-name")
        link_tag = name_cell.find("a") if name_cell else None

        if not link_tag or not link_tag.get("href"):
            return "error", None, session

        href = link_tag.get("href")
        details_url = BASE_URL + href
        parts = [p for p in href.split('/') if p]
        device_id = parts[-2] if len(parts) >= 2 else None

        det_resp = session.get(details_url)
        det_soup = BeautifulSoup(det_resp.text, "html.parser")

        os_val, created_val, modified_val = extract_details(det_soup)
        details_tuple = (os_val, created_val, modified_val)
        print(f"   ✅ Dispositivo encontrado | OS: {os_val}")

        # ==========================================================
        # LÓGICA DINÁMICA DEL BOTÓN DE ACCIÓN (.deletelink)
        # ==========================================================
        action_btn = det_soup.find(class_="deletelink")
        if not action_btn:
            print("   ❌ No se encontró el botón rojo de acción (.deletelink).")
            return "error", details_tuple, session

        btn_val = action_btn.get("value") or action_btn.text
        btn_val = btn_val.strip().lower()

        # --- PASO 1: SI ES DEACTIVATE ---
        if "deactivate" in btn_val:
            print("   🔄 Botón 'Deactivate' detectado. Procesando formulario oficial...")
            form_id = action_btn.get("form")
            target_form = det_soup.find("form", id=form_id) if form_id else action_btn.find_parent("form")

            if target_form:
                payload = {}
                for inp in target_form.find_all("input"):
                    if inp.get("name"): payload[inp.get("name")] = inp.get("value", "")
                payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")

                action = target_form.get("action")
                post_url = urljoin(details_url, action) if action else details_url

                # Ejecutamos desactivación y le damos tiempo
                session.post(post_url, data=payload, headers={"Referer": details_url})
                time.sleep(2)

                # Recargar la página para ver el botón actualizado (que debe ser Delete)
                det_resp = session.get(details_url)
                det_soup = BeautifulSoup(det_resp.text, "html.parser")
                action_btn = det_soup.find(class_="deletelink")

                if not action_btn:
                    print("   ❌ El botón desapareció tras desactivar.")
                    return "error", details_tuple, session

                btn_val = action_btn.get("value") or action_btn.text
                btn_val = btn_val.strip().lower()
            else:
                print("   ⚠️ No se encontró el formulario asociado al botón Deactivate.")

        # --- PASO 2: SI ES DELETE ---
        if "delete" in btn_val or "eliminar" in btn_val:
            print("   🗑️ Botón 'Delete' detectado. Siguiendo el flujo...")

            # Si el botón Delete nos envía a otra pantalla (es un enlace)
            if action_btn.name == "a" and action_btn.get("href"):
                delete_url = urljoin(details_url, action_btn.get("href"))
                del_page = session.get(delete_url)
                del_soup = BeautifulSoup(del_page.text, "html.parser")

                target_form = None
                for f in del_soup.find_all("form"):
                    if f.get("id") == "logout-form": continue
                    if f.find("input", {"name": "csrfmiddlewaretoken"}):
                        target_form = f
                        break

                if target_form:
                    payload = {}
                    for inp in target_form.find_all(["input", "button"]):
                        if inp.get("name"):
                            payload[inp.get("name")] = inp.get("value", "")

                    payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")
                    payload["post"] = "yes"
                    payload["force_delete"] = "true"

                    action = target_form.get("action")
                    post_url = urljoin(delete_url, action) if action else delete_url
                    session.post(post_url, data=payload, headers={"Referer": delete_url}, allow_redirects=False)
                else:
                    print("   ❌ No se encontró formulario en la página de confirmación de Delete.")
                    return "error", details_tuple, session

            # Si el Delete es un submit en la misma página (raro, pero cubierto)
            elif action_btn.name in ["input", "button"]:
                form_id = action_btn.get("form")
                target_form = det_soup.find("form", id=form_id) if form_id else action_btn.find_parent("form")

                if target_form:
                    payload = {}
                    for inp in target_form.find_all("input"):
                        if inp.get("name"):
                            payload[inp.get("name")] = inp.get("value", "")

                    payload["csrfmiddlewaretoken"] = session.cookies.get("csrftoken", "")
                    payload["post"] = "yes"
                    payload["force_delete"] = "true"

                    action = target_form.get("action")
                    post_url = urljoin(details_url, action) if action else details_url
                    session.post(post_url, data=payload, headers={"Referer": details_url}, allow_redirects=False)
        else:
            print(f"   ⚠️ El botón de acción tiene un estado desconocido: {btn_val}")
            return "error", details_tuple, session

        # --- PASO 3: PRUEBA DE VIDA ---
        time.sleep(1)
        verify_resp = session.get(details_url)
        if verify_resp.status_code == 404 or device_id not in verify_resp.url:
            print("   ✅ ¡Eliminado exitosamente! (Confirmado en servidor)")
            return "deleted", details_tuple, session
        else:
            print("   ❌ Falló la eliminación. El equipo sigue existiendo.")
            return "error", details_tuple, session

    except Exception as e:
        print(f"   ❌ Error interno procesando {mac}: {e}")
        return "error", None, session


# =========================
# MAIN
# =========================
def main():
    print("=" * 60)
    print(" INICIANDO AUTO-DELETE (OBEDECIENDO AL BOTÓN DELETELINK)")
    print("=" * 60)

    macs, _ = read_and_clean_macs()
    if not macs: return

    session = login_session()
    if not session:
        print("❌ No se pudo establecer la conexión inicial. Abortando.")
        return

    updated_lines = []

    for idx, mac in enumerate(macs, 1):
        print(f"\n🔍 Procesando {idx}/{len(macs)}: {mac}")

        result, details, session = process_mac(session, mac)

        if result == "not_found":
            updated_lines.append(f"{mac} | MAC NO ENCONTRADA")
        elif result == "mismatch":
            print("   ⚠️ MAC NO COINCIDE")
            updated_lines.append(f"{mac} | MAC NO COINCIDE")
        elif result == "session_error":
            updated_lines.append(f"{mac} | ERROR DE SESIÓN (EXPULSADO)")
        elif result == "error":
            updated_lines.append(f"{mac} | ERROR EN PROCESO")
        elif result == "deleted":
            os_val, created_val, modified_val = details if details else ("N/A", "N/A", "N/A")
            updated_lines.append(f"{mac} | ELIMINADO | OS={os_val} | Created={created_val} | Modified={modified_val}")

    try:
        with open(MAC_FILE_PATH, 'w', encoding='utf-8') as file:
            for line in updated_lines:
                file.write(line + "\n")

            file.write("\n\n")

            for mac in macs:
                file.write(mac + "\n")
        print(f"\n💾 Resultados guardados en {MAC_FILE_PATH}")
    except Exception as e:
        print(f"❌ Error guardando el archivo: {e}")


if __name__ == "__main__":
    main()
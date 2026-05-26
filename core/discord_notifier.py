import os
import urllib.request
import json
from datetime import datetime

class DiscordNotifier:
    EQUIPO_MAPEO = {
        "MPC-1OCAK8IK9CP": "Rey",
        "DESKTOP-PT8UMBI": "Cuervonv",
        "ALVARO": "Alvaro",
        "DESKTOP-4D3P5N2": "Esteban",
        "MPC-17KT4458H7R": "Kevin",
        "DESKTOP-7D3G6V0": "Felipe",
        "DESKTOP-R1IDN86": "Paula Andrea",
        "MPC-71225UVI7HG": "Bryan",
        "USUARIO-IO29QUF": "FlechasJuan",
        "DESKTOP-5FNCEON": "Yeison",
        "WINDOWS-OBOHUKI": "Santiago",
        "MPC-A5584AEIOOK": "Oscar",
        "MPC-175K2LHCBFV": "Juan Marin",
        "DESKTOP-A-VALLE": "Jhon Vallejo"
    }

    def __init__(self, ingreso_url=None, produccion_url=None, error_url=None):
        self.ingreso_url = ingreso_url or os.getenv("DISCORD_WEBHOOK_INGRESO", "")
        self.produccion_url = produccion_url or os.getenv("DISCORD_WEBHOOK_PRODUCCION", "")
        self.error_url = error_url or os.getenv("DISCORD_WEBHOOK_ERRORES", "")

    @staticmethod
    def get_alias():
        """Obtiene el nombre mapeado del equipo actual"""
        hostname = os.getenv('COMPUTERNAME', 'Desconocido').upper()
        return DiscordNotifier.EQUIPO_MAPEO.get(hostname, hostname)

    def _send(self, webhook_url, data):
        if not webhook_url:
            return
        try:
            req = urllib.request.Request(webhook_url, data=json.dumps(data).encode('utf-8'),
                                         headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                pass
        except Exception:
            pass

    def send_ingreso(self, script_name):
        """Notifica al canal de ingreso cuando alguien abre el script"""
        nombre_visual = self.get_alias()
        data = {
            "embeds": [{
                "title": "🟢 Ingreso al Script",
                "color": 5763719,  # Verde
                "fields": [
                    {"name": "📋 Script", "value": f"**{script_name}**", "inline": True},
                    {"name": "💻 Operador", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "⏰ Hora de ingreso", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        self._send(self.ingreso_url, data)

    def send_webhook(self, macs, meta, script_name, is_interrupted=False, is_reintegro=False):
        """Envía un resumen de las MACs flasheadas al canal de producción"""
        if not macs and not is_interrupted:
            return

        nombre_visual = self.get_alias()
        lista_macs = "\n".join([f"• `{mac}`" for mac in macs]) if macs else "Ninguna MAC procesada."
        
        # Color: Azul para reintegro, Verde normal. Amarillo si interrumpido.
        color = 3447003 if is_reintegro else 3066993
        if is_interrupted:
            color = 16766720  # Amarillo
            
        title = f"👻 Lote de {script_name} Flasheados"
        if is_interrupted:
            title = f"⚠️ Lote de {script_name} Detenido Manualmente"
            
        data = {
            "embeds": [{
                "title": title,
                "color": color,
                "fields": [
                    {"name": "🔢 Equipos Procesados", "value": f"**{len(macs)} / {meta}**" if meta else f"**{len(macs)}**", "inline": True},
                    {"name": "💻 Procesado por", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "📍 Direcciones MAC", "value": lista_macs, "inline": False},
                    {"name": "⏰ Fecha", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        self._send(self.produccion_url, data)

    def send_error(self, script_name, error_msg):
        """Envía un reporte de error crítico al canal de errores"""
        nombre_visual = self.get_alias()
        data = {
            "embeds": [{
                "title": "🚨 Error en Script",
                "color": 15158332,  # Rojo
                "fields": [
                    {"name": "📋 Script", "value": f"**{script_name}**", "inline": True},
                    {"name": "💻 Operador", "value": f"**{nombre_visual}**", "inline": True},
                    {"name": "❌ Detalle del Error", "value": f"```{error_msg}```", "inline": False},
                    {"name": "⏰ Fecha", "value": datetime.now().strftime('%d/%m/%Y %H:%M:%S'), "inline": False}
                ],
                "footer": {"text": "Sistema de Automatización - Soluciones Cuervo"}
            }]
        }
        self._send(self.error_url, data)

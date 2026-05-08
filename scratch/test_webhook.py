import os
import json
import urllib.request
from pathlib import Path
from dotenv import load_dotenv

# Replicar lógica de carga
BASE_DIR = Path(__file__).parent.parent.absolute()
load_dotenv(BASE_DIR / ".env")

WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK_URL")
print(f"WEBHOOK_URL: {WEBHOOK_URL}")

def test_webhook():
    if not WEBHOOK_URL:
        print("Error: WEBHOOK_URL no encontrada en .env")
        return

    data = {
        "embeds": [{
            "title": "🧪 TEST Webhook Python",
            "description": "Si ves esto, la configuración de Python es correcta.",
            "color": 16711680 # Rojo
        }]
    }
    
    try:
        req = urllib.request.Request(WEBHOOK_URL, data=json.dumps(data).encode('utf-8'), 
                                   headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            print(f"Respuesta Discord: {response.getcode()}")
    except Exception as e:
        print(f"Error enviando webhook: {e}")

if __name__ == "__main__":
    test_webhook()

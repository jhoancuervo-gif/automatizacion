# Sistema de Automatización de Redes - Proyecto Cuervo 🦅

Este ecosistema de scripts está diseñado exclusivamente para el **área de preconfiguración**. Su objetivo es estandarizar y agilizar el despliegue de configuraciones, actualizaciones de firmware y gestión remota de dispositivos de red.

## 📂 Arquitectura de Módulos

El sistema se divide en tres núcleos principales de automatización:

### 1. Módulo POE (Power Over Ethernet)
Este módulo gestiona la **actualización de software** y el **provisionamiento** de dispositivos POE.
*   **Flasheo de Configuración**: Carga un archivo binario (\.bin\) que establece reglas de **filtrado DHCP**.
*   **Gestión de Puertos**: Libera el puerto 1 o el puerto 8 según el modelo.
*   **Port Forwarding (Redireccionamiento)**:
    *   Para configuraciones en **puerto 8**: Se realiza un taggeo masivo de puertos (del 1.8 al 7.8).
    *   Para configuraciones en **puerto 1**: Todos los puertos se taggean con la etiqueta 1.

### 2. Módulo Phantom
Automatiza la integración de dispositivos a la infraestructura de monitoreo central.
*   **Acceso**: Conexión mediante la **IP de gestión** del equipo.
*   **Despliegue**: Sube una imagen \Firmware.bin\ personalizada.
*   **Gestión Remota**: Vincula el equipo automáticamente con la plataforma **OpenWisp** para administración en la nube.

### 3. Módulo Orb
Módulo hermano de Phantom que utiliza una lógica de despliegue idéntica.
*   **Diferenciador**: Aplica variaciones específicas en las líneas de código del archivo binario para adaptarse a modelos de hardware distintos.

---

## 🛠️ Requisitos Técnicos

Para garantizar el funcionamiento de los scripts, la estación de trabajo debe cumplir con:

1.  **Python 3.13**: Lenguaje base para la lógica de automatización.
2.  **Librerías de Python**:
    *   \
equests\ & \eautifulsoup4\: Para interacción con interfaces web (Web Scraping).
    *   \ syncssh\: Para ejecución de comandos remotos de forma asíncrona.
    *   \python-dotenv\: Gestión de variables de entorno y credenciales seguras.
3.  **CURL**: Herramienta de línea de comandos vital para el flasheo de dispositivos POE.
4.  **PowerShell**: Se requiere que la política de ejecución sea \RemoteSigned\. **Se recomienda ejecutar como Administrador** para evitar bloqueos de red.

---

## 🚀 Guía de Uso Paso a Paso

### Paso 1: Sincronización Inicial (Solo la primera vez)
Si eres nuevo, solicita acceso al repositorio en GitHub y clona el proyecto en tu escritorio:
\\\powershell
git clone https://github.com/reinelvillegas-design/automatizacion.git
\\\

### Paso 2: Preparación del Entorno
Dentro de la carpeta, ejecuta el script de configuración. Este instalará todas las dependencias:
*   Archivo: \instalar_dependencias.ps1\

### Paso 3: Ejecución del Sistema
**Utiliza siempre el lanzador oficial**:
*   Archivo: \menu_principal.bat\

> **Nota**: Al abrirlo, el sistema realiza automáticamente un \git pull\ para descargar las últimas mejoras de la nube antes de mostrar el menú.

---

## ☁️ Gestión de Cambios (Para Desarrolladores)

Si realizas una mejora en el código, utiliza el script de subida:
*   Archivo: \subir_cambios.bat\
*   **Proceso**: Ejecuta el archivo, escribe un comentario sobre lo que cambiaste y presiona Enter.

---
**Desarrollado por REINEL VILLEGAS - JHOAN ESTEBAN CUERVO OSORIO - JOHN VALLEJO**
*Área de Preconfiguración - Proyecto Cuervo.*

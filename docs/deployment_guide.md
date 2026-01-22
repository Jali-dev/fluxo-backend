# Guía de Despliegue: Render (Producción)

## 🚀 Checklist DevOps Senior

Configuración verificada para producción en Render (Plan Free/Starter).

| Parámetro | Valor Configurado | Razón Técnica |
| :--- | :--- | :--- |
| **Type** | Web Service | Expone un puerto HTTP público. |
| **Runtime** | Docker | Mayor control sobre librerías del sistema (`ffmpeg`). |
| **Context** | `backend/` | El código fuente no está en la raíz. |
| **Environment** | `PORT=10000` | Render inyecta este puerto, Gunicorn debe escucharlo. |
| **Start Command** | *Automático* | Usamos `CMD` en Dockerfile. NO sobrescribir en Render. |
| **Health Check** | `/` (200 OK) | Render revisa que la app responda antes de enrutar tráfico. |

## ⚠️ Errores Comunes y Soluciones

### 1. "Build Failed: Dockerfile not found"

* **Causa**: Render busca en la raíz (`/`) pero el archivo está en `backend/Dockerfile`.
* **Solución**: Asegúrate de que `dockerContext` en `render.yaml` apunte a `backend` o configúralo manualmente en Settings -> Build & Deploy -> Build Context.

### 2. "Deploy Failed: Timed out waiting for port"

* **Causa**: La aplicación arrancó pero no escuchó en el puerto `$PORT`.
* **Verificación**: Revisa los logs. Debe decir `Listening at: http://0.0.0.0:10000`.
* **Solución**: Verifica que tu Dockerfile tenga `ENV PORT=10000` y el comando `gunicorn --bind 0.0.0.0:$PORT`.

### 3. "Application Error" (502 Bad Gateway)

* **Causa**: La app crasheó al recibir la petición o tardó demasiado.
* **Solución en Free Tier**: Aumentamos el timeout de Gunicorn a 120s (`--timeout 120`) para dar tiempo a `yt-dlp` de procesar videos pesados sin cortar la conexión.

### 4. "OOM Killed" (Out Of Memory)

* **Causa**: El contenedor consumió más de 512MB RAM.
* **Solución**: Usamos `workers=1` y `threads=8` en Gunicorn. Esto limita el consumo de RAM (un solo proceso Python) pero permite concurrencia vía hilos.

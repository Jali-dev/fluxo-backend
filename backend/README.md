# Fluxo Backend API (Flask)

Servicio de extracción de video optimizado para Facebook usando `yt-dlp`.

## Stack
- **Python 3.11**
- **Flask**: Servidor HTTP ligero.
- **yt-dlp**: Motor de extracción.
- **Gunicorn**: Servidor de producción WSGI.
- **Docker**: Contenedorización.

## Endpoints

### `POST /extract`
Procesa una URL de Facebook y devuelve el enlace directo al stream.

**Request:**
```json
{
  "url": "https://fb.watch/example..."
}
```

**Response (200 OK):**
```json
{
  "title": "Video Title",
  "thumbnail": "https://...",
  "direct_url": "https://...mp4?token=...",
  "type": "recorded",  // "recorded" (.mp4) o "live" (.m3u8)
  "duration": 120
}
```

## Despliegue (Railway/Render/Cloud Run)
1. Subir carpeta `backend/` a un repositorio.
2. Desplegar (El `Dockerfile` expone el puerto `$PORT`).

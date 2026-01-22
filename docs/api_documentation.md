# Fluxo Backend API Documentation

## Overview

Servicio REST minimalista para la extracción de metadatos y URLs directas de videos (específicamente Facebook/Meta) utilizando `yt-dlp`.

- **Base URL (Producción)**: `https://fluxo-backend-rsqy.onrender.com`
- **Protocol**: HTTPS
- **Format**: JSON

---

## Endpoints

### 1. Health Check

Verifica que el servicio esté activo y respondiendo.

- **GET** `/`
- **Response 200 OK**:

  ```json
  {
    "status": "ok",
    "service": "Fluxo Extractor (Flask)"
  }
  ```

---

### 2. Extract Video

Extrae la URL reproducible (`.mp4` o `.m3u8`) de un enlace compartido.

- **POST** `/extract`
- **Content-Type**: `application/json`
- **Timeout**:
  - Gunicorn limit: 120s
  - Internal processing limit: 45s (Error 504 si excede)

#### Request Body

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `url` | string | **Yes** | URL completa del video (ej. `https://fb.watch/xyz` o `https://www.facebook.com/watch/?v=...`) |

**Example Request:**

```json
{
  "url": "https://fb.watch/123456789"
}
```

#### Response (Success - 200 OK)

| Field | Type | Description |
| :--- | :--- | :--- |
| `title` | string | Título del video o "Unknown Title". |
| `thumbnail` | string | URL de la imagen en miniatura (jpg/webp). |
| `direct_url` | string | URL directa al stream (`.mp4` o `.m3u8`). Caduca con el tiempo. |
| `type` | string | `live` (si es stream HLS) o `recorded` (si es archivo estático). |
| `duration` | float/null | Duración en segundos (null si es stream en vivo). |

**Example Response:**

```json
{
  "title": "Amazing Video",
  "thumbnail": "https://cdn.facebook.com/thumbs/123.jpg",
  "direct_url": "https://video.xx.fbcdn.net/v/t42...mp4?token=...",
  "type": "recorded",
  "duration": 542
}
```

#### Error Responses

| Status Code | Error Code | Description |
| :--- | :--- | :--- |
| **400 Bad Request** | `Missing 'url' field` | El JSON no contiene la key `url`. |
| **400 Bad Request** | `Could not extract video info` | `yt-dlp` falló (video privado, borrado o geo-bloqueado). |
| **422 Unprocessable** | `No processing URL found` | Se procesó la metadata pero no se encontró un stream válido. |
| **504 Gateway Timeout** | `Extraction timed out` | El proceso excedió los 45 segundos internos. |
| **500 Server Error** | `Internal error` | Error inesperado en el servidor Python. |

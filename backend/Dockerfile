FROM python:3.11-slim

# Evita que Python genere archivos .pyc y fuerza logs en tiempo real
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=10000

# Instalar ffmpeg y dependencias básicas
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Crear usuario no-root por seguridad
RUN addgroup --system app && adduser --system --group app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Cambiar permisos al usuario app
RUN chown -R app:app /app

# Cambiar al usuario no-root
USER app

# Gunicorn Tunning para Render Plan Gratuito (512MB RAM)
# Workers=1 evita OOM (Out of Memory). Threads=8 maneja concurrencia I/O (yt-dlp).
# Timeout=120s para videos largos de Facebook.
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:${PORT} --workers 1 --threads 8 --timeout 120"]

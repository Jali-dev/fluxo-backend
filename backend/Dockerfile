FROM python:3.11-slim

# Install ffmpeg (required for yt-dlp / facebook streams)
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Port for Cloud Run / Render default
ENV PORT=8080

# Use Gunicorn as production server
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:${PORT} --workers 2 --threads 4 --timeout 60"]

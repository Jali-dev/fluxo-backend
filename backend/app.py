import os
import subprocess
import json
import logging
from flask import Flask, request, jsonify

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route("/", methods=["GET"])
def health_check():
    return jsonify({
        "status": "ok",
        "service": "Fluxo Extractor (Flask)"
    }), 200

@app.route("/extract", methods=["POST"])
def extract_video():
    """
    Extracts direct video URL using yt-dlp.
    Json Body: { "url": "https://fb.watch/..." }
    """
    try:
        data = request.get_json()
        if not data or "url" not in data:
            return jsonify({"error": "Missing 'url' field"}), 400

        target_url = data["url"]
        logger.info(f"Processing URL: {target_url}")

        # Command to get JSON metadata
        cmd = [
            "yt-dlp",
            "-J",              # Dump JSON
            "--no-warnings",   # Clean output
            target_url
        ]

        # Execute yt-dlp
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=45)

        if result.returncode != 0:
            logger.error(f"yt-dlp error: {result.stderr}")
            return jsonify({"error": "Could not extract video info", "details": result.stderr}), 400

        parsed_data = json.loads(result.stdout)

        # Extraction Logic
        video_title = parsed_data.get("title")
        thumbnail = parsed_data.get("thumbnail")
        duration = parsed_data.get("duration")
        
        # Determine best URL and Type (Live vs Recorded)
        direct_url = parsed_data.get("url")
        is_live = parsed_data.get("is_live", False)
        
        # If direct_url is m3u8, it's likely a Live stream or HLS
        if direct_url and ".m3u8" in direct_url:
            video_type = "live"
        elif direct_url and ".mp4" in direct_url:
            video_type = "recorded"
        else:
            # Fallback inspection of 'formats' if 'url' key is not sufficient or empty
            # Facebook sometimes returns multiple formats. We prefer mp4 for recorded.
            formats = parsed_data.get("formats", [])
            best_mp4 = None
            
            for f in formats:
                f_url = f.get("url", "")
                if ".m3u8" in f_url:
                    direct_url = f_url
                    video_type = "live"
                    is_live = True
                    break # Prefer m3u8 if available (adaptive streaming)
                
                if f.get("ext") == "mp4" and f.get("acodec") != "none":
                    # Keep updating best_mp4, usually last is best quality
                    best_mp4 = f_url
            
            if not direct_url and best_mp4:
                direct_url = best_mp4
                video_type = "recorded"
            elif not direct_url:
                 # Last resort
                 video_type = "unknown"

        if not direct_url:
            return jsonify({"error": "No processing URL found"}), 422

        response = {
            "title": video_title,
            "thumbnail": thumbnail,
            "direct_url": direct_url,
            "type": video_type, # 'live' (m3u8) or 'recorded' (mp4)
            "duration": duration
        }
        
        return jsonify(response), 200

    except subprocess.TimeoutExpired:
        logger.error("Timeout expired")
        return jsonify({"error": "Extraction timed out"}), 504
    except Exception as e:
        logger.error(f"Internal error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # Dev server
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))

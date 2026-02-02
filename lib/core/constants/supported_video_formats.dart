class SupportedVideoFormats {
  // MIME Types
  static const String mpegUrl = 'application/x-mpegURL';
  static const String appleMpegUrl = 'application/vnd.apple.mpegurl';
  static const String dashXml = 'application/dash+xml';
  static const String videoPrefix = 'video/';

  // Extensions (Fallback)
  static const List<String> extensions = [
    '.m3u8',
    '.mp4',
    '.mpd',
    '.webm',
    '.mkv',
    '.ts',
    '.mov'
  ];

  // Helper to check if content type is video
  static bool isVideoContentType(String? contentType) {
    if (contentType == null) return false;
    final lower = contentType.toLowerCase();
    return lower.startsWith(videoPrefix) ||
           lower == mpegUrl ||
           lower == appleMpegUrl ||
           lower == dashXml;
  }
}

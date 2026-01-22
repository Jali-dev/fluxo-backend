import 'package:flutter/services.dart';

class CastService {
  static const MethodChannel _channel = MethodChannel('com.fluxo.fluxo/cast');

  /// Inicializa el contexto de Cast.
  /// Debe llamarse al inicio de la app o en el `initState` del Home.
  Future<void> init() async {
    try {
      await _channel.invokeMethod('initCast');
    } on PlatformException catch (e) {
      print("Error initializing Cast: ${e.message}");
    }
  }

  /// Carga un video en el dispositivo Cast conectado.
  Future<void> loadMedia({
    required String url,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? contentType = 'video/mp4',
    bool isLive = false,
  }) async {
    try {
      await _channel.invokeMethod('loadMedia', {
        'url': url,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'contentType': contentType,
        'isLive': isLive,
      });
    } on PlatformException catch (e) {
      print("Error loading media: ${e.message}");
    }
  }

  /// Muestra el selector de rutas (Dialog) si es posible.
  /// Nota: La Integration nativa recomendada usa el botón oficial 'MediaRouteButton'.
  Future<void> showRouteSelector() async {
    try {
      await _channel.invokeMethod('showRouteSelector');
    } on PlatformException catch (e) {
      print("Error showing route selector: ${e.message}");
    }
  }

  /// Reanuda la reproducción.
  Future<void> play() async {
    try {
      await _channel.invokeMethod('play');
    } on PlatformException catch (e) {
      print("Error playing: ${e.message}");
    }
  }

  /// Pausa la reproducción.
  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause');
    } on PlatformException catch (e) {
      print("Error pausing: ${e.message}");
    }
  }

  /// Detiene la reproducción.
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print("Error stopping: ${e.message}");
    }
  }

  /// Busca una posición específica en milisegundos.
  Future<void> seekTo(int positionMs) async {
    try {
      await _channel.invokeMethod('seek', {'position': positionMs});
    } on PlatformException catch (e) {
      print("Error seeking: ${e.message}");
    }
  }

  /// Ajusta el volumen del dispositivo Cast (0.0 a 1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume});
    } on PlatformException catch (e) {
      print("Error setting volume: ${e.message}");
    }
  }
}

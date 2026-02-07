# Fluxo Player

Fluxo es una aplicación Android desarrollada en Flutter para transmitir videos de la web a dispositivos Google Cast (Chromecast, Google TV, etc.).

## ✨ Características Principales

* **Interfaz Moderna**: Diseño oscuro con gradientes coloridos y estética premium.
* **Entrada de Enlaces**: Pega una URL directamente en la pantalla principal y toca "REPRODUCIR" para abrir el navegador integrado.
* **Navegador Web Integrado (Web Caster)**: Permite navegar por sitios web de streaming con detección automática de videos.
* **Detector de Videos**: Detecta enlaces de video (m3u8, mp4, dash) usando "Monkey Patching" para interceptar solicitudes.
* **Soporte Google Cast**: Envía contenido detectado a TV compatible con Cast.

## 🚀 Cómo Usar

1. Abre la app **Fluxo Player**.
2. Pega un enlace de video en el campo "Pega tu enlace aquí...".
3. Toca el botón **REPRODUCIR** para abrir el navegador.
4. El navegador detectará automáticamente los videos en la página.
5. Selecciona un video y envíalo a tu TV con Cast.

## ⚠️ Problemas Conocidos

> La detección automática puede fallar en sitios con protección DRM o iframes muy complejos. Usa el botón "Escanear Manualmente" en el menú del navegador si es necesario.

## 📦 Instalación

1. Clonar el repositorio.
2. Ejecutar `flutter pub get`.
3. Compilar con `flutter build apk --release`.
4. El APK estará en `build/app/outputs/flutter-apk/app-release.apk`.

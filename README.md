# Fluxo App

Fluxo es una aplicación Android desarrollada en Flutter para transmitir videos de la web a dispositivos Google Cast (Chromecast, Google TV, etc.).

## Características Principales

* **Navegador Web Integrado**: Permite navegar por sitios web de streaming.
* **Detector de Videos (Web Caster)**: Intenta detectar enlaces de video (m3u8, mp4, dash) en la página actual.
* **Soporte Google Cast**: Envío de contenido detectado a TV.

## ⚠️ Estado Actual y Problemas Conocidos

> **IMPORTANTE:** La función de detección automática de enlaces de video ("Video Sniffer") **NO FUNCIONA CORRECTAMENTE** en este momento.

* La detección automática falla en la mayoría de los sitios modernos con protección o iframes complejos.
* El botón de "Escanear Manualmente" puede no devolver resultados fiables.
* Se está trabajando en una solución más robusta similar a "Web Video Caster", pero actualmente la funcionalidad es inestable o nula.

## Instalación

1. Clonar el repositorio.
2. Ejecutar `flutter pub get`.
3. Configurar credenciales de Android si es necesario.
4. Compilar con `flutter build apk --release`.

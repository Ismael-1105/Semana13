// ⚠️ CONFIGURACIÓN - CAMBIAR ANTES DE EJECUTAR

// URL del backend vulnerable. Dependiendo de dónde corre tu servidor y qué
// dispositivo use la app, el valor puede variar.
// En lugar de definir una constante fija, se calcula aquí dinámicamente; sin
// embargo, si ejecutas en un dispositivo físico debes adaptar la IP manualmente.
//
// Ejemplos de direcciones según el entorno:
//   • Flutter desktop / web: http://localhost:3000
//   • Android emulator (AVD): http://10.0.2.2:3000  (el "localhost" del emu
//     apunta al propio emulador, no a tu PC)
//   • Genymotion: http://10.0.3.2:3000
//   • Dispositivo físico: http://<IP-de-tu-PC>:3000
//   • Ngrok o similar: usa la URL pública generada, sin barra final.
//
// Si el backend no está accesible en la URL configurada, las peticiones fallan
// con "Connection refused", como se muestra al usar localhost desde un emulador.

import 'dart:io';

String get API_URL {
  // Detecta Android para usar el alias especial del emulador.
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  // por defecto localhost para desktop/web/iOS
  return 'http://localhost:3000';
}

// Puerto del servidor Node.js
const int PORT = 3000;

// Timeouts
const Duration REQUEST_TIMEOUT = Duration(seconds: 10);

// Flags de debug
const bool DEBUG_LOGS = true;
const bool SHOW_SENSITIVE_DATA = true;

# semana13 - Aplicación Flutter Vulnerable

Este repositorio contiene una aplicación Flutter diseñada para **propósitos
educativos de seguridad** junto a su backend Node.js vulnerable. Sirve como
ejemplo práctico de malas prácticas y vectores de ataque.

---

## 1. Frontend (semana13/lib/main.dart)
La aplicación móvil ofrece:

- **Pantalla de login/registro** sin validación sólida.
- **Dashboard que consume el backend** con botones que activan peticiones HTTP:
  - `/users`: lista todos los usuarios del servidor (revele contraseñas en texto
    claro).
  - `/data`: expone información sensible y estadísticas.
  - `/admin`: muestra un secreto administrativo.
  - `/info`: datos de la versión y uptime del servidor.
  - `/contacts`: lee la libreta de direcciones (requiere permisos), guarda los
    contactos en:
      * Base de datos SQLite local (`app.db`).
      * Almacenamiento seguro (`flutter_secure_storage`).
      * Backend a través de POST.
  - Botones adicionales permiten leer contactos guardados localmente o en el
    servidor.
- Datos sensibles se muestran sin restricciones y se guardan sin cifrado.
- Varias funciones ilustran vulnerabilidades móviles: almacenamiento inadecuado,
  permisos, exfiltración de datos y manejo inseguro de contextos.

La URL del backend y las opciones de depuración se configuran en
`lib/config.dart`.

La intención es emplear esta app para demostrar ataques de cliente y la
importancia de validar/filtrar datos antes de enviarlos al servidor.

---

## 2. Backend (vulnerable-backend)

El servidor es un simple proyecto Node.js + Express cuyo README incluye más
detalles; aquí un resumen:

- MongoDB sin autenticación, esquema de usuarios con contraseñas en texto
  plano.
- Endpoints inseguros:
  - `/register` y `/login` sin hash ni tokens reales.
  - `/users`, `/admin`, `/data`, `/info` accesibles por cualquiera.
  - `/contacts`: guarda contactos recibidos sin validación.
  - WebSocket abierto con eventos sin autorización.
- CORS abierto (`*`), sin rate limiting ni helmet.
- Modelo `Contact` para almacenar datos de la libreta de direcciones.

Un script de verificación (`verifyContacts.js`) ayuda a comprobar que la app
Flutter puede enviar contactos correctamente.

---

## 3. Uso para Presentación

1. Inicia el backend (`npm start` en `vulnerable-backend`).
2. Lanzar la app Flutter (`flutter run` desde la carpeta `semana13`).
3. Interactúa con los botones del dashboard y observa los logs / respuestas.
4. Ejecuta `verifyContacts.js` para demostrar la exfiltración de contactos.

Puedes alternar las banderas de `DEBUG_LOGS`/`SHOW_SENSITIVE_DATA` en
`config.dart` para controlar la verbosidad y revelación de información.

Este conjunto sirve como base para hablar sobre:

- Errores comunes en apps móviles y APIs.
- Importancia del cifrado, validación y control de acceso.
- Cómo un atacante puede explotar estas debilidades.

**¡Asegúrate de aclarar que todo esto es intencionadamente inseguro!**

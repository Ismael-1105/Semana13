# 🔥 Laboratorio de Seguridad: App Móvil Vulnerable y Backend Inseguro

## 🎯 Objetivo

Simular un ataque realista a una aplicación móvil vulnerable con backend expuesto. Este es un entorno educativo completamente intencional para aprender sobre vulnerabilidades de seguridad.

**⚠️ ADVERTENCIA**: Este código está DELIBERADAMENTE mal configurado. Nunca uses estas prácticas en producción.

---

## 🖥️ Arquitectura del Laboratorio

```
┌─────────────────────────────────────────────────────────────────┐
│                      ATACANTE (Kali Linux VM)                   │
│  - Metasploit  - Burp Suite  - Wireshark  - Herramientas APK   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓ (HTTP sin cifrado)
┌──────────────────────────────────────────────────────────────────┐
│            APP FLUTTER VULNERABLE (Android Emulator)             │
│  - HTTP sin HTTPS       - Credenciales en texto plano            │
│  - Sin certificate pin  - Logs sensibles                         │
│  - API URL hardcodeada  - WebSocket inseguro                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ↓ (MongoDB sin autenticación)
┌──────────────────────────────────────────────────────────────────┐
│        BACKEND NODE.JS + EXPRESS (VPS / Ngrok)                  │
│  - Sin autenticación    - Passwords en texto plano              │
│  - CORS abierto         - Sin rate limiting                      │
│  - WebSocket abierto    - Endpoints expuestos                    │
└──────────────────────────────────────────────────────────────────┘
                           │
                           ↓
┌──────────────────────────────────────────────────────────────────┐
│      BASE DE DATOS MONGODB (Sin cifrado)                        │
│  - Usuarios con passwords en texto plano                        │
│  - Credenciales administrativas accesibles                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
Parcial 3/
├── semana13/                    # App Flutter
│   ├── pubspec.yaml            # Dependencias (http, shared_preferences)
│   └── lib/
│       └── main.dart           # App vulnerable
│
└── vulnerable-backend/          # Backend Node.js
    ├── package.json            # Dependencias
    ├── .env                    # Configuración (INSEGURA)
    └── server.js               # Servidor vulnerable
```

---

## 🔧 Configuración Inicial

### 1️⃣ Backend Node.js

#### Instalación de dependencias:
```bash
cd vulnerable-backend
npm install
```

#### Variables de entorno (.env):
```
PORT=3000
MONGO_URI=mongodb://localhost:27017/vulnerableDB
JWT_SECRET=123456
```

#### Iniciar servidor:
```bash
npm start
# El servidor escucha en http://localhost:3000
```

#### Endpoints disponibles:
- `POST /register` - Crear usuario (sin hash)
- `POST /login` - Login inseguro (retorna token falso)
- `GET /users` - Listar todos los usuarios SIN autenticación
- `GET /admin` - Datos administrativos SIN protección
- `GET /data` - Información sensible expuesta
- `GET /info` - Información del servidor
- WebSocket en `/` - Conexión persistente abierta

### 2️⃣ Configurar MongoDB local

El backend espera una base de datos MongoDB en `localhost:27017`:

```bash
# En Windows, si tienes MongoDB Community Edition instalado:
mongod --dbpath "C:\Program Files\MongoDB\Server\6.0\data"

# O en WSL/Linux:
sudo service mongodb start
```

### 3️⃣ App Flutter

#### Instalar dependencias:
```bash
cd semana13
flutter pub get
```

#### Actualizar IP del servidor:
En [lib/main.dart](semana13/lib/main.dart), cambiar:
```dart
final String apiUrl = "http://192.168.1.100:3000"; // Tu IP local
```

#### Ejecutar la app:
```bash
flutter run
```

---

## 🚨 Vulnerabilidades Implementadas

### Backend (Node.js)

| Vulnerabilidad | Ubicación | Impacto |
|---|---|---|
| **CORS abierto** | server.js:L6 | Cualquier origin puede hacer requests |
| **Sin autenticación** | server.js:L27 | Endpoints accesibles sin token |
| **Passwords en texto plano** | server.js:L37 | Credenciales grabadas sin hash |
| **Token falso** | server.js:L57 | Validación de token inexistente |
| **MongoDB sin auth** | server.js:L14 | Base de datos expuesta |
| **WebSocket abierto** | server.js:L75 | Conexión persistente sin validación |
| **Sin validación de input** | Todo | SQL Injection, NoSQL Injection posible |
| **Información sensible expuesta** | server.js:L96 | /info revela versiones y uptime |

### App Flutter

| Vulnerabilidad | Ubicación | Impacto |
|---|---|---|
| **HTTP sin HTTPS** | main.dart:L33 | Tráfico interceptable |
| **Credenciales en SharedPreferences** | main.dart:L72 | Almacenamiento sin encripción |
| **Contraseña en texto plano** | main.dart:L72 | Credenciales visibles en memoria |
| **Logs sensibles** | main.dart:L56 | Tokens expuestos en console |
| **URL hardcodeada** | main.dart:L33 | Fácil ingeniería inversa del APK |
| **Sin certificate pinning** | Toda la app | Vulnerable a MITM |
| **Datos sensibles en logs** | main.dart:L212 | Contraseñas listadas en UI |

---

## 🎯 Ataques Demostrables

### 1️⃣ Interceptación de credenciales (Burp Suite)

1. Instalar Burp Suite en Kali
2. Configurar proxy en Android: `Settings > Network > Proxy = 192.168.1.100:8080`
3. Instalar certificado de Burp en Android
4. Ejecutar la app y hacer login
5. Ver credenciales en PLAINTEXT en Burp

### 2️⃣ Enumeración de endpoints directa

```bash
# Desde la máquina atacante:
curl http://192.168.1.100:3000/users
curl http://192.168.1.100:3000/admin
curl http://192.168.1.100:3000/data
curl http://192.168.1.100:3000/info
```

Todos los endpoints responden SIN autenticación.

### 3️⃣ Extracción de contraseñas

```bash
curl http://192.168.1.100:3000/users | jq '.[].password'
```

Obtendrás todas las contraseñas de los usuarios en texto plano.

### 4️⃣ Ingeniería inversa del APK

```bash
# Extraer APK del emulador
adb pull /data/app/com.example.semana13-*/base.apk ./app.apk

# Decompilarlo con apktool
apktool d app.apk

# Buscar credenciales hardcodeadas
grep -r "192.168.1.100" app/

# Buscar strings sensibles
strings app.apk | grep -i "password\|token\|secret"
```

### 5️⃣ Ataque MITM con Wireshark

1. Abrir Wireshark en Kali
2. Sniffear tráfico de la red
3. Filtrar: `http.request`
4. Ver todas las peticiones HTTP en plaintext:
   - Credenciales de login
   - Tokens
   - IDs de usuario
   - Direcciones email

### 6️⃣ WebSocket Hijacking

```python
# Script Python para conectarse al WebSocket
import socketio

sio = socketio.Client()

@sio.on('connect')
def on_connect():
    print('Conectado al servidor')
    sio.emit('pingServer')

@sio.on('pongServer')
def on_message(data):
    print('Respuesta:', data)
    
@sio.on('userData')
def on_user_data(data):
    print('Datos del usuario:', data)

sio.connect('http://192.168.1.100:3000')
sio.emit('getUserData', '647f8c9d9c7a4b1a2c3d4e5f')
sio.wait()
```

---

## 🔍 Herramientas Recomendadas

### En Kali Linux:
- **Burp Suite Community** - Interceptar tráfico HTTP/HTTPS
- **Metasploit** - Framework de explotación
- **Wireshark** - Análisis de tráfico de red
- **apktool** - Decompilación de APK
- **Frida** - Dynamic instrumentation
- **OWASP ZAP** - Scanning de vulnerabilidades

### Comandos útiles:
```bash
# Monitorear puerto 3000
netstat -tlnp | grep 3000

# Enviar petición POST
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{"email":"attacker@test.com","password":"123","role":"admin"}'

# Crear usuario admin
curl -X POST http://localhost:3000/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"123456","role":"admin"}'
```

---

## 📊 Matriz de Vulnerabilidades

| Vulnerabilidad | CVSS | CWE | Tipo | Severity |
|---|---|---|---|---|
| Credenciales en texto plano | 7.5 | CWE-256 | Authentication | HIGH |
| HTTP sin HTTPS | 7.4 | CWE-295 | Transport | HIGH |
| CORS abierto | 6.5 | CWE-346 | Cross-Origin | MEDIUM |
| Sin autenticación | 9.1 | CWE-287 | AuthN | CRITICAL |
| Passwords sin hash | 8.6 | CWE-256 | Crypto | HIGH |
| SQL/NoSQL Injection | 8.6 | CWE-89 | Injection | HIGH |
| Información sensible expuesta | 5.3 | CWE-200 | Information | MEDIUM |

---

## 🛡️ Remediaciones (Cómo arreglarlo)

### Backend:
```javascript
// 1. Usar variables de entorno
require('dotenv').config();

// 2. Incluir helmet para seguridad
const helmet = require('helmet');
app.use(helmet());

// 3. Restrictar CORS
app.use(cors({
  origin: ['https://tu-dominio.com'],
  credentials: true
}));

// 4. Usar bcrypt para passwords
const bcrypt = require('bcrypt');
const hashed = await bcrypt.hash(password, 10);

// 5. Implementar JWT real
const jwt = require('jsonwebtoken');
const token = jwt.sign({userId: user._id}, process.env.JWT_SECRET);

// 6. Authenticar endpoints
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({error: 'No token'});
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch {
    res.status(403).json({error: 'Invalid token'});
  }
};
app.get('/users', authMiddleware, /* ... */);
```

### App Flutter:
```dart
// 1. Usar HTTPS
final String apiUrl = "https://tu-servidor.com:3000";

// 2. Encriptar almacenamiento local
final encrypted = await FlutterSecureStorage().write(
  key: 'token',
  value: token
);

// 3. Certificate pinning
final client = http.Client();
final badCertificateCallback = ...;

// 4. Enviar token en headers
await http.get(
  Uri.parse("$apiUrl/users"),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json'
  }
);

// 5. Sin logs sensibles
// print(response.body); // ❌ NO HACER
```

---

## 📝 Notas Importantes

1. **Solo para propósitos educativos**: Este laboratorio está diseñado para entender vulnerabilidades reales.
2. **No usar en producción**: Nunca implementes estas prácticas en aplicaciones reales.
3. **Ambiente aislado**: Ejecuta esto en una red aislada, NO en internet público.
4. **Responsabilidad legal**: El hacking no autorizado es ilegal. Este lab es solo con consentimiento.
5. **Dificultades esperadas**: 
   - La app necesita una dirección IP válida del backend
   - MongoDB debe estar corriendo localmente
   - Los puertos deben estar disponibles (3000 para Node.js, 27017 para MongoDB)

---

## 🚀 Próximos Pasos

1. **Ejecutar los ataques** en el ambiente controlado
2. **Documentar hallazgos** en un reporte de pentesting
3. **Proponer remediaciones** basadas en OWASP Top 10
4. **Implementar contramedidas** en código secure
5. **Validar fixes** con las mismas herramientas de ataque

---

## 📚 Referencias

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [CVSS Calculator](https://www.first.org/cvss/calculator/3.1)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)

---

**⚠️ Recuerda**: Nuestro objetivo es APRENDER, no causar daño. Usa esta información responsablemente.

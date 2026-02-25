# 🔴 Backend Vulnerable - Node.js + Express

Este backend está **INTENCIONALMENTE** configurado con vulnerabilidades de seguridad para propósitos educativos.

⚠️ **NUNCA usar este código en producción**

---

## 📋 Vulnerabilidades Incluidas

- ❌ CORS completamente abierto (`"*"`)
- ❌ Sin autenticación en endpoints
- ❌ Passwords en texto plano (sin hash)
- ❌ Tokens JWT falsos sin verificación
- ❌ MongoDB sin credenciales
- ❌ WebSocket inseguro
- ❌ Sin rate limiting
- ❌ Sin validación de inputs
- ❌ Información sensible expuesta

---

## 🚀 Instalación Rápida

### Windows
```powershell
cd vulnerable-backend
npm install
npm start
```

### Linux/Mac
```bash
cd vulnerable-backend
npm install
npm start
```

---

## 📡 Endpoints Disponibles

### Autenticación (INSEGURA)
```
POST /register
Body: {
  "email": "user@example.com",
  "password": "123456",
  "role": "user"
}
Response: { "message": "Usuario creado", "user": {...} }
```

```
POST /login
Body: {
  "email": "user@example.com",
  "password": "123456"
}
Response: { "message": "Login exitoso", "token": "fake-jwt-token", "user": {...} }
```

### Datos (SIN AUTENTICACIÓN)
```
GET /users
Response: [{"_id": "...", "email": "...", "password": "...", "role": "..."}]
```

```
GET /admin
Response: { "secret": "Datos administrativos sensibles" }
```

```
GET /data
Response: { "totalUsers": 5, "users": [...], "databaseInfo": "..." }
```

```
GET /info
Response: { "serverVersion": "1.0.0", "mongoVersion": "Latest", "uptime": ... }
```

### WebSocket
```javascript
// Conexión: ws://localhost:3000
socket.emit('pingServer');
socket.on('pongServer', (data) => console.log(data));

socket.emit('getUserData', userId);
socket.on('userData', (user) => console.log(user));
```

---

## 🧪 Ejemplos de Ataques

### 1. Enumerar usuarios
```powershell
curl http://localhost:3000/users
```

### 2. Crear usuario
```powershell
curl -X POST http://localhost:3000/register `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"attacker@test.com\",\"password\":\"123\",\"role\":\"admin\"}'
```

### 3. Extraer contraseñas
```bash
curl http://localhost:3000/users | jq '.[].password'
```

### 4. Acceder a admin sin autenticación
```powershell
curl http://localhost:3000/admin
```

---

## 📊 Estructura del Servidor

```javascript
// server.js estructura:
- Configuración Express y CORS abierto
- Conexión MongoDB sin credenciales
- Schema de usuario (sin hash)
  - email: String
  - password: String (texto plano ❌)
  - role: String
- Endpoints públicos
- WebSocket inseguro
```

---

## 🔧 Configuración

Edita `.env`:
```
PORT=3000
MONGO_URI=mongodb://localhost:27017/vulnerableDB
JWT_SECRET=123456
```

---

## 📝 Logs

El servidor imprime:
- Conexiones nuevas
- Solicitudes recibidas
- Errores de base de datos

Úsalo para entender el flujo de ataques.

---

## 🛡️ Cómo Arreglarlo

Para una guía completa sobre remediaciones, lee [LABORATORIO_README.md](../LABORATORIO_README.md).

**Cambios esenciales:**
1. Implementar JWT real con verificación
2. Hashear passwords con bcrypt
3. Restrictar CORS
4. Validar inputs
5. Agregar autenticación a endpoints
6. Usar HTTPS
7. Secure MongoDB con credenciales

---

## 🎯 Próximos Pasos

1. ✅ Ejecuta el backend: `npm start`
2. 🔍 Enumerates endpoints con curl
3. 📱 Conecta la app Flutter
4. 🎭 Ejecuta ataques
5. 📋 Documenta hallazgos

---

## 🧩 Script de verificación de contactos

Se ha incluido un pequeño script en la carpeta raíz (`verifyContacts.js`) que
permite comprobar rápidamente si el endpoint `/contacts` está recibiendo y
almacenando datos correctamente. Usa Node.js para ejecutarlo:

```bash
cd vulnerable-backend
npm install axios   # sólo la primera vez si no está instalado
node verifyContacts.js
```

El script realiza un `POST` con un contacto de prueba y luego un `GET` para
recuperar todos los contactos. Si el elemento de prueba aparece en la lista,
significa que la aplicación Flutter está pudiendo enviarlos al servidor.

También se puede activar la limpieza automática descomentando la línea
`api.delete('/contacts')` dentro del script.

Puedes adaptar el script (o convertirlo en un script de PowerShell/curl) según
necesites.

---

**Recuerda: Usa este conocimiento responsablemente.**

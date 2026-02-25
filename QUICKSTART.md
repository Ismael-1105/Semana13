# ⚡ GUÍA RÁPIDA - Inicio en 5 minutos

## 🖥️ Requisitos previos:
- **Node.js v16+** instalado
- **MongoDB Community** (opcional, para bd persistente)
- **Flutter SDK** instalado y bien configurado
- **Android Emulator** o dispositivo físico con Android Developer Options habilitado

---

## 🔴 PASO 1: Iniciar Backend Node.js

### Opción A: Windows (Fácil)
```powershell
# Navega a la carpeta del backend
cd vulnerable-backend

# Ejecuta el script (instala dependencias y inicia servidor)
.\start.bat
```

### Opción B: Terminal Manual
```powershell
cd vulnerable-backend
npm install
npm start
```

**✅ Deberías ver:**
```
Servidor vulnerable corriendo en puerto 3000
```

---

## ✅ PASO 2: Verificar Backend

Ejecuta el script de prueba en **otra terminal**:
```powershell
# En la raíz del proyecto
.\test_endpoints.bat
```

Deberías obtener respuestas JSON sin errores. Si falla:
- Verifica que el servidor todavía está corriendo
- Revisa que el puerto 3000 esté disponible: `netstat -ano | findstr 3000`

---

## 🔵 PASO 3: Configurar App Flutter

### Paso 1: Obtén tu IP local
```powershell
ipconfig | findstr "IPv4"
```
Busca algo como: `192.168.1.100` o `10.0.0.x`

### Paso 2: Actualiza la configuración
🔴 **IMPORTANTE:** Debes actualizar la URL en uno de estos dos lugares:

**Opción A: Rápido (Recomendado)**
- Abre: `semana13/lib/main.dart`
- Línea 6: Cambia `const String API_URL = "http://localhost:3000";`
- Usa la IP que obtuviste si quieres acceder desde otro dispositivo
- Guarda el archivo

**Opción B: Usa config.dart**
- Abre: `semana13/lib/config.dart`
- Modifica `const API_URL = ...`
- Importa en main.dart: `import 'config.dart';` y usa `API_URL`

### Paso 3: Instala dependencias
```powershell
cd semana13
flutter pub get
```

---

## 🟢 PASO 4: Ejecutar la App

```powershell
# En la carpeta semana13
flutter run

# Si tienes múltiples dispositivos, selecciona uno cuando se pida
```

**Espera a que aparezca la app en el emulator/dispositivo**

---

## 🟣 PASO 5: Probar la App

### 1. Crear usuario desde terminal
```powershell
# En una terminal, desde la raíz del proyecto
curl -X POST http://localhost:3000/register `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"test@test.com\",\"password\":\"123456\",\"role\":\"user\"}'
```

### 2. Login en la App
- Email: `test@test.com`
- Password: `123456`
- Click en "Login"

### 3. Ver datos vulnerables
Deberías ver:
- ✅ Lista de usuarios (sin autenticación)
- ✅ Contraseñas en texto plano
- ✅ Datos administrativos sin protección

---

## 🚀 Ataques Rápidos

### Ver todos los usuarios:
```powershell
curl http://localhost:3000/users | ConvertFrom-Json | Format-Table
```

### Ver contraseñas:
```powershell
curl http://localhost:3000/users | jq '.[].password'
```

### Acceder a endpoints administrativos:
```powershell
curl http://localhost:3000/admin
curl http://localhost:3000/info
```

---

## ✅ Checklist de Verificación

- [ ] Backend corriendo en puerto 3000
- [ ] `curl http://localhost:3000/users` retorna `[]` o lista de usuarios
- [ ] Flutter app instala sin errores
- [ ] App conecta al backend (ve "Datos cargados")
- [ ] Puedes hacer login
- [ ] Ves datos de usuarios en el dashboard

---

## 🐛 Solución de Problemas

| Problema | Solución |
|----------|----------|
| **"Cannot find npm"** | Instala Node.js desde nodejs.org |
| **"Port 3000 already in use"** | `netstat -ano \| findstr 3000` y cierra ese proceso |
| **"Connection refused"** | Verifica que `npm start` está ejecutándose |
| **App no conecta** | Cambia `localhost` por tu IP local en `main.dart` |
| **"Flutter command not found"** | Instala Flutter desde flutter.dev |
| **MongoDB connection error** | Opcional - la app funciona sin BD persistente |

---

## 🔑 Notas Importantes

1. **Si accedes desde otro dispositivo:**
   - Cambia `localhost:3000` por `TU_IP:3000` en main.dart
   - Ej: `http://192.168.1.100:3000`

2. **Si quieres exponer públicamente:**
   - Usa Ngrok: `ngrok http 3000`
   - Copia la URL y úsala en main.dart

3. **Para ver logs con sensibles:**
   - Abre Android Studio / DevTools
   - En la sección de logs ves tokens y contraseñas

4. **Datos se pierden al reiniciar:**
   - Crea usuarios nuevos cada vez
   - O instala MongoDB local para persistencia

---

## 📚 Próximos pasos

1. ✅ **Todo funciona** → Lee [LABORATORIO_README.md](LABORATORIO_README.md)
2. 🔐 **Intercepta tráfico** → Usa Burp Suite o Wireshark
3. 📦 **Extrae APK** → Ingeniería inversa con apktool
4. 📝 **Documenta ataques** → Crea reporte de pentesting

---

**¡Listo para comenzar! 🚀**

Si tienes problemas, revisa los logs de la consola o abre una issue.


@echo off
REM Script para probar los endpoints vulnerables

echo ========================================
echo  TEST APIs - Backend Vulnerable
echo ========================================
echo.

set SERVER=http://localhost:3000

echo [1] Probando conexion al servidor...
curl -I %SERVER% >nul 2>&1
if errorlevel 1 (
  echo ERROR: No se pudo conectar a %SERVER%
  echo Asegúrate de que el servidor está corriendo: npm start
  pause
  exit /b 1
)
echo OK: Servidor respondiendo

echo.
echo [2] Obteniendo lista de usuarios...
curl %SERVER%/users
echo.

echo.
echo [3] Obteniendo datos admin...
curl %SERVER%/admin
echo.

echo.
echo [4] Obteniendo informacion del servidor...
curl %SERVER%/info
echo.

echo.
echo [5] Creando un usuario de prueba...
curl -X POST %SERVER%/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@example.com\",\"password\":\"password123\",\"role\":\"user\"}"
echo.

echo.
echo ========================================
echo  TESTS COMPLETADOS
echo ========================================
pause

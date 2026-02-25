@echo off
REM Script para iniciar el backend vulnerable en Windows

echo ========================================
echo  Backend Vulnerable - Iniciando...
echo ========================================

echo.
echo Instalando dependencias...
call npm install

echo.
echo Iniciando servidor en puerto 3000...
echo Presiona CTRL+C para detener el servidor
echo.

call npm start

pause

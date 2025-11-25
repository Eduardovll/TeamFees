@echo off
REM Script para criar links simbólicos das bibliotecas (versões sem número)
REM Executar como Administrador ou usar copy ao invés de mklink

setlocal
set SDK_PATH=C:\Users\%USERNAME%\Documents\Embarcadero\Studio\SDKs\ubuntu22.04.sdk\lib\x86_64-linux-gnu

echo === Criando links simbolicos das bibliotecas ===
echo Diretorio: %SDK_PATH%
echo.

cd /d "%SDK_PATH%" 2>nul
if errorlevel 1 (
    echo ERRO: Diretorio nao encontrado: %SDK_PATH%
    echo Execute copy_sdk_libs.ps1 primeiro!
    pause
    exit /b 1
)

echo Criando links...
copy /Y libc.so.6 libc.so >nul 2>&1
copy /Y libdl.so.2 libdl.so >nul 2>&1
copy /Y libpthread.so.0 libpthread.so >nul 2>&1
copy /Y libm.so.6 libm.so >nul 2>&1
copy /Y libz.so.1 libz.so >nul 2>&1
copy /Y libgcc_s.so.1 libgcc_s.so >nul 2>&1

echo.
echo === Verificando arquivos ===
dir /b *.so

echo.
echo === Concluido ===
echo Bibliotecas prontas para compilacao Linux64!
echo.
pause

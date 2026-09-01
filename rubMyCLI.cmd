@echo off
setlocal enabledelayedexpansion

:: 1. Definisce ed esplicita il percorso del file .ps1 associato
set "PS1_FILE=%~dpn0.ps1"

:: 2. Controllo immediato: se il file .ps1 non esiste, si arresta subito
if not exist "%PS1_FILE%" (
    color 0C
    echo [ERRORE] File script non trovato:
    echo "%PS1_FILE%"
    echo.
    echo Verificare che il file .ps1 sia presente nella stessa cartella e con lo stesso nome del file .cmd.
    color 07
    pause
    exit /b 1
)

:: 3. Imposta la directory di lavoro nella cartella dello script
pushd "%~dp0"

:: 4. Tenta di impostare la ExecutionPolicy nel Registro utente
powershell.exe -MTA -NoLogo -NoProfile -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" >nul 2>&1

if %errorlevel% neq 0 (
    color 0E
    echo [ATTENZIONE] Impossibile aggiornare la Execution Policy utente via comando.
    echo Tentativo di esecuzione diretta con bypass di sessione...
    echo.
    color 07
)

:: 5. Esegue lo script PowerShell
powershell.exe -MTA -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"

if %errorlevel% neq 0 (
    color 0C
    echo.
    echo [ERRORE] Lo script PowerShell si e concluso con un errore (Codice: %errorlevel%).
    color 07
    pause
    popd
    exit /b %errorlevel%
)

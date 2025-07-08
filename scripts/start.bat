@echo off
setlocal

REM Farger for output (ANSI escape codes fungerer kanskje ikke i alle Windows-terminaler)
REM Bruker standard echo for meldinger.
echo Starter Vitalparametermonitor Oppsett- og Oppstartskript for Windows...

REM Ga til rotmappen til prosjektet
cd /D "%~dp0\.."

set "PYTHON_CODE_DIR=Python\Code"
set "VENV_DIR=%PYTHON_CODE_DIR%\venv"
set "REQUIREMENTS_FILE=%PYTHON_CODE_DIR%\requirements.txt"
set "PYTHON_CMD=python"

REM Funksjon for a sjekke om Python 3 er installert (forenklet sjekk)
echo.
echo Sjekker Python 3 installasjon...
where %PYTHON_CMD% >nul 2>nul
if %errorlevel% neq 0 (
    echo Python er ikke funnet i PATH.
    echo Vennligst installer Python 3 (sorg for at 'Add Python to PATH' er krysset av under installasjon) og prov igjen.
    goto :eof
)

%PYTHON_CMD% -V > python_version.tmp
set /p PY_VERSION=<python_version.tmp
del python_version.tmp

echo Funnet Python versjon: %PY_VERSION%
if not "%PY_VERSION:Python 3=%" == "%PY_VERSION%" (
    echo Python 3 er installert.
) else (
    echo Python 3 ser ikke ut til aa vaere installert (fant %PY_VERSION%).
    echo Vennligst installer Python 3 og prov igjen.
    goto :eof
)

REM Opprette og aktivere virtuelt miljoe
echo.
echo Setter opp virtuelt miljoe i %VENV_DIR%...
if not exist "%VENV_DIR%\Scripts\activate.bat" (
    echo Oppretter virtuelt miljoe...
    %PYTHON_CMD% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo Kunne ikke opprette virtuelt miljoe. Sjekk at 'venv' modulen er tilgjengelig.
        goto :eof
    )
    echo Virtuelt miljoe opprettet.
) else (
    echo Virtuelt miljoe eksisterer allerede.
)

echo Aktiverer virtuelt miljoe...
call "%VENV_DIR%\Scripts\activate.bat"
if errorlevel 1 (
    echo Kunne ikke aktivere virtuelt miljoe.
    goto :eof
)
echo Virtuelt miljoe aktivert.

REM Installere avhengigheter
echo.
if not exist "%REQUIREMENTS_FILE%" (
    echo Filen %REQUIREMENTS_FILE% ble ikke funnet. Kan ikke installere avhengigheter.
    echo Sorg for at du har en requirements.txt fil i %PYTHON_CODE_DIR%.
    echo Eksempel innhold for requirements.txt:
    echo opencv-python
    echo numpy
    echo scipy
    echo flask
    echo flask-cors
    echo pillow
    echo requests
    echo configparser
    REM Ikke avslutt her, la brukeren potensielt kjore uten.
) else (
    echo Installerer avhengigheter fra %REQUIREMENTS_FILE%...
    pip install -r "%REQUIREMENTS_FILE%"
    if errorlevel 1 (
        echo Kunne ikke installere avhengigheter. Sjekk feilmeldingene ovenfor.
        echo Du ma kanskje installere noen systemavhengigheter manuelt.
        goto :eof
    )
    echo Avhengigheter installert OK.
)


echo.
echo Oppsett fullfort!
echo.

REM Spor brukeren hva som skal startes
echo Hva vil du starte?
echo 1) Server
echo 2) Klient
echo 3) Bade Server og Klient
echo 4) Avslutt
choice /C 1234 /M "Velg et alternativ (1-4):"

REM Gaa til Python-katalogen
cd "%PYTHON_CODE_DIR%"
if errorlevel 1 (
    echo Kunne ikke navigere til %PYTHON_CODE_DIR%.
    goto :deactivate_venv
)


if %errorlevel% == 1 (
    echo Starter serveren...
    start "VitalParameterServer" %PYTHON_CMD% servidor.py
)
if %errorlevel% == 2 (
    echo Starter klienten...
    start "VitalParameterKlient" %PYTHON_CMD% cliente.py
)
if %errorlevel% == 3 (
    echo Starter serveren...
    start "VitalParameterServer" %PYTHON_CMD% servidor.py
    echo Venter 5 sekunder for serveren a starte...
    timeout /t 5 /nobreak >nul
    echo Starter klienten...
    start "VitalParameterKlient" %PYTHON_CMD% cliente.py
)
if %errorlevel% == 4 (
    echo Avslutter.
)

:deactivate_venv
REM Deaktiver virtuelt miljoe ved avslutning
if defined VIRTUAL_ENV (
    echo Deaktiverer virtuelt miljoe...
    call deactivate
)

echo Skript fullfort.
:eof
endlocal

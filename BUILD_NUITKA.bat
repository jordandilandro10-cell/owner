@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  SUPREMACY BETA - Build via NUITKA (compatible Python 3.14)
REM
REM  Ce script est le PLAN B si tu ne veux pas installer Python 3.13.
REM  Nuitka compile Python -^> C -^> .exe natif.
REM  Pas de bootloader PyInstaller = pas de crash sur Python 3.14.
REM
REM  Requis: MSVC Build Tools OU MinGW (Nuitka telechargera MinGW auto
REM          si aucun compilateur trouve, mais ca prend 5-10 min).
REM ============================================================
cd /d "%~dp0"
echo.
echo  ============================================
echo   SUPREMACY BETA - BUILD NUITKA (Python 3.14 OK)
echo  ============================================
echo.

REM --- Verifie SUPREMACY-8C3.exe ---
if not exist "SUPREMACY-8C3.exe" (
    echo [!] SUPREMACY-8C3.exe introuvable.
    echo     Place-le a cote de ce script avant de build.
    pause & exit /b 1
)
echo [+] SUPREMACY-8C3.exe trouve

REM --- Verifie loader.py ---
if not exist "loader.py" (
    echo [!] loader.py introuvable.
    pause & exit /b 1
)

REM --- Trouve python (n'importe quelle version 3.10+, y compris 3.14) ---
set "PYEXE="
python --version >nul 2>&1
if !errorlevel! equ 0 (
    for /f "delims=" %%P in ('python -c "import sys; print(sys.executable)"') do set "PYEXE=%%P"
)
if not defined PYEXE (
    py -c "import sys" >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%P in ('py -c "import sys; print(sys.executable)"') do set "PYEXE=%%P"
    )
)
if not defined PYEXE (
    echo [!] Aucun Python trouve. Installe-le depuis https://www.python.org
    pause & exit /b 1
)
echo [+] Python: !PYEXE!
"!PYEXE!" --version

REM --- Repare numpy si casse (probleme fréquent sur 3.14) ---
echo.
echo [*] Verification/reparation de numpy...
"!PYEXE!" -c "import numpy" >nul 2>&1
if errorlevel 1 (
    echo [*] numpy casse, reinstallation...
    "!PYEXE!" -m pip install --quiet --force-reinstall --no-cache-dir numpy
)

REM --- Nettoie les anciens builds ---
echo [*] Nettoyage des anciens builds...
if exist "loader.build" rmdir /s /q "loader.build" 2>nul
if exist "loader.dist" rmdir /s /q "loader.dist" 2>nul
if exist "loader.onefile-build" rmdir /s /q "loader.onefile-build" 2>nul
if not exist "dist" mkdir "dist"

REM --- Met a jour pip ---
echo.
echo [1/4] Mise a jour pip + installation Nuitka + zstandard + ordered-set...
"!PYEXE!" -m pip install --quiet --upgrade pip setuptools wheel
"!PYEXE!" -m pip install --quiet --upgrade nuitka zstandard ordered-set
if errorlevel 1 (
    echo [!] Installation Nuitka echouee. Verifie ta connexion internet.
    pause & exit /b 1
)
echo [+] Nuitka installe

REM --- Install les deps du projet ---
echo.
echo [*] Installation dependances projet (PyQt5, cryptography)...
"!PYEXE!" -m pip install --quiet --upgrade PyQt5 cryptography
if errorlevel 1 (
    echo [!] Attention: PyQt5 ou cryptography absent. Le build peut echouer.
)

REM --- Construit les --include-data-file conditionnels ---
set "DATAFILES=--include-data-file=SUPREMACY-8C3.exe=SUPREMACY-8C3.exe"
if exist "hosts" set "DATAFILES=!DATAFILES! --include-data-file=hosts=hosts"
if exist "gate_recording.json" set "DATAFILES=!DATAFILES! --include-data-file=gate_recording.json=gate_recording.json"

REM --- Compile loader.py -^> SUPREMACY-BETA.exe ---
echo.
echo [2/4] Compilation loader.py -- SUPREMACY-BETA.exe (10-20 min, patience)...
echo       Nuitka est plus lent que PyInstaller mais bien plus stable.
echo.
"!PYEXE!" -m nuitka ^
    --onefile ^
    --windows-console-mode=disable ^
    --windows-uac-admin ^
    --enable-plugin=pyqt5 ^
    --assume-yes-for-downloads ^
    --output-dir=dist ^
    --output-filename=SUPREMACY-BETA.exe ^
    !DATAFILES! ^
    loader.py
if errorlevel 1 (
    echo.
    echo [!] Build Nuitka echoue.
    echo     Verifie les erreurs ci-dessus. Souvent c'est:
    echo       - MSVC Build Tools manquant (installe Visual Studio Community
    echo         avec "Desktop development with C++")
    echo       - Un import Python que Nuitka n'a pas trouve
    echo.
    pause & exit /b 1
)
echo [+] loader.py -- dist\SUPREMACY-BETA.exe OK

REM --- Compile IKAAM_START.py -^> IKAAM_START.exe ---
if exist "IKAAM_START.py" (
    echo.
    echo [3/4] Compilation IKAAM_START.py -- IKAAM_START.exe...
    "!PYEXE!" -m nuitka ^
        --onefile ^
        --windows-console-mode=disable ^
        --windows-uac-admin ^
        --assume-yes-for-downloads ^
        --output-dir=dist ^
        --output-filename=IKAAM_START.exe ^
        IKAAM_START.py
    if errorlevel 1 (
        echo [!] Build IKAAM_START echoue
    ) else (
        echo [+] IKAAM_START.py -- dist\IKAAM_START.exe OK
    )
) else (
    echo [3/4] IKAAM_START.py absent, saute.
)

REM --- Compile install_hosts.py -^> install_hosts.exe ---
if exist "install_hosts.py" (
    echo.
    echo [4/4] Compilation install_hosts.py -- install_hosts.exe...
    "!PYEXE!" -m nuitka ^
        --onefile ^
        --windows-console-mode=disable ^
        --windows-uac-admin ^
        --assume-yes-for-downloads ^
        --output-dir=dist ^
        --output-filename=install_hosts.exe ^
        install_hosts.py
    if errorlevel 1 (
        echo [!] Build install_hosts echoue (optionnel)
    ) else (
        echo [+] install_hosts.py -- dist\install_hosts.exe OK
    )
) else (
    echo [4/4] install_hosts.py absent, saute.
)

REM --- Nettoyage final ---
if exist "loader.build" rmdir /s /q "loader.build" 2>nul
if exist "loader.dist" rmdir /s /q "loader.dist" 2>nul
if exist "loader.onefile-build" rmdir /s /q "loader.onefile-build" 2>nul

echo.
echo  ============================================
echo   BUILD NUITKA TERMINE
echo  ============================================
echo.
if exist "dist\SUPREMACY-BETA.exe" (
    echo   Fichiers dans dist\:
    echo.
    dir /b dist\*.exe
    echo.
    echo   Pour lancer: double-clic sur dist\SUPREMACY-BETA.exe
) else (
    echo   [!] Aucun .exe genere. Verifie les erreurs ci-dessus.
)
echo.
pause
endlocal

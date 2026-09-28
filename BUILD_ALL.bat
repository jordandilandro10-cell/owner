@echo off
setlocal EnableDelayedExpansion
REM ============================================================
REM  SUPREMACY BETA - Build tous les .exe (PyInstaller)
REM  Double-clic pour compiler. Resultat dans dist\
REM  SUPREMACY-8C3.exe est integre dans SUPREMACY-BETA.exe
REM
REM  FIX: Python 3.14 non supporte par PyInstaller stable.
REM       Ce script detecte la version et guide vers Python 3.12/3.13
REM       qui ont des wheels officiels PyInstaller.
REM ============================================================
cd /d "%~dp0"
echo.
echo  ============================================
echo   SUPREMACY BETA - BUILD .EXE
echo  ============================================
echo.

REM --- Verifie que SUPREMACY-8C3.exe existe ---
if not exist "SUPREMACY-8C3.exe" (
    echo [!] SUPREMACY-8C3.exe introuvable dans ce dossier.
    echo     Place-le a cote de ce script avant de build.
    pause & exit /b 1
)
echo [+] SUPREMACY-8C3.exe trouve

REM --- Trouve un Python compatible (3.12 ou 3.13 prefere, PAS 3.14) ---
echo.
echo [*] Recherche d'un Python compatible...
set "PYEXE="

REM Cherche via py launcher (priorite: 3.13, puis 3.12, puis 3.11)
for %%V in (3.13 3.12 3.11) do (
    if not defined PYEXE (
        py -%%V -c "import sys" >nul 2>&1
        if !errorlevel! equ 0 (
            for /f "delims=" %%P in ('py -%%V -c "import sys; print(sys.executable)"') do set "PYEXE=%%P"
            echo [+] Python %%V trouve: !PYEXE!
        )
    )
)

REM Fallback: python.exe du PATH, mais REJETTE 3.14
if not defined PYEXE (
    python -c "import sys; sys.exit(0 if sys.version_info[:2] in [(3,11),(3,12),(3,13)] else 1)" >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%P in ('python -c "import sys; print(sys.executable)"') do set "PYEXE=%%P"
        echo [+] Python compatible via PATH: !PYEXE!
    )
)

if not defined PYEXE (
    echo.
    echo  ============================================
    echo   [!] AUCUN PYTHON COMPATIBLE TROUVE
    echo  ============================================
    echo.
    echo   PyInstaller ne supporte pas Python 3.14 (trop recent).
    echo   Installe Python 3.13 ou 3.12 depuis:
    echo.
    echo       https://www.python.org/downloads/
    echo.
    echo   Coche "Add Python to PATH" et "py launcher"
    echo   pendant l'installation. Puis relance ce script.
    echo.
    pause & exit /b 1
)

REM --- Affiche la version choisie ---
"!PYEXE!" --version

REM --- Nettoie les builds precedents pour eviter les caches corrompus ---
echo.
echo [*] Nettoyage des builds precedents...
if exist "build" rmdir /s /q "build" 2>nul
if exist "SUPREMACY-BETA.spec" del /q "SUPREMACY-BETA.spec" 2>nul
if exist "IKAAM_START.spec" del /q "IKAAM_START.spec" 2>nul
if exist "install_hosts.spec" del /q "install_hosts.spec" 2>nul

REM --- Met a jour pip d'abord (evite les bugs distlib) ---
echo.
echo [1/4] Mise a jour de pip et installation de PyInstaller...
"!PYEXE!" -m pip install --quiet --upgrade pip setuptools wheel
if errorlevel 1 (
    echo [!] Impossible de mettre a jour pip. Continuons quand meme.
)

REM --- Install PyInstaller stable (marche sur 3.11/3.12/3.13) ---
"!PYEXE!" -m pip install --quiet --upgrade "pyinstaller>=6.11,<7.0"
if errorlevel 1 (
    echo [!] Installation PyInstaller echouee.
    echo     Verifie ta connexion internet et relance.
    pause & exit /b 1
)

REM --- Verifie que le bootloader est present ---
"!PYEXE!" -c "import PyInstaller, os, sys; b=os.path.join(os.path.dirname(PyInstaller.__file__),'bootloader'); sys.exit(0 if os.path.isdir(b) and os.listdir(b) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [!] Bootloader PyInstaller manquant. Reinstallation forcee...
    "!PYEXE!" -m pip install --quiet --force-reinstall --no-cache-dir "pyinstaller>=6.11,<7.0"
    if errorlevel 1 (
        echo [!] Reinstallation echouee. Abandon.
        pause & exit /b 1
    )
)
echo [+] PyInstaller pret

REM --- Install les dependances communes pour eviter les hidden-import warnings ---
echo [*] Installation des dependances du projet...
"!PYEXE!" -m pip install --quiet --upgrade PyQt5 cryptography
if errorlevel 1 (
    echo [!] Attention: PyQt5 ou cryptography n'a pas pu s'installer.
    echo     Le build peut echouer si loader.py les utilise.
)

REM --- Compile loader.py -^> SUPREMACY-BETA.exe (avec 8C3 integre) ---
echo.
echo [2/4] Compilation loader.py -- SUPREMACY-BETA.exe (3-8 min, 8C3 inclus)...

REM Construit les --add-data conditionnellement (evite l'erreur si absent)
set "ADDDATA=--add-data SUPREMACY-8C3.exe;."
if exist "hosts" set "ADDDATA=!ADDDATA! --add-data hosts;."
if exist "gate_recording.json" set "ADDDATA=!ADDDATA! --add-data gate_recording.json;."

"!PYEXE!" -m PyInstaller --noconfirm --onefile --noconsole --uac-admin ^
    --name SUPREMACY-BETA ^
    --hidden-import=PyQt5.sip ^
    --hidden-import=cryptography ^
    --hidden-import=cryptography.hazmat.primitives.ciphers.aead ^
    --hidden-import=cryptography.hazmat.backends.openssl ^
    !ADDDATA! ^
    loader.py
if errorlevel 1 (
    echo.
    echo [!] Build loader echoue
    echo.
    echo     Fallback: essai avec Nuitka...
    "!PYEXE!" -m pip install --quiet nuitka
    if not errorlevel 1 (
        "!PYEXE!" -m nuitka --onefile --windows-disable-console --enable-plugin=pyqt5 ^
            --include-data-file=SUPREMACY-8C3.exe=SUPREMACY-8C3.exe ^
            --output-dir=dist ^
            loader.py
        if errorlevel 1 (
            echo [!] Nuitka a aussi echoue. Verifie loader.py et ses imports.
            pause & exit /b 1
        )
        echo [+] Nuitka a reussi
    ) else (
        echo [!] Impossible d'installer Nuitka non plus. Abandon.
        pause & exit /b 1
    )
) else (
    echo [+] loader.py -- dist\SUPREMACY-BETA.exe OK
)

REM --- Compile IKAAM_START.py -^> IKAAM_START.exe ---
if exist "IKAAM_START.py" (
    echo.
    echo [3/4] Compilation IKAAM_START.py -- IKAAM_START.exe...
    "!PYEXE!" -m PyInstaller --noconfirm --onefile --noconsole --uac-admin ^
        --name IKAAM_START ^
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
    "!PYEXE!" -m PyInstaller --noconfirm --onefile --noconsole --uac-admin ^
        --name install_hosts ^
        install_hosts.py
    if errorlevel 1 (
        echo [!] Build install_hosts echoue (optionnel)
    ) else (
        echo [+] install_hosts.py -- dist\install_hosts.exe OK
    )
) else (
    echo [4/4] install_hosts.py absent, saute.
)

REM --- Resume ---
echo.
echo  ============================================
echo   BUILD TERMINE
echo  ============================================
echo.
if exist "dist\*.exe" (
    echo   Fichiers dans dist\:
    echo.
    dir /b dist\*.exe
    echo.
    echo   SUPREMACY-BETA.exe contient deja:
    echo     - SUPREMACY-8C3.exe (integre)
    if exist "hosts" echo     - hosts (template)
    if exist "gate_recording.json" echo     - gate_recording.json
    echo.
    echo   Pour lancer: double-clic sur dist\SUPREMACY-BETA.exe
    if exist "dist\IKAAM_START.exe" echo   Ou utilise dist\IKAAM_START.exe (lance tout)
) else (
    echo   [!] Aucun .exe genere. Verifie les erreurs ci-dessus.
)
echo.
pause
endlocal

SUPREMACY BETA - Build Scripts
================================

Deux scripts sont fournis. Prends celui qui correspond a ta situation:

--------------------------------------------------------------------
1) BUILD_ALL.bat  (recommande, plus rapide)
--------------------------------------------------------------------
   Utilise PyInstaller. Requiert Python 3.11, 3.12 ou 3.13.
   Le script detecte automatiquement une version compatible via
   le "py launcher" (installe avec Python sur Windows).

   Ton probleme actuel: tu as Python 3.14 installe.
   PyInstaller ne supporte PAS encore 3.14 (pas de bootloader).

   SOLUTION: installe Python 3.13 depuis:
     https://www.python.org/downloads/release/python-3130/
   (coche "Add Python to PATH" et "py launcher" pendant l'install)

   Ensuite double-clic sur BUILD_ALL.bat. Ca marche.

   Temps de build: 3-8 minutes.

--------------------------------------------------------------------
2) BUILD_NUITKA.bat  (plan B, marche avec Python 3.14)
--------------------------------------------------------------------
   Utilise Nuitka au lieu de PyInstaller. Compile Python -> C -> .exe
   natif. Pas de bootloader = pas de crash sur Python 3.14.

   Requis: MSVC Build Tools (Visual Studio Community avec
           "Desktop development with C++") OU laisse Nuitka
           telecharger MinGW automatiquement (~200 Mo, 5-10 min).

   Double-clic. Prends du cafe. Temps de build: 10-20 minutes.

--------------------------------------------------------------------
Erreurs communes
--------------------------------------------------------------------

"PyInstaller does not include a pre-compiled bootloader"
  -> Tu es sur Python 3.14. Utilise BUILD_NUITKA.bat, OU installe
     Python 3.13 et relance BUILD_ALL.bat.

"Unable to find resource t64.exe in package pip._vendor.distlib"
  -> Bug pip sur Python 3.14. BUILD_ALL.bat le contourne en
     upgradant pip avant tout.

"DLL load failed while importing _multiarray_umath" (numpy)
  -> numpy casse sur Python 3.14. Les scripts le reinstallent
     automatiquement. Sinon manuellement:
       pip install --force-reinstall --no-cache-dir numpy

"MSVC not found" ou "cl.exe not found" (Nuitka)
  -> Installe Visual Studio Community 2022 gratuitement:
     https://visualstudio.microsoft.com/downloads/
     Coche "Desktop development with C++" pendant l'install.
     OU relance BUILD_NUITKA.bat et laisse-le installer MinGW.

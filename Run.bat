@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: Run.bat - Application Bootstrapper
:: Downloads the latest release and required assets from GitHub,
:: installs a certificate if needed, then launches the application.
:: ============================================================


:: ------------------------------------------------------------
:: CONFIGURATION
:: ------------------------------------------------------------
set "REPO_NAME=MAT"
set "REPO_OWNER=acotales"

set "BASE_DIR=.\%REPO_NAME%"
set "ASSETS_DIR=%BASE_DIR%\assets"
set "TEMP_DIR=%BASE_DIR%\temp"

set "EXE_PATH=%BASE_DIR%\%REPO_NAME%.exe"
set "TEMP_ZIP=%TEMP_DIR%\%REPO_NAME%.zip"
set "CERT_PATH=%ASSETS_DIR%\certificate.cer"

set "API_URL=https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest"
set "ZIP_URL=https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/main.zip"


:: ------------------------------------------------------------
:: DIRECTORY SETUP
:: Create required directories if they don't already exist.
:: ------------------------------------------------------------
echo [Setup] Preparing directories...
for %%D in ("%BASE_DIR%" "%ASSETS_DIR%" "%TEMP_DIR%") do (
    if not exist "%%~D" (
        mkdir "%%~D" 2>nul || (
            echo [ERROR] Failed to create directory: %%~D
            exit /b 1
        )
    )
)


:: ------------------------------------------------------------
:: ASSET PRE-CHECK
:: Search recursively from the script's own directory for the
:: 3 required asset files. If all are found, copy them into the
:: assets folder and skip the ZIP download entirely.
:: If any are missing, fall through to the full download path.
:: ------------------------------------------------------------
echo [Check] Scanning for existing asset files...

set "FOUND_CERT="
set "FOUND_AIO="
set "FOUND_ICO="

:: Walk the entire directory tree starting from where Run.bat lives (%~dp0)
for /r "%~dp0" %%F in (certificate.cer) do if exist "%%F" set "FOUND_CERT=%%F"
for /r "%~dp0" %%F in (aio.cmd)         do if exist "%%F" set "FOUND_AIO=%%F"
for /r "%~dp0" %%F in (app.ico)         do if exist "%%F" set "FOUND_ICO=%%F"

if defined FOUND_CERT echo [Check] Found: %FOUND_CERT%
if defined FOUND_AIO  echo [Check] Found: %FOUND_AIO%
if defined FOUND_ICO  echo [Check] Found: %FOUND_ICO%

if defined FOUND_CERT if defined FOUND_AIO if defined FOUND_ICO (
    :: --------------------------------------------------------
    :: FAST PATH: All 3 assets already exist locally.
    :: Copy them into the assets directory, then go straight to
    :: downloading the .exe — skip the ZIP download entirely.
    :: --------------------------------------------------------
    echo [Check] All required asset files found locally. Skipping repository download.

    echo [Setup] Copying local assets to %ASSETS_DIR%...
    xcopy /Y "%FOUND_CERT%" "%ASSETS_DIR%\" >nul 2>&1
    xcopy /Y "%FOUND_AIO%"  "%ASSETS_DIR%\" >nul 2>&1
    xcopy /Y "%FOUND_ICO%"  "%ASSETS_DIR%\" >nul 2>&1
    echo [Setup] Assets copied successfully.

    goto :DownloadExe
)

:: --------------------------------------------------------
:: SLOW PATH: One or more assets are missing.
:: Download the repository ZIP, extract it, and copy all
:: required asset files before downloading the .exe.
:: --------------------------------------------------------
echo [Check] One or more asset files not found. Proceeding with full download...


:: ------------------------------------------------------------
:: DOWNLOAD: Repository ZIP (for assets)
:: Downloads the main branch archive to extract supporting files.
:: ------------------------------------------------------------
echo [Download] Fetching repository archive for assets...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%TEMP_ZIP%' -UseBasicParsing;" ^
    "  exit 0" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to download repository archive. Check your internet connection.
    goto :Cleanup
)
echo [Download] Repository archive downloaded successfully.


:: ------------------------------------------------------------
:: EXTRACT & COPY ASSETS
:: Unzips the archive and copies required asset files to the
:: assets directory. Cleans up temp files afterwards.
:: ------------------------------------------------------------
echo [Extract] Extracting repository archive...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_DIR%' -Force;" ^
    "  exit 0" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to extract archive.
    goto :Cleanup
)

echo [Extract] Copying required asset files ^(aio.cmd, certificate.cer, app.ico^)...
for /r "%TEMP_DIR%" %%F in (aio.cmd certificate.cer app.ico) do (
    if exist "%%F" (
        xcopy /Y "%%F" "%ASSETS_DIR%\" >nul 2>&1
        echo [Extract] Copied: %%~nxF
    )
)

echo [Cleanup] Removing temporary files...
if exist "%TEMP_ZIP%" del /f /q "%TEMP_ZIP%" 2>nul
if exist "%TEMP_DIR%"  rmdir /s /q "%TEMP_DIR%" 2>nul


:: ------------------------------------------------------------
:: DOWNLOAD: Latest Release EXE
:: Queries the GitHub API for the latest release and downloads
:: the first .exe asset found.
:: Both the fast path and slow path converge here.
:: ------------------------------------------------------------
:DownloadExe
echo [Download] Fetching latest release executable...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  $release = Invoke-RestMethod -Uri '%API_URL%' -Headers @{ 'User-Agent' = 'Run.bat' };" ^
    "  $asset = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1;" ^
    "  if (-not $asset) { Write-Error 'No .exe asset found in latest release.'; exit 2 }" ^
    "  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile '%EXE_PATH%' -UseBasicParsing;" ^
    "  exit 0" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"

set "EXE_ERR=%errorlevel%"
if %EXE_ERR% equ 1 echo [ERROR] Network or GitHub API failure. Check your internet connection.
if %EXE_ERR% equ 2 echo [ERROR] No .exe file found in the latest release.
if %EXE_ERR% gtr 0 (
    echo [ERROR] Executable download failed ^(exit code: %EXE_ERR%^).
    goto :Cleanup
)
echo [Download] Executable downloaded successfully.


:: ------------------------------------------------------------
:: CERTIFICATE INSTALLATION
:: Checks if the certificate is already installed in the local
:: machine store. Installs it if missing.
:: ------------------------------------------------------------
:StartProcess
if not exist "%CERT_PATH%" (
    echo [Certificate] No certificate file found at %CERT_PATH%. Skipping installation.
    goto :LaunchApp
)

echo [Certificate] Checking if certificate is already installed...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  $cert   = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_PATH%');" ^
    "  $thumb  = ($cert.Thumbprint -replace '\s','').ToUpperInvariant();" ^
    "  $exists = Get-ChildItem 'Cert:\LocalMachine\My' |" ^
    "            Where-Object { ($_.Thumbprint -replace '\s','').ToUpperInvariant() -eq $thumb };" ^
    "  if ($exists) { exit 0 } else { exit 1 }" ^
    "} catch { Write-Host $_.Exception.Message; exit 2 }"

if %errorlevel% equ 0 (
    echo [Certificate] Certificate is already installed. Skipping.
    goto :LaunchApp
)
if %errorlevel% equ 2 (
    echo [WARNING] Could not read certificate file. Skipping installation.
    goto :LaunchApp
)

echo [Certificate] Installing certificate into LocalMachine\My store...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "try {" ^
    "  Import-Certificate -FilePath '%CERT_PATH%' -CertStoreLocation 'Cert:\LocalMachine\My' | Out-Null;" ^
    "  exit 0" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"

if %errorlevel% equ 0 (
    echo [Certificate] Certificate installed successfully.
) else (
    echo [WARNING] Certificate installation failed. The application may not run correctly.
)


:: ------------------------------------------------------------
:: LAUNCH APPLICATION
:: Verifies the executable exists before launching, then shows
:: a success dialog via PowerShell WPF.
:: ------------------------------------------------------------
:LaunchApp
if not exist "%EXE_PATH%" (
    echo [ERROR] Executable not found at %EXE_PATH%. Cannot launch application.
    exit /b 1
)

echo [Launch] Starting application: %EXE_PATH%
start "" "%EXE_PATH%"
:: Exit cleanly — the VBS launcher will show the success message box.
exit /b 0


:: ------------------------------------------------------------
:: CLEANUP ON FAILURE
:: Removes partial downloads / temp files before exiting.
:: ------------------------------------------------------------
:Cleanup
if exist "%TEMP_ZIP%" del /f /q "%TEMP_ZIP%" 2>nul
if exist "%TEMP_DIR%"  rmdir /s /q "%TEMP_DIR%" 2>nul
:: Exit with code 1 — the VBS launcher will show the error message box.
exit /b 1

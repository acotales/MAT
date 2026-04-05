@echo off
setlocal enabledelayedexpansion

:: ---------------------------
::  Administrator check
:: ---------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    :: Relaunch the script as admin using PowerShell
    powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs -WindowStyle Hidden"
    exit /b
)

:: ---------------------------
::  Variables
:: ---------------------------
set "REPO_OWNER=acotales"
set "REPO_NAME=MAT"
set "INSTALL_DIR=%ProgramData%\%REPO_NAME%"
set "TEMP_DIR=%TEMP%\%REPO_NAME%_Temp"
set "TEMP_ZIP=%TEMP%\%REPO_NAME%.zip"
set "CERT_PATH=%INSTALL_DIR%\assets\certificate.cer"
set "EXE_PATH=%INSTALL_DIR%\%REPO_NAME%.exe"
set RETRY_COUNT=0
set MAX_RETRIES=3

:: ---------------------------
::  Check if installation already exists
:: ---------------------------
if not exist "%INSTALL_DIR%" (
    echo Directory %INSTALL_DIR% does not exist. Starting download process.
    goto :DownloadFiles
) else (
    echo Directory exists. Checking for required files...
    if not exist "%EXE_PATH%" (
        echo %REPO_NAME%.exe is missing.
        goto :DownloadFiles
    )
    if not exist "%CERT_PATH%" (
        echo certificate.cer is missing.
        goto :DownloadFiles
    )
    :: Both files exist
    goto :ProcessFiles
)

:: ---------------------------
::  Download files (with retry counter)
:: ---------------------------
:DownloadFiles
set /a RETRY_COUNT+=1
if %RETRY_COUNT% gtr %MAX_RETRIES% (
    call :ShowMessageBox "Installation failed after %MAX_RETRIES% attempts." "Error" 16
    exit /b 1
)

echo DownloadFiles: Starting download process (attempt %RETRY_COUNT%).

:: Create directories
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Download the EXE from GitHub release
echo Downloading latest %REPO_NAME% release from GitHub.
powershell -Command "$ErrorActionPreference='Stop'; try { $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest'; $asset = $release.assets | Where-Object { $_.name -eq '%REPO_NAME%.exe' -or $_.name -like '*.exe' } | Select-Object -First 1; if ($asset) { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile \"%EXE_PATH%\"; exit 0 } else { Write-Host 'ERROR: No executable found in latest release.'; exit 2 } } catch { Write-Host 'ERROR: GitHub API or network failure.'; exit 1 }"

:: Handle PowerShell exit codes
if %errorlevel% equ 2 (
    call :ShowMessageBox "No .exe file found in the latest GitHub release." "Error" 16
    exit /b 1
)
if %errorlevel% neq 0 (
    :: Network/API error – retryable
    call :ShowMessageBox "Download failed (network/API error). Retry?" "Warning" 5+48
    if !errorlevel! equ 4 ( goto :DownloadFiles ) else ( goto :DownloadFailed )
)

:: Download source ZIP (for certificate and other assets)
echo Downloading source code from GitHub.
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/main.zip' -OutFile '%TEMP_ZIP%'"

:: Verify both downloads succeeded
if exist "%EXE_PATH%" if exist "%TEMP_ZIP%" (
    goto :ExtractFiles
) else (
    call :ShowMessageBox "Installation failed. Check your internet connection and try again." "Warning" 5+48
    if !errorlevel! equ 4 ( goto :DownloadFiles ) else ( goto :DownloadFailed )
)

:DownloadFailed
call :ShowMessageBox "Installation failed." "Error" 16
exit /b 1

:: ---------------------------
::  Extract files from ZIP
:: ---------------------------
:ExtractFiles
echo ExtractFiles: Extracting files.
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_DIR%' -Force"

:: Find the extracted folder (e.g., MAT-main)
for /d %%i in ("%TEMP_DIR%\MAT-*") do set "EXTRACTED_FOLDER=%%i"

:: Move files from extracted folder to MAT folder
echo Moving files to %INSTALL_DIR%.
xcopy /E /I /Y "%EXTRACTED_FOLDER%\*" "%INSTALL_DIR%"

:: Clean up temp files
del "%TEMP_ZIP%" 2>nul
rmdir /S /Q "%TEMP_DIR%" 2>nul
goto :ProcessFiles

:: ---------------------------
::  Install certificate and unblock EXE
:: ---------------------------
:ProcessFiles
echo ProcessFiles: Checking and installing certificate, unblocking executable.

:: Install certificate if not already present
if exist "%CERT_PATH%" (
    echo Checking for certificate installation.
    powershell -Command "$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_PATH%'); $thumb = $cert.Thumbprint; if (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumb }) { exit 0 } else { exit 1 }"
    if %errorlevel% equ 0 (
        echo Certificate is already installed.
    ) else (
        echo Installing certificate.
        powershell -Command "Import-Certificate -FilePath '%CERT_PATH%' -CertStoreLocation Cert:\LocalMachine\My"
        echo Certificate installed successfully.
    )
) else (
    echo Certificate file not found at %CERT_PATH%. Re-downloading.
    goto :DownloadFiles
)

:: Unblock the EXE (removes "downloaded from internet" marker)
if exist "%EXE_PATH%" (

    powershell -Command "Get-Item '%targetFile%' -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue" >nul 2>&1

    if %errorlevel% equ 0 (
        echo Unblocking %REPO_NAME%.exe.
        powershell -Command "Unblock-File -Path '%EXE_PATH%'" 2>nul
    )

    :: Run the executable file
    start "" "%EXE_PATH%"
) else (
    echo %REPO_NAME%.exe not found at %EXE_PATH%. Re-downloading.
    goto :DownloadFiles
)

call :ShowMessageBox "Installation completed successfully!" "Success" 64
pause
exit /b 0

:: ---------------------------
::  Helper function: Show a VBScript message box
::  %1 = message text, %2 = title, %3 = icon/button flags
:: ---------------------------
:ShowMessageBox
set "vbs=%temp%\msgbox.vbs"
echo wscript.quit msgbox("%~1", %3, "%~2") > "%vbs%"
wscript "%vbs%"
set "exitcode=%errorlevel%"
del "%vbs%"
exit /b %exitcode%

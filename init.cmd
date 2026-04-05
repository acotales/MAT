@echo off
setlocal enabledelayedexpansion

:: Set variables
set "REPO_OWNER=acotales"
set "REPO_NAME=MAT"
set "INSTALL_DIR=%ProgramData%\%REPO_NAME%"
set "TEMP_DIR=%TEMP%\%REPO_NAME%_Temp"
set "TEMP_ZIP=%TEMP%\%REPO_NAME%.zip"
set "CERT_PATH=%INSTALL_DIR%\assets\certificate.cer"
set "EXE_PATH=%INSTALL_DIR%\%REPO_NAME%.exe"


if not exist "%INSTALL_DIR%" (
    echo Directory %INSTALL_DIR% does not exist. Starting download process.
    goto :DownloadFiles

) else (
    echo Directory exists. Checking for required files...

    if not exist "%EXE_PATH%" (
        echo MAT.exe is missing.
        goto :DownloadFiles
    )

    if not exist "%CERT_PATH%" (
        echo certificate.cer is missing.
        goto :DownloadFiles
    )

    :: Both files exist
    goto :ProcessFiles
)



:DownloadFiles
echo DownloadFiles: Starting download process.

:: Create directories
echo Creating necessary directories
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Try to download the latest release EXE using GitHub API
echo Downloading latest MAT release from GitHub.
powershell -Command "$ErrorActionPreference='Stop'; try { $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest'; $asset = $release.assets | Where-Object { $_.name -eq '%REPO_NAME%.exe' -or $_.name -like '*.exe' } | Select-Object -First 1; if ($asset) { Write-Host \"Found executable: $($asset.name)\"; Invoke-WebRequest -Uri $asset.browser_download_url -OutFile \"%EXE_PATH%\"; exit 0 } else { Write-Host \"No EXE found in latest release.\"; exit 1 } } catch { Write-Host \"Error accessing GitHub API or no release found.\"; exit 1 }"

:: Download the repository as a zip file
echo Downloading MAT source code from GitHub.
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/main.zip' -OutFile '%TEMP_ZIP%'"

:: Check if all downloads were successful
if exist "%EXE_PATH%" if exist "%TEMP_ZIP%" (
    goto :ExtractFiles
) else (
    echo Download failed. Please check your internet connection.
    :: Create a temporary VBScript file for Warning
    echo wscript.quit msgbox("Installation failed. Please check your internet connection and try again.", 5+48, "Warning") > %temp%\retry.vbs
    wscript %temp%\retry.vbs
    del %temp%\retry.vbs

    :: Check the return code (4 = Retry, 2 = Cancel)
    if %errorlevel%==4 (
        echo Retrying...
        goto :DownloadFiles
    ) else (
        echo Operation cancelled by user.
        :: Create a temporary VBScript file for Error
        echo x=msgbox("Installation failed.", 0+16, "Error") > %temp%\msg.vbs
        wscript.exe %temp%\msg.vbs
        del %temp%\msg.vbs
        exit
    )
)




:ExtractFiles
echo ExtractFiles: Extracting files.

:: Extract the ZIP file
powershell -Command "Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_DIR%' -Force"

:: Find the extracted folder (it will be MAT-main or similar)
for /d %%i in ("%TEMP_DIR%\MAT-*") do (
    set "EXTRACTED_FOLDER=%%i"
)

:: Move files from extracted folder to MAT folder
echo Moving files to %INSTALL_DIR%.
xcopy /E /I /Y "%EXTRACTED_FOLDER%\*" "%INSTALL_DIR%"

:: Clean up temp files
echo Cleaning up temporary files.
del "%TEMP_ZIP%" 2>nul
rmdir /S /Q "%TEMP_DIR%" 2>nul



:ProcessFiles
echo ProcessFiles: Checking and installing certificate, unblocking executable.

:: Find and install the certificate file
if exist "%CERT_PATH%" (
    echo Checking for certificate installation.
 
    :: Get thumbprint and check store
    @REM powershell -Command "$thumb = (Get-PfxCertificate -FilePath '%CERT_PATH%').Thumbprint; if (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumb }) { exit 0 } else { exit 1 }"

    :: Bug fix: Use Get-PfxCertificate to read the .cer file and get the thumbprint, then check if it exists in the store.
    powershell -Command "$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_PATH%'); $thumb = $cert.Thumbprint; if (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumb }) { exit 0 } else { exit 1 }"

    if %ERRORLEVEL% EQU 0 (
        echo Certificate is already installed.
    ) else (
        echo Installing certificate.
        powershell -Command "$cert = Import-Certificate -FilePath '%CERT_PATH%' -CertStoreLocation Cert:\LocalMachine\My"
        echo Certificate installed successfully.
    )
) else (
    echo Certificate file not found at %CERT_PATH%.
    goto :DownloadFiles
)

:: Find and unblock MAT.exe
if exist "%EXE_PATH%" (
    echo Unblocking MAT.exe.
    powershell -Command "Unblock-File -Path '%EXE_PATH%'" 2>nul
    echo File unblocked successfully.
) else (
    echo MAT.exe not found at %MAT_PATH%.
    goto :DownloadFiles
)


:: Create a temporary VBScript file
echo x=msgbox("Installation completed successfully!", 0+64, "Success") > %temp%\msg.vbs
:: Execute it
wscript.exe %temp%\msg.vbs
:: Delete the temporary file
del %temp%\msg.vbs

pause
@echo off
setlocal enabledelayedexpansion



set "REPO_NAME=MAT"
set "REPO_OWNER=acotales"

set "BASE_DIR=%cd%\%REPO_NAME%"
set "ASSETS_DIR=%BASE_DIR%\assets"
set "TEMP_DIR=%BASE_DIR%\temp"

set "EXE_PATH=%BASE_DIR%\%REPO_NAME%.exe"
set "TEMP_ZIP=%TEMP_DIR%\%REPO_NAME%.zip"
set "CERT_PATH=%ASSETS_DIR%\certificate.cer"

set "NULL="
set "ZIP_URL=ht%NULL%tps://git%NULL%hub.com/%REPO_OWNER%/%REPO_NAME%/archive/refs/heads/main.zip"
set "API_URL=ht%NULL%tps://api.git%NULL%hub.com/repos/%REPO_OWNER%/%REPO_NAME%/releases/latest"

set missing_files=0

if exist "%BASE_DIR%" (
    if exist "%EXE_PATH%" (
        if exist "%ASSETS_DIR%\app.ico" (
            if exist "%ASSETS_DIR%\certificate.cer" (
                if exist "%ASSETS_DIR%\aio.cmd" (
                    goto :StartProcess
                )
            )
        )
    )
) else (
    if not exist %BASE_DIR% mkdir %BASE_DIR%
    if not exist %ASSETS_DIR% mkdir %ASSETS_DIR%
    if not exist %TEMP_DIR% mkdir %TEMP_DIR%
    goto :DownloadFiles
)


:DownloadFiles
echo Downloading files...

powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { $release = Invoke-RestMethod -Uri '%API_URL%'; $asset = $release.assets | Where-Object { $_.name -like '*.exe' } | Select-Object -First 1; if ($asset) { Invoke-WebRequest -Uri $asset.browser_download_url -OutFile \"%EXE_PATH%\"; exit 0 } else { exit 2 } } catch { exit 1 }"

if %errorlevel% gtr 0 (
    set /a missing_files+=1
    if %errorlevel% equ 1 (
        echo Network or GitHub API failure. Please check internet connection.
    ) else (
        echo No .exe file found in the latest release.
    )
)
echo Error Level (Download .exe): %errorlevel%

powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%TEMP_ZIP%'; exit 0 } catch { exit 1 }"

if %errorlevel% gtr 0 (
    set /a missing_files+=1
    echo Failed to download GitHub repository.
)
echo Error Level (Download .zip): %errorlevel%

if %missing_files% gtr 0 (
    echo ERROR: Failed to run the application. Exiting.
    exit /b 1
) else (
    if exist "%TEMP_ZIP%" (
        echo Extracting the downloaded zip file...
        powershell -Command "$ProgressPreference = 'SilentlyContinue'; try { Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%TEMP_DIR%' -Force; exit 0 } catch { exit 1}"
        
        echo Copying required files...
        for /r "%TEMP_DIR%" %%f in (aio.cmd certificate.cer app.ico) do (
            if exist "%%f" (
                xcopy /Y "%%f" "%ASSETS_DIR%\" >nul 2>&1
            )
        )

        echo Deleting the zip file...
        del "%TEMP_ZIP%" 2>nul

        echo Deleting temp folder...
        rmdir /S /Q "%TEMP_DIR%" 2>nul

        goto :StartProcess

    ) else (
        echo ERROR: No zip file found. Exiting.
        exit /b 1
    )
)


:StartProcess
echo Starting process...

if exist "%CERT_PATH%" (
    echo Checking certificate file installation.
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2('%CERT_PATH%'); $thumb = ($cert.Thumbprint -replace '\s','').ToUpperInvariant(); if (Get-ChildItem 'Cert:\\LocalMachine\\My' | Where-Object { ($_.Thumbprint -replace '\s','').ToUpperInvariant() -eq $thumb }) { exit 0 } else { exit 1 }"

    if %errorlevel% equ 0 (
        echo Certificate is already installed.
    ) else (
        echo Certificate is not installed.
        powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Import-Certificate -FilePath '%CERT_PATH%' -CertStoreLocation 'Cert:\LocalMachine\My' | Out-Null ; exit 0 } catch { exit 1 }"
        
        if %errorlevel% gtr 0 (
            echo Certificate successfully installed.
        )
    )
)

if exist "%EXE_PATH%" (
    echo Running application.
    start "" "%EXE_PATH%"
)

exit /b 0

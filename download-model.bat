@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "MODEL_ROOT=D:\local-model"
set "RUNTIME_DIR=%MODEL_ROOT%\runtime"
set "MODEL_DIR=%MODEL_ROOT%\models"
set "RUNTIME_ZIP=%RUNTIME_DIR%\llama-b10298-bin-win-cpu-x64.zip"
set "MODEL_FILE=%MODEL_DIR%\Qwen2.5-0.5B-Instruct-Q4_K_M.gguf"
if not defined LLAMA_URL set "LLAMA_URL=https://github.com/ggml-org/llama.cpp/releases/download/b10298/llama-b10298-bin-win-cpu-x64.zip"
if not defined MODEL_URL set "MODEL_URL=https://hf-mirror.com/bartowski/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/Qwen2.5-0.5B-Instruct-Q4_K_M.gguf"

where curl.exe >nul 2>nul
if errorlevel 1 (
  echo ERROR: curl.exe was not found.
  pause
  exit /b 1
)

rem Remove only the interrupted BITS jobs created by earlier versions of this setup.
powershell.exe -NoProfile -Command "Get-BitsTransfer -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -in 'Qwen2.5-0.5B GGUF','llama.cpp Windows CPU runtime' } | Remove-BitsTransfer -ErrorAction SilentlyContinue"

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"
if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%"

set "LLAMA_SERVER="
for /r "%RUNTIME_DIR%" %%F in (llama-server.exe) do set "LLAMA_SERVER=%%F"
if not defined LLAMA_SERVER (
  echo Downloading llama.cpp Windows CPU runtime...
  call :download "%LLAMA_URL%" "%RUNTIME_ZIP%"
  if errorlevel 1 (
    echo ERROR: Runtime download failed. Run this script again to resume.
    pause
    exit /b 1
  )

  echo Extracting runtime...
  powershell.exe -NoProfile -Command "Expand-Archive -LiteralPath '%RUNTIME_ZIP%' -DestinationPath '%RUNTIME_DIR%' -Force"
  if errorlevel 1 (
    echo ERROR: Runtime extraction failed.
    pause
    exit /b 1
  )
)

set "LLAMA_SERVER="
for /r "%RUNTIME_DIR%" %%F in (llama-server.exe) do set "LLAMA_SERVER=%%F"
if not defined LLAMA_SERVER (
  echo ERROR: llama-server.exe was not found after extraction.
  pause
  exit /b 1
)

set "MODEL_SIZE=0"
if exist "%MODEL_FILE%" for %%F in ("%MODEL_FILE%") do set "MODEL_SIZE=%%~zF"
if !MODEL_SIZE! LSS 300000000 (
  echo Downloading or resuming Qwen2.5-0.5B Q4_K_M model...
  call :download "%MODEL_URL%" "%MODEL_FILE%"
  if errorlevel 1 (
    echo ERROR: Model download failed. Run this script again to resume.
    pause
    exit /b 1
  )
)

for %%F in ("%MODEL_FILE%") do set "MODEL_SIZE=%%~zF"
if !MODEL_SIZE! LSS 300000000 (
  echo ERROR: Model file is incomplete. Run this script again to resume.
  pause
  exit /b 1
)

echo.
echo Download complete.
echo Runtime: %LLAMA_SERVER%
echo Model:   %MODEL_FILE%
pause
exit /b 0

:download
set "URL=%~1"
set "TARGET=%~2"
set "TARGET_DIR=%~dp2"
if "%TARGET_DIR:~-1%"=="\" set "TARGET_DIR=%TARGET_DIR:~0,-1%"
set "ARIA2="
for /f "delims=" %%F in ('where aria2c.exe 2^>nul') do if not defined ARIA2 set "ARIA2=%%F"
if not defined ARIA2 if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\aria2c.exe" set "ARIA2=%LOCALAPPDATA%\Microsoft\WinGet\Links\aria2c.exe"
if not defined ARIA2 for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%F in (aria2c.exe) do if not defined ARIA2 set "ARIA2=%%F"
if defined ARIA2 (
  echo Using aria2c with 8 connections and resume support...
  "%ARIA2%" --continue=true --max-connection-per-server=8 --split=8 --min-split-size=1M --file-allocation=none --dir "%TARGET_DIR%" --out "%~nx2" "%URL%"
  exit /b !errorlevel!
)

echo aria2c was not found. Falling back to single-connection curl.
curl.exe --fail --location --retry 20 --retry-delay 5 --continue-at - --output "%TARGET%" "%URL%"
exit /b !errorlevel!

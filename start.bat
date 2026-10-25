@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "ROOT=%~dp0"
set "MODEL_ROOT=D:\local-model"
set "RUNTIME_DIR=%MODEL_ROOT%\runtime"
set "MODEL_FILE=%MODEL_ROOT%\models\Qwen2.5-0.5B-Instruct-Q4_K_M.gguf"

where node >nul 2>nul
if errorlevel 1 (
  echo ERROR: Node.js 20 or newer is required.
  pause
  exit /b 1
)

for /f %%V in ('node -p "process.versions.node.split('.')[0]"') do set "NODE_MAJOR=%%V"
if !NODE_MAJOR! LSS 20 (
  echo ERROR: Node.js 20 or newer is required.
  pause
  exit /b 1
)

if not exist "%MODEL_FILE%" (
  echo ERROR: Model not found. Run download-model.bat first.
  pause
  exit /b 1
)

for %%F in ("%MODEL_FILE%") do set "MODEL_SIZE=%%~zF"
if !MODEL_SIZE! LSS 300000000 (
  echo ERROR: Model file is incomplete. Run download-model.bat again to resume.
  pause
  exit /b 1
)

set "LLAMA_SERVER="
for /r "%RUNTIME_DIR%" %%F in (llama-server.exe) do set "LLAMA_SERVER=%%F"
if not defined LLAMA_SERVER (
  echo ERROR: llama-server.exe not found. Run download-model.bat first.
  pause
  exit /b 1
)

netstat -ano | findstr /r /c:":8080 .*LISTENING" >nul
if errorlevel 1 (
  start "llama.cpp" /D "%RUNTIME_DIR%" cmd /k call "%LLAMA_SERVER%" -m "%MODEL_FILE%" --alias qwen2.5-0.5b-instruct --port 8080 -c 2048 -ngl 0
)

start "Next.js API" /D "%ROOT%ai-backend-nextjs" cmd /k call npm run dev
start "Vue frontend" /D "%ROOT%ai-frontend-vue3" cmd /k call npm run dev

echo Started llama.cpp, Next.js, and Vue in separate windows.
echo Open http://localhost:5173 after the model finishes loading.
pause
exit /b 0

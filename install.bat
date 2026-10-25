@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "ROOT=%~dp0"
set "npm_config_cache=%ROOT%.npm-cache"

where node >nul 2>nul
if errorlevel 1 (
  echo ERROR: Node.js 20 or newer is required.
  pause
  exit /b 1
)

for /f %%V in ('node -p "process.versions.node.split('.')[0]"') do set "NODE_MAJOR=%%V"
if !NODE_MAJOR! LSS 20 (
  echo ERROR: Node.js 20 or newer is required. Current major version: !NODE_MAJOR!
  pause
  exit /b 1
)

echo Installing Next.js backend dependencies...
pushd "%ROOT%ai-backend-nextjs"
call npm install --no-audit --no-fund
if errorlevel 1 (
  popd
  echo ERROR: Backend dependency installation failed.
  pause
  exit /b 1
)
if not exist ".env.local" copy ".env.example" ".env.local" >nul
popd

echo Installing Vue frontend dependencies...
pushd "%ROOT%ai-frontend-vue3"
call npm install --no-audit --no-fund
if errorlevel 1 (
  popd
  echo ERROR: Frontend dependency installation failed.
  pause
  exit /b 1
)
if not exist ".env" copy ".env.example" ".env" >nul
popd

echo.
echo Dependencies installed and environment files are ready.
echo Run download-model.bat, then run start.bat.
pause
exit /b 0

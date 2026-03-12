@echo off
setlocal

cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File ".\scripts\verify-rls-isolation.ps1" -Cleanup
set EXIT_CODE=%ERRORLEVEL%

echo.
if %EXIT_CODE%==0 (
  echo RLS isolation check passed.
) else (
  echo RLS isolation check failed. Exit code: %EXIT_CODE%
)

pause
exit /b %EXIT_CODE%

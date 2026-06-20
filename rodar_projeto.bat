@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\launchers\launcher_grid_2x2.ps1" -Mode startup_safe -DryRun

echo.
echo ============================================================
echo Lancador finalizado. Esta janela pode ser fechada.
echo ============================================================
pause
endlocal

@echo off
wevtutil sl Microsoft-Windows-SleepStudy/Diagnostic /q:true
wevtutil sl Microsoft-Windows-Kernel-Processor-Power/Diagnostic /q:true
wevtutil sl Microsoft-Windows-UserModePowerService/Diagnostic /q:true
reg add "HKLM\SYSTEM\ControlSet001\Services\DPS" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\diagsvc" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\WdiServiceHost" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\WdiSystemHost" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
goto :EOF
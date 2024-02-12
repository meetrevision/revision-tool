@echo off
set "services=HKLM\SYSTEM\ControlSet001\Services"
::Windows Defender
reg add "%services%\MsSecCore" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "%services%\MsSecFlt" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "%services%\MsSecWfp" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\SecurityHealthService" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\Sense" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\WdBoot" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "%services%\WdFilter" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "%services%\WdNisDrv" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\WdNisSvc" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\WinDefend" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg add "%services%\wscsvc" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg add "%services%\MDCoreSvc" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
::WindowsSystemTray
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SecurityHealth" /t REG_EXPAND_SZ /d "%systemroot%\system32\SecurityHealthSystray.exe" /f >NUL 2>nul
::SystemGuard
reg add "%services%\SgrmAgent" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "%services%\SgrmBroker" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
::WebThreatDefSvc
reg add "%services%\webthreatdefsvc" /v "Start" /t REG_DWORD /d "3" /f >NUL 2>nul
reg add "%services%\webthreatdefusersvc" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
for /f %%i in ('reg query "%services%" /s /k "webthreatdefusersvc" /f 2^>nul ^| find /i "webthreatdefusersvc" ') do (
  reg add "%%i" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
)


::SmartScreen
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\smartscreen.exe" /f >NUL 2>nul
for %%j in (
	"%systemroot%\system32\smartscreen.exe"
) do (
	if not exist %%j if exist "%%j.revi" ren "%%j.revi" "smartscreen.exe" >NUL 2>nul
)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /f >NUL 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "On" /f >NUL 2>nul
reg delete "HKLM\Software\Policies\Microsoft\System" /v "EnableSmartScreen" /f >NUL 2>nul

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >NUL 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "PreventOverride" /f >NUL 2>nul
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >NUL 2>nul

::Smart App Control
reg delete "HKLM\SYSTEM\ControlSet001\Control\CI\Policy" /v "VerifiedAndReputablePolicyState" /f >NUL 2>nul

:: Remove Defender policies
reg delete "HKLM\Software\Policies\Microsoft\Windows Defender" /f >NUL 2>nul
reg delete "HKLM\Software\Policies\Microsoft\Windows Advanced Threat Protection" /f >NUL 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center" /f >NUL 2>nul

::Configure detection for potentially unwanted applications
reg add "HKLM\Software\Microsoft\Windows Defender" /v "PUAProtection" /t REG_DWORD /d "1" /f >NUL 2>nul

::Device Security
reg delete "HKLM\SYSTEM\ControlSet001\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /f >NUL 2>nul
reg delete "HKLM\SYSTEM\ControlSet001\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /f >NUL 2>nul


goto :EOF
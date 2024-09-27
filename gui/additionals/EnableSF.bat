@echo off
::ReadyBoost
reg add "HKLM\SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "fvevol\0iorate\0rdyboost" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\rdyboost" /v "Start" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\SysMain" /v "Start" /t REG_DWORD /d "2" /f >NUL 2>nul
reg delete "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /f >NUL 2>nul
for /f %%i in ('PowerShell -NonInteractive -NoLogo -NoP -C "(Get-PhysicalDisk -SerialNumber (Get-Disk -Number (Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1)).DiskNumber).SerialNumber.TrimStart()).MediaType"') do set "hardDrive=%%i"
if "%hardDrive%"=="HDD" (
  reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d "3" /f >NUL 2>nul
)
reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "3" /f >NUL 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "GroupPolicyDisallowCaches" /f >NUL 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "AllowNewCachesByDefault" /f >NUL 2>nul
goto :EOF
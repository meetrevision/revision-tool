@echo off
::ReadyBoost
sc stop SysMain >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Control\Class\{71a27cdd-812a-11d0-bec7-08002be2092f}" /v "LowerFilters" /t REG_MULTI_SZ /d "fvevol\0iorate" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\SysMain" /v "Start" /t REG_DWORD /d "4" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Services\rdyboost" /v "Start" /t REG_DWORD /d "4" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f >NUL 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "GroupPolicyDisallowCaches" /t REG_DWORD /d "1" /f >NUL 2>nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EMDMgmt" /v "AllowNewCachesByDefault" /t REG_DWORD /d "0" /f >NUL 2>nul
::PowerShell -NonInteractive -NoLogo -NoProfile -Command "Disable-MMAgent -mc" >NUL 2>nul
::reg add "HKLM\SYSTEM\ControlSet001\Control\Session Manager\Memory Management\PrefetchParameters" /v "isMemoryCompressionEnabled" /t REG_DWORD /d "0" /f
goto :EOF
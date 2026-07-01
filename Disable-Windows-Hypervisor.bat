@echo off
title Disable Hyper-V & Virtualization Security
color 0C
echo ===================================================
echo   DISABLE HYPER-V & VIRTUALIZATION SECURITY
echo ===================================================
echo.
echo This will disable:
echo   - Hyper-V
echo   - Virtual Machine Platform
echo   - Windows Hypervisor Platform
echo   - VBS (Virtualization-Based Security)
echo   - HVCI (Memory Integrity)
echo   - Credential Guard
echo   - Device Guard
echo   - Hyper-V Services
echo.
echo WARNING: This will BREAK WSL2 and Docker Desktop!
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b
)

echo.
echo ===================================================
echo STEP 1: Disabling Windows Features
echo ===================================================

echo Disabling Microsoft-Hyper-V-All...
dism /online /disable-feature /featurename:Microsoft-Hyper-V-All /norestart

echo Disabling Microsoft-Hyper-V...
dism /online /disable-feature /featurename:Microsoft-Hyper-V /norestart

echo Disabling HypervisorPlatform...
dism /online /disable-feature /featurename:HypervisorPlatform /norestart

echo Disabling VirtualMachinePlatform...
dism /online /disable-feature /featurename:VirtualMachinePlatform /norestart

echo Disabling Microsoft-Windows-Subsystem-Linux...
dism /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart

echo Disabling Containers...
dism /online /disable-feature /featurename:Containers /norestart

echo.
echo ===================================================
echo STEP 2: Disabling Hypervisor Boot
echo ===================================================

bcdedit /set hypervisorlaunchtype off
bcdedit /set vsmlaunchtype off

echo.
echo ===================================================
echo STEP 3: Disabling VBS via Registry
echo ===================================================

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f

echo.
echo ===================================================
echo STEP 4: Disabling HVCI (Memory Integrity)
echo ===================================================

reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f

echo.
echo ===================================================
echo STEP 5: Disabling Credential Guard
echo ===================================================

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f

echo.
echo ===================================================
echo STEP 6: Disabling Device Guard
echo ===================================================

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v HypervisorEnforcedCodeIntegrity /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f

echo.
echo ===================================================
echo STEP 7: Stopping Hyper-V Services
echo ===================================================

sc stop vmcompute 2>nul
sc stop vmms 2>nul
sc config vmcompute start= disabled 2>nul
sc config vmms start= disabled 2>nul

echo.
echo ===================================================
echo STEP 8: Status Check
echo ===================================================

echo.
echo Current Hypervisor Configuration:
bcdedit | findstr hypervisorlaunchtype

echo.
echo ===================================================
echo COMPLETED!
echo ===================================================
echo.
echo A SYSTEM REBOOT IS REQUIRED!
echo.
set /p reboot="Reboot now? (Y/N): "
if /i "%reboot%"=="Y" (
    echo Rebooting in 5 seconds...
    timeout /t 5 /nobreak
    shutdown /r /t 0
) else (
    echo Please reboot manually for changes to take effect.
    pause
)
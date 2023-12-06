@echo off
rem PURPOSE: 	This bat is designed to download and install zscaler client connector automatically for govcloud tenants
rem LIMITS:	This file will not handle EXE installs and is suitible for Windows only. Not intended for VDI either
rem DISCLAIMER: This script is provided without any warrant or guarantee of its functionality. Use at your own risk.
rem CREDIT: 	bradley.cooper@zscaler.com
rem VERSION:	2023.09.06

rem	vvvv READ THIS vvvv

rem https://help.zscaler.us/client-connector/customizing-zscaler-client-connector-install-options-msi#RunZAppMSICmdLine

rem	^^^^ READ THIS ^^^^

rem	--- FILL THESE PARAMETERS OUT ---

rem ZClient Connector download URL. Links can be found in your client connector admin portal. MSI ONLY
rem DO NOT INCLUDE ANY URL QUERY STRINGS, i.e. ?q=what+am+i&lang=en
rem EXAMPLE: https://dist.zpagov.net/dist/zapp/Zscaler-windows-4.1.0.102-installer-x64.msi
	set ZClientInstallerURL=setme

rem cloud name of tenant, i.e. "zscalergov" (legacy) -or- "zscalerten" (GCC high) -or- "mod.zscalergov" (GCC mod)
	set CLOUDNAME=setme

rem SSO IDP primary domain of tenant, i.e. agency.gov. Also used with Integrated Windows Authentication (IWA)
	set USERDOMAIN=setme

rem	--- OPTIONAL PARAMETERS ---

rem blocks internet traffic until user logs in. "1" enables feature. "0" is default and disabled
	set STRICTENFORCEMENT=0

rem policy token for preinstallation of app profile policy. blank is default value 
	set POLICYTOKEN=

rem TROUBLESHOOTING ONLY. force reinstall driver if issues suspected. "1" enables feature. "0" is default and disabled
	set REINSTALLDRIVER=0

rem Quiet install parameter to display the install wizard window. "1" is default and enables feature. "0" will turn off this feature
	set QUIETMODE=1

rem	--- END OF PARAMETERS ---
rem	--- START OF AUTOMATION DO NOT EDIT ---

rem check to ensure required parameters are filled out
if %ZClientInstallerURL%==setme (
	echo ZClientInstallerURL not set
	exit /b 0
)
if %CLOUDNAME%==setme (
	echo CLOUDNAME not set
	exit /b 0
) 
if %USERDOMAIN%==setme (
	echo USERDOMAIN not set
	exit /b 0
)

rem Extract the filename from the URL. Will break if URL is not simple.
for %%A in ("%ZClientInstallerURL%") do set "msiPath=%%~nxA"

rem check if installer file already exists
if not exist "%msiPath%" (
	
	rem check for wget and download
	where wget > nul 2>&1
	if %errorlevel% equ 0 (
		echo Downloading Zscaler Client Connector installer using wget...
		wget -o %msiPath% %ZClientInstallerURL%
		set downloaded = "true"
	)	
	rem no wget found so check for curl and download
	if not defined downloaded (
		where curl > nul 2>&1
		if %errorlevel% equ 0 (
			echo Downloading Zscaler Client Connector installer using curl...
			curl -o %msiPath% %ZClientInstallerURL%
		) else (
        echo ERROR: 'wget' and 'curl' not available to download Zscaler Client Connector.
        exit /b 1
		)
	)  
) else ( echo Zscaler Client Connector file already downloaded. %msiPATH% )

rem construct the options variable to pass to the install command.
if %QUIETMODE%==1 (
	set QUIET=/quiet
) else (
	set QUIET=
)
set "options=%QUIET% CLOUDNAME=%CLOUDNAME% POLICYTOKEN=%POLICYTOKEN% STRICTENFORCEMENT=%STRICTENFORCEMENT% USERDOMAIN=%USERDOMAIN% REINSTALLDRIVER=%REINSTALLDRIVER%"

rem Install Zscaler Client Connector with org parameters
echo installing Zscaler Client Connector...
msiexec /i %msiPath% %options%

rem Check the exit code of msiexec
if %errorlevel% equ 0 (
    echo Zscaler Client Connecotr installation completed successfully.
    exit /b 0
) else if %errorlevel% equ 1603 (
    echo Installation failed. Another installation is in progress.
    exit /b 1603
) else if %errorlevel% equ 3010 (
    echo Installation completed successfully but requires a reboot.
    exit /b 3010
) else (
    echo Installation failed with error code: %errorlevel%
    exit /b %errorlevel%
)
rem 	--- END OF AUTOMATION ---
rem 	--- END OF SCRIPT ---

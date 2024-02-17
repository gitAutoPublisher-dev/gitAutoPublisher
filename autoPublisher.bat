@echo off
:: Basic settings
set tempFile=%temp%\regTemp.txt
set localhost=127.0.0.1
set gitIP=github.com
set schtaskName=autoPublisherTimer
set ver=autoPublisher v2.4.4
title %ver% running...
echo Welcome to use %ver%
:: Go to target direction
cd /d %~dp0
:: Read register config
echo .>%tempFile%
reg query HKCU\Software\autoPublisher /v routerIP > %tempFile% 2>nul
if %errorlevel%==0 (
	for /f "tokens=3" %%i in (%tempFile%) do set routerIP=%%i
	set noRIP=0
) else (
	set noRIP=1
)
reg query HKCU\Software\autoPublisher /v schTask > %tempFile% 2>nul
if %errorlevel%==0 (
	for /f "tokens=3" %%i in (%tempFile%) do set noTask=%%i
) else (
	set noTask=0
)
:: Network status check
echo Checking network status....
:: Network local status check
ping %localhost% -n 1 2>nul>nul
if %errorlevel%==0 (
	echo Current network status [Local]: Normal
) else (
	echo Current network status [Local]: Abnormal
	echo Error: The computer does not have the network function enabled / %ver% does not have the ability to access the network
	echo And the push process is refused
	goto exit
)
:: Network router status check
if noRIP==0 (
	choice /c YN /t 10 /d N /n /m "Current router IP address: %routerIP%, please confirm whether to change the router IP address, yes Y, no N"
	if %errorlevel%==2 goto rcheck
)
set /p routerIP=Please enter your router IP address (default: 192.168.0.1): 
if not defined routerIP set routerIP=192.168.0.1
:rcheck
ping %routerIP% -n 1 2>nul>nul
if %errorlevel%==0 (
	echo Current network status [Router]: Normal
) else (
	echo Current network status [Router]: Abnormal
	echo Error: %ver% can not access network and the push process is refused
	goto exit
)
:: Network github status check
ping %gitIP% -n 1 2>nul>nul
if %errorlevel%==0 (
	echo Current network status [Github]: Normal
	goto gsc
) else (
	echo Current network status [Github]: Abnormal
	echo Error: %ver% can not access github and the push process is refused
	goto exit
)
:: Git status check
:gsc
git status 2>nul>nul
if %errorlevel%==0 (
	echo Current repository status: Normal
	goto task
) else (
	echo Current repository status: Abnormal
	echo Error: The repository does not exist and the push process is refused
	goto exit
)
:: Schtask status check
:task
schtasks /query /tn %schtaskName% 2>nul>nul
if %errorlevel%==0 (
	echo Current schtask status: Normal
	goto choose
) else (
	echo Current schtask status: Abnormal
	goto schtask
)
:: Schtask config
:schtask
if noTask==1 goto choose
choice /c YN /t 10 /d Y /n /m "Please confirm whether to create scheduled task, yes Y, no N"
if %errorlevel%==2 (
	set noTask=1
	goto choose
)
set /p t=Please enter your expected scheduled task execution time per day(24 hours) (default: 18): 
if not defined t set t=18
schtasks /create /tn %schtaskName% /sc DAILY /st %t%:00 /tr %0 2>nul>nul
:: Push confirm
:choose
choice /c YN /t 10 /d Y /n /m "Please confirm whether to push, yes Y, no N"
if %errorlevel%==2 goto exit
:: Initialization
title %ver% initializing...
echo Initializing...
timeout /t 5 /nobreak 2>nul>nul
echo Initialization complete, starting push process...
:: Push
title %ver% pushing...
echo Adding all changes...
git add .
echo Commiting all changes...
git commit -m "Push by autoPublisher: %date:~0,10%,%time:~0,8%" 2>nul>nul
echo Merging all remote changes to local...
git pull 2>nul>nul 
echo Pushing all local changes to remote...
git push 2>nul>nul
echo Push process has ended
title %ver% push completed!
:: Save register config
reg add HKCU\Software\autoPublisher /v routerIP /t REG_SZ /d routerIP /f
reg add HKCU\Software\autoPublisher /v schTask /t REG_DWORD /d 1 /f
:exit
:: Program end
title %ver% process has ened
echo Thank you for using %ver%
echo Please press any key to continue...
pause 2>nul>nul
exit
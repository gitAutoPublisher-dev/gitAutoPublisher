@echo off
:: Echo version
set ver=autoPublisher v2.4.8
if "%1"=="-?" (
    echo Usage: autoPublisher.bat [-v] [-c] [-s]
    echo -v: Show the version of gitAutoPublisher
    echo -c: Show the contributors of gitAutoPublisher
    echo -s: Show the sponsors of gitAutoPublisher
    exit /b 0
)
if "%1"=="-v" (
    echo Version: %ver%
    exit /b 0
)
if "%1"=="-c" (
    echo Contributors: Nightingale0504, YUCLing
    exit /b 0
)
if "%1"=="-s" (
    echo Sponsors: None
    exit /b 0
)
:: Basic settings
set tempFile=%temp%\regTemp.txt
set gitIP=github.com
set schtaskName=autoPublisherTimer
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
    set noTask=1
) else (
    set noTask=0
)
:: Register config check
echo Checking register config....
:: Register routerIP check
if %noRIP%==1 (
    echo Register config [routerIP]: Not found
) else (
    echo Register config [routerIP]: %routerIP%
)
:: Register schTask check
if %noTask%==0 (
    echo Register config [schTask]: Not found
) else (
    echo Register config [schTask]: Found
)
:: Network status check
echo Checking network status....
:: Network local status check
ping localhost -n 1 2>nul>nul
if %errorlevel%==0 (
    echo Current network status [Local]: Normal
) else (
    echo Current network status [Local]: Abnormal
    echo Error: The computer does not have the network function enabled / %ver% does not have the ability to access the network
    echo And the push process is refused
    goto exit
)
:: Network router status check
if %noRIP%==1 goto lcheck
echo Current router IP address: %routerIP%
choice /c YN /t 10 /d N /n /m "Please confirm whether to change the router IP address, yes Y, no N"
if %errorlevel%==2 goto rcheck
:lcheck
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
if %noTask%==1 goto choose
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
echo Initializing...
timeout /t 5 /nobreak 2>nul>nul
echo Initialization complete, starting push process...
:: Push
echo Adding all changes...
git add .
echo Committing all changes...
git commit -m "Push by autoPublisher: %date:~0,10%,%time:~0,8%" 2>nul>nul
echo Merging all remote changes to local...
git pull 2>nul>nul 
echo Pushing all local changes to remote...
git push 2>nul>nul
echo Push process has ended
:: Save register config
reg add HKCU\Software\autoPublisher /v routerIP /t REG_SZ /d %routerIP% /f 2>nul>nul
reg add HKCU\Software\autoPublisher /v schTask /t REG_DWORD /d 1 /f 2>nul>nul
:exit
:: Program end
echo Thank you for using %ver%
del %tempFile% /q 2>nul>nul
echo Please press any key to continue...
pause 2>nul>nul
cls
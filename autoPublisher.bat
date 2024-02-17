@echo off
:: Basic settings
set schtaskName=autoPublisherTimer
set ver=autoPublisher v2.4.2
title %ver% running...
echo Welcome to use %ver%
:: Go to target direction
cd /d %~dp0
:: Git status check
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
choice /c YN /t 10 /d Y /n /m "Please confirm whether to create scheduled task, yes Y, no N"
if %errorlevel%==2 goto choose
echo Please enter your expected scheduled task execution time per day(24 hours):
set /p t=
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
echo Pushing all local changes to ::ote...
git push 2>nul>nul
echo Push process has ended
title %ver% push completed!
:exit
:: Program end
title %ver% process has ened
echo Thank you for using %ver%
echo Please press any key to continue
pause 2>nul>nul
cls
@echo off

@REM build cmake project
setlocal enableextensions

@REM Make sure Windows is correctly using UTF-8 (Visual Studio in German locale)
chcp 65001

cd "%~dp0"
set PWD="%cd%"

REM ###############################################################
set X11_BASE_ROOT=%PWD%
set ACE_ROOT=%X11_BASE_ROOT%\ACE\ACE
set TAO_ROOT=%X11_BASE_ROOT%\ACE\TAO
set TAOX11_ROOT=%X11_BASE_ROOT%\taox11

set MPC_BASE=%TAOX11_ROOT%\bin\MPC
set MPC_ROOT=%X11_BASE_ROOT%\ACE\MPC

set RIDL_BE_PATH=;%TAOX11_ROOT%
set RIDL_BE_SELECT=c++11
set RIDL_ROOT=%X11_BASE_ROOT%\ridl\lib
REM ###############################################################

where ruby python perl cmake git

REM see etc/brix11rc
if not exist taox11 goto :bootstrap
if not exist ridl goto :bootstrap
if not exist ACE goto :bootstrap
if not exist ACE/MPC goto :bootstrap
ruby bin/brix11 --show-config
goto :build

:bootstrap
ruby bin/brix11 bootstrap

:build
@echo ON
if "%VCINSTALLDIR%"=="" (
  @echo Setup the build environment ...
  call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
  if %errorlevel% neq 0 (
    @echo Error: Build Environment for MSVC 14.3x could not be set!
    pause
    exit /b 1
  )
)

ruby %X11_BASE_ROOT%/bin/brix11 -t vs2022 configure -W aceroot=%ACE_ROOT% -W taoroot=%TAO_ROOT% -W mpcroot=%MPC_ROOT%
ruby %X11_BASE_ROOT%/bin/brix11 env -- configure -P > configure.log
type configure.log
ruby bin/brix11 env > .setenv.bat

builddriver ruby %X11_BASE_ROOT%/bin/brix11 gen build workspace.mwc -- gen build %TAOX11_ROOT%/examples -- gen build %TAOX11_ROOT%/orbsvcs/tests -- gen build %TAOX11_ROOT%/tests
if errorlevel 1 goto :error

builddriver ruby %X11_BASE_ROOT%/bin/brix11 make --release -N %X11_BASE_ROOT% -- make --release -N %TAOX11_ROOT%/examples -- make --release -N %TAOX11_ROOT%/orbsvcs/tests -- make --release -N %TAOX11_ROOT%/tests
if errorlevel 1 goto :error

:: export PATH="$X11_BASE_ROOT/bin:$X11_BASE_ROOT/lib:$TAOX11_ROOT/bin:$ACE_ROOT/bin:$ACE_ROOT/lib:$PATH"
set PATH="%X11_BASE_ROOT%\bin;%X11_BASE_ROOT%\lib;%TAOX11_ROOT%\bin;%ACE_ROOT%\bin;%ACE_ROOT%\lib;%PATH%"
cmake -B build -S . -D CMAKE_BUILD_TYPE=Release --fresh
cmake --build build --target PACKAGE
if errorlevel 1 goto :error

goto :end

:error
@echo "Fatal Error!"
if "%GITLAB_CI%"=="" (
    pause
)
exit /b 1

:end
@echo "Success."
exit /b 0


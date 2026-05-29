@echo off
REM ===========================================================================
REM  build.bat  (lives in grpc\)
REM
REM  Builds the forked grpc_csharp_plugin.exe (with the TCP codegen mode).
REM  Configures CMake first if the build tree doesn't exist yet.
REM
REM  Output: grpc\_build\grpc_csharp_plugin.exe
REM
REM  (Regenerating .cs from .proto is a separate step, not done here.)
REM ===========================================================================
setlocal EnableDelayedExpansion

REM --- Paths (relative to this script, which lives in grpc\) -----------------
set "GRPC=%~dp0"
set "BUILD=%GRPC%_build"

REM --- Locate Visual Studio via vswhere -------------------------------------
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
  echo [ERROR] vswhere not found at "%VSWHERE%".
  exit /b 1
)
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR (
  echo [ERROR] No Visual Studio install with C++ tools found.
  exit /b 1
)

set "VCVARS=%VSDIR%\VC\Auxiliary\Build\vcvars64.bat"
set "CMAKE=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
set "NINJA=%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
set "PLUGIN=%BUILD%\grpc_csharp_plugin.exe"

REM Enter the MSVC x64 environment once (>nul hides vcvars' harmless vswhere probe).
call "%VCVARS%" >nul
if errorlevel 1 ( echo [ERROR] Failed to initialize MSVC environment. & exit /b 1 )

REM --- Configure if needed --------------------------------------------------
if not exist "%BUILD%\build.ninja" (
  echo [INFO] No CMake cache found; configuring grpc ^(this is slow the first time^)...
  "%CMAKE%" -G Ninja -DCMAKE_MAKE_PROGRAM="%NINJA%" -DCMAKE_BUILD_TYPE=Release -DgRPC_BUILD_TESTS=OFF -S "%GRPC%." -B "%BUILD%"
  if errorlevel 1 ( echo [ERROR] CMake configure failed. & exit /b 1 )
)

REM --- Build the plugin ------------------------------------------------------
echo [INFO] Building grpc_csharp_plugin...
"%CMAKE%" --build "%BUILD%" --target grpc_csharp_plugin
if errorlevel 1 ( echo [ERROR] Plugin build failed. & exit /b 1 )

REM --- Verify the exe actually exists (don't trust exit code alone) ----------
if not exist "%PLUGIN%" (
  echo [ERROR] Build reported success but "%PLUGIN%" is missing.
  exit /b 1
)

echo.
echo [OK] Plugin built: %PLUGIN%
endlocal

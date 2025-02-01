@echo off
echo :: Set Visual Studio environment ::
set VCVARS32="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\vcvars32.bat"
if not exist %VCVARS32% echo NOT FOUND: %VCVARS32% && exit /B 1
call %VCVARS32%

@echo off

set FUZIX=trs80-0.4
set FUZIXSYS=%FUZIX%.sys


set SCR=-s:%FUZIXSYS%.scr
set EQU=-e:%FUZIXSYS%.equ

echo :: Extracting secondary bootstrap from boot floppy image ::
JV3Disk -X -I:%FUZIX%\boot.jv3 -O:%FUZIXSYS%.bin -T:29
if errorlevel 1 pause && goto :eof

echo :: Disassembling kernel ::
dasm80 -b0100:%FUZIXSYS%.bin -p:%FUZIXSYS%.prn %SCR% %EQU% -ww --zmac
if errorlevel 1 pause && goto :eof

dasm80 -b0100:%FUZIXSYS%.bin -o:%FUZIXSYS%.dasm %SCR% %EQU% -ww --zmac
if errorlevel 1 pause && goto :eof


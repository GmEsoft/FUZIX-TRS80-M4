@echo off

set FUZIX=trs80-0.3
set FUZIXBOOT=%FUZIX%.boot
set FUZIXHDBOOT=%FUZIX%.hdboot
set FUZIXHDSYS=%FUZIX%.sys

echo :: Creating the new hard disk image %FUZIXHDBOOT%.hd from %FUZIX%.hd ::
copy %FUZIX%.hd %FUZIXHDBOOT%.hd

echo :: Making the hard disk natively bootable,                                 ::
echo :: Adding a cylinder at the end for the secondary bootstrap (floppy image) ::
patch %FUZIXHDBOOT%.hd (D0x08=01;F0x08=00;D0x0B=02;F0x0B=00;D0x1C=CB;F0x1C=CA;D0x1D=00;F0x1D=00)
::                      Autoboot ON       Native boot       One more cylinder
if errorlevel 1 pause && goto :eof

::HardDisk -X -1 -H:* -I:%FUZIXHDBOOT%.hd -O:%FUZIX%.fix.img
echo :: Analyzing new hard disk image ::
HardDisk -A -1 -I:%FUZIXHDBOOT%.hd
if errorlevel 1 pause && goto :eof
::pause

echo :: Extracting first sector from hard disk image ::
HardDisk -X -1 -O:%FUZIXHDBOOT%.bin -I:%FUZIXHDBOOT%.hd -S:1 -N:1
if errorlevel 1 pause && goto :eof

::JV3Disk -X -I:%FUZIX%.jv3 -O:%FUZIX%.img
echo :: Extracting floppy boot sector from boot floppy image ::
JV3Disk -X -I:%FUZIX%.jv3 -O:%FUZIXBOOT%.bin -S:1 -N:1
if errorlevel 1 pause && goto :eof

echo :: Extracting secondary bootstrap from boot floppy image ::
JV3Disk -X -I:%FUZIX%.jv3 -O:%FUZIX%.sys.bin -T:29
if errorlevel 1 pause && goto :eof

set SCR=-s:%FUZIXBOOT%.scr
set EQU=-e:%FUZIXBOOT%.equ

:: echo :: Disassembling floppy boot sector ::
:: dasm80 -b:%FUZIXBOOT%.bin -p:%FUZIXBOOT%.prn %SCR% %EQU%
:: if errorlevel 1 pause && goto :eof

:: dasm80 -b:%FUZIXBOOT%.bin -o:%FUZIXBOOT%.dasm %SCR% %EQU%
:: if errorlevel 1 pause && goto :eof

echo :: Getting ZMAC ::
set ZMAC=zmac\zmac.exe
if not exist %ZMAC% getzmac.sh

echo :: Assembling primary bootstrap ::
%ZMAC% %FUZIXHDBOOT%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof

echo :: Assembling secondary bootstrap ::
%ZMAC% %FUZIXHDSYS%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof

echo :: Writing new hard disk boot sector ::
HardDisk -U -1 -I:build/%FUZIXHDBOOT%.cim -O:%FUZIXHDBOOT%.hd -S:1 -N:1
if errorlevel 1 pause && goto :eof

echo :: Writing new hard disk secondary bootstrap ::
::HardDisk -U -1 -I:%FUZIX%.sys.bin -O:%FUZIXHDBOOT%.hd -T:202 -H:* -N:198
HardDisk -U -1 -I:build/%FUZIXHDSYS%.cim -O:%FUZIXHDBOOT%.hd -T:202 -H:* -N:198
if errorlevel 1 pause && goto :eof

echo :: Copying new hard disk image for FreHD ::
copy %FUZIXHDBOOT%.hd fuzix003

echo :: Starting the emulator
trs80gp_Fuzix_HD_HDBoot.bat

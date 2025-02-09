@echo off

set FUZIX=trs80-0.4
set FUZIXHD=hard4p-0
set FUZIXBOOT=%FUZIX%.boot
set FUZIXHDBOOT=%FUZIX%.hdboot
set FUZIXHDSYS=%FUZIX%.sys

set PAUSE=
if not "%1" == "" set PAUSE=pause

if exist %FUZIX%\%FUZIXHD% goto FUZIX_HD_OK
echo :: Downloading %FUZIX ::
getfuzix_04.sh
if errorlevel 1 pause && goto :eof
%PAUSE%
:FUZIX_HD_OK

echo :: Creating the new hard disk image %FUZIXHDBOOT%.hd from %FUZIX%.hd ::
copy %FUZIX%\%FUZIXHD% %FUZIXHDBOOT%.hd

if exist PAT.EXE goto PATCH_OK
echo :: Building PATCH.EXE ::
call mk_Patch.bat
copy patch.exe pat.exe
if errorlevel 1 pause && goto :eof
%PAUSE%
:PATCH_OK

echo :: Making the hard disk natively bootable,                                 ::
echo :: Adding a cylinder at the end for the secondary bootstrap (floppy image) ::
pat %FUZIXHDBOOT%.hd (D0x08=01;F0x08=00;D0x0B=02;F0x0B=00;D0x1C=CB;F0x1C=CA;D0x1D=00;F0x1D=00)
::                      Autoboot ON       Native boot       One more cylinder
if errorlevel 1 pause && goto :eof
%PAUSE%

if exist HARDDISK.EXE goto HARDDISK_OK
echo :: Building HARDDISK.EXE ::
call mk_HardDisk.bat
if errorlevel 1 pause && goto :eof
%PAUSE%
:HARDDISK_OK

::HardDisk -X -1 -H:* -I:%FUZIXHDBOOT%.hd -O:%FUZIX%.fix.img
echo :: Analyzing new hard disk image ::
HardDisk -A -1 -I:%FUZIXHDBOOT%.hd
if errorlevel 1 pause && goto :eof
%PAUSE%

echo :: Extracting first sector from hard disk image ::
HardDisk -X -1 -O:%FUZIXHDBOOT%.bin -I:%FUZIXHDBOOT%.hd -S:1 -N:1
if errorlevel 1 pause && goto :eof
%PAUSE%

if exist JV3DISK.EXE goto JV3DISK_OK
echo :: Building JV3DISK.EXE ::
call mk_JV3Disk.bat
if errorlevel 1 pause && goto :eof
%PAUSE%
:JV3DISK_OK

::JV3Disk -X -I:%FUZIX%.jv3 -O:%FUZIX%.img
echo :: Extracting floppy boot sector from boot floppy image ::
JV3Disk -X -I:%FUZIX%\boot.jv3 -O:%FUZIXBOOT%.bin -S:1 -N:1
%PAUSE%
if errorlevel 1 pause && goto :eof

echo :: Extracting secondary bootstrap from boot floppy image ::
JV3Disk -X -I:%FUZIX%\boot.jv3 -O:%FUZIX%.sys.bin -T:29
%PAUSE%
if errorlevel 1 pause && goto :eof

set ZMAC=zmac\zmac.exe
if exist ZMAC goto ZMAC_OK
echo :: Downloading ZMAC ::
getzmac.sh
if errorlevel 1 pause && goto :eof
%PAUSE%
:ZMAC_OK

echo :: Assembling primary bootstrap ::
%ZMAC% %FUZIXHDBOOT%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof
%PAUSE%

echo :: Assembling secondary bootstrap ::
%ZMAC% %FUZIXHDSYS%.asm --od build --oo cim,lst -c -s -g
if errorlevel 1 pause && goto :eof
%PAUSE%

echo :: Writing new hard disk boot sector ::
HardDisk -U -1 -I:build/%FUZIXHDBOOT%.cim -O:%FUZIXHDBOOT%.hd -S:1 -N:1
if errorlevel 1 pause && goto :eof
%PAUSE%

echo :: Writing new hard disk secondary bootstrap ::
::HardDisk -U -1 -I:%FUZIX%.sys.bin -O:%FUZIXHDBOOT%.hd -T:202 -H:* -N:198
HardDisk -U -1 -I:build/%FUZIXHDSYS%.cim -O:%FUZIXHDBOOT%.hd -T:202 -H:* -N:198
if errorlevel 1 pause && goto :eof
%PAUSE%

echo :: Copying new hard disk image for FreHD ::
copy %FUZIXHDBOOT%.hd fuzix004
%PAUSE%

if exist windows\trs80gp.exe goto TRS80GP_OK
echo :: Downloading TRS80GP ::
gettrs80gp.sh
if errorlevel 1 pause && goto :eof
%PAUSE%
:TRS80GP_OK

echo :: Starting the emulator
%PAUSE%
trs80gp_Fuzix_HD_HDBoot_04.bat

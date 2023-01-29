@echo off
call :del *.dasm
call :del *.prn
call :del *.obj
call :del *.lst
call :del *.img
call :del *.map
call :del *.new
call :del *.tra
call :del *.tst
call :del *.bin
call :del *.obj
call :del *.bak
call :del *.out
call :del *.hd????.hd
call :del *.fix.hd
call :del std???.txt
call :del fuzix???
call :rmdir build
call :rmdir zmac
goto :eof

:del
if exist %1 del %1
goto :eof

:rmdir
if exist %1 rmdir /S /Q %1
goto :eof

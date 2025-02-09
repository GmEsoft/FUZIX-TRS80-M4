@echo off
echo     At the 'bootdev:' prompt, reply '0'
echo     At the 'login:' prompt, reply 'root'
echo     Do not forget to type 'shutdown' before shutting down!
windows\trs80gp.exe -m4p -h0 fuzix003
:: -b 8 -b 100

@echo off
echo     At the 'bootdev:' prompt, reply '0'
echo     At the 'login:' prompt, reply 'root'
echo     Do not forget to type 'shutdown' before shutting down!
windows\trs80gp.exe -m4 -d boot.jv3 -h0 hard4p-0
:: -b 8 -b 100

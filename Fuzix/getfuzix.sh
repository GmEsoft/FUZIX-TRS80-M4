#!/bin/sh
curl -k -o trs80-0.3.jv3.gz https://www.fuzix.org/downloads/0.3/trs80-0.3.jv3.gz
gzip -d -f trs80-0.3.jv3.gz 
curl -k -o trs80-0.3.hd.gz  https://www.fuzix.org/downloads/0.3/trs80-0.3.hd.gz
gzip -d -f trs80-0.3.hd.gz 
read -p "Press ENTER"

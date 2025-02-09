#!/bin/sh
DIR=trs80-0.4
mkdir -p $DIR
cd $DIR
curl -k -o boot.jv3 https://www.fuzix.org/downloads/0.4/trs80/boot.jv3
curl -k -o hdboot.jv3 https://www.fuzix.org/downloads/0.4/trs80/hdboot.jv3
curl -k -o hard4p-0 https://www.fuzix.org/downloads/0.4/trs80/hard4p-0
cd ..

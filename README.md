# FUZIX-TRS80-M4


Patch for Fuzix v0.3, v0.4 and v0.5(dev) to run on real TRS-80 Model 4(p), with FreHD autoboot


## Description

This is a patch to address 2 bugs in the official distribution of Fuzix release 0.3 for the TRS-80 Model 4-4p, to allow Fuzix to run on real hardware.

The first bug is a bad initialization of the CRT controller, causing the 2 1K video pages to be swapped.

The second bug is a missing wait ready loop after the OTIR statement used to write bytes to the hard disk.

In release 0.4 of Fuzix, the first bug has been fixed.

In release 0.5 of Fuzix currently under development, both bugs have been fixed.

Another change is the addition of a hard disk loader, to load the bootloader originally stored in the floppy image trs80-0.3.jv3, directly from an additional cylinder on the hard disk. The modified hard disk image is directly bootable from the Model 4p without needing the replacement of the original ROM with the special FreHD Boot ROM. It's also compatible with the special FreHD Boot ROM on both the Model 4 and the Model 4p.


## Build

- First, download and decompress the original Fuzix floppy and hard disk images https://www.fuzix.org/downloads/0.3/trs80-0.3.jv3.gz and https://www.fuzix.org/downloads/0.3/trs80-0.3.hd.gz . This can be done by running the script `getfuzix.sh`.
- Download ZMAC from http://48k.ca/zmac.zip . This will be used to build the new Hard Disk boot sector from `trs80-0.3.hdboot.asm` and the patched Fuzix system core from `trs80-0.3.sys.asm`. This can be done by running the script `getzmac.sh`.
- Build the utilities `HardDisk.exe`, `JV3Disk.exe` and `Patch.exe` from the C source files, using Visual Studio and the scripts `mk_HardDisk.exe`, `mk_JV3Disk.exe` and `mk_Patch.exe`. It may be necessary to adapt `vcvars32.bat` for your particular installation of Visual Studio.
- Run `make_trs80-0.3.hdboot.bat` to build the new hard disk image, with the new boot sector, the boot loader extracted from `trs80-0.3.jv3` and the patched system core from `trs80-0.3.hd`. This creates a new hard disk image `fuzix003` which can be directly copied to the FreHD SD Card.


## Run

To run the new Fuzix system in TRS80gp:

- Download TRS80gp from http://48k.ca/trs80gp.html or by running the script `gettrs80gp.sh`.
- Run TRS80gp with the new hard disk image with `trs80gp_Fuzix_HD_HDBoot.bat` or by running the following command:
`windows\trs80gp.exe -m4p -h0 fuzix003`
  - At the `bootdev:` prompt, reply `0`.
  - At the `login:` prompt, reply `root`.
  - Do not forget to type the command `shutdown` before shutting the system down, otherwise a `fsck /dev/hdd0` will be forced.
  


Enjoy !

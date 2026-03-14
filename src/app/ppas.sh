#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Linking /home/nik/DEV/00_pet_projects/Active/hexnik.coffiction_diary/src/coffiction_diary
OFS=$IFS
IFS="
"
/usr/bin/ld.bfd -b elf64-x86-64 -m elf_x86_64  --dynamic-linker=/lib64/ld-linux-x86-64.so.2     -L. -o /home/nik/DEV/00_pet_projects/Active/hexnik.coffiction_diary/src/coffiction_diary -T /home/nik/DEV/00_pet_projects/Active/hexnik.coffiction_diary/src/link38257.res -e _start
if [ $? != 0 ]; then DoExitLink /home/nik/DEV/00_pet_projects/Active/hexnik.coffiction_diary/src/coffiction_diary; fi
IFS=$OFS

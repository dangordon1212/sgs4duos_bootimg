#!/bin/bash

TOOL_DIR=$HOME/opt/arm-eabi-4.7/bin
BUILD_DIR=$PWD/../_9502

READY=0
for f in old-boot.img kernel.zip END; do
  if [ "$f" == 'END' ]; then
    READY=1
    break
  elif [ ! -f $f ]; then
    echo "$f missing"
    break
  fi
done
if [ $READY != 1 ]; then
  exit 1
fi

echo -n -e '\nExtract boot.img?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  ./abootimg -x old-boot.img
  sed -i '1d' bootimg.cfg
fi

echo -n -e '\nExpand initrd.img?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  rm -rf ramdisk
  mkdir ramdisk
  cd ramdisk
  gunzip -c ../initrd.img | cpio -i
  cd ..
fi

echo -n -e '\nCopy modules?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cd ramdisk
  ls -sh ./lib/modules/
  rm -f ./lib/modules/*
  find $BUILD_DIR -name '*.ko' -exec cp {} ./lib/modules/ \;
  $TOOL_DIR/arm-eabi-strip --strip-unneeded ./lib/modules/*.ko
  ls -sh ./lib/modules/
  cd ..
fi

echo -n -e '\nRepack initrd.img?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cd ramdisk
  find . | cpio -o -H newc | gzip > ../new-initrd.img
  cd ..
  ls -rush *initrd.img
fi

echo -n -e '\nCopy zImage?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cp $BUILD_DIR/arch/arm/boot/zImage new-zImage
  ls -rush *zImage
fi

echo -n -e '\nRepack boot.img?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  ./abootimg --create boot.img -f bootimg.cfg -k new-zImage -r new-initrd.img
  #./abootimg -u boot.img -k new-zImage -r new-initrd.img
  ls -rush *boot.img
fi

echo -n -e '\nCreate ZIP?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  rm -f new.zip new-signed.zip
  cp kernel.zip new.zip
  7z u new.zip boot.img | grep ing
  ../tools/signzip.sh new.zip
  mv new-signed.zip new-kernel.zip
  rm -f new.zip
fi

echo


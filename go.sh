#!/bin/bash

source $PWD/../my_setup.sh
test -z "$CROSS_COMPILE" && exit 1
BUILD_DIR=$PWD/..

test ! -f old-boot.img && echo "old-boot.img missing!" && exit 1
test ! -d META-INF     && echo "META-INF missing!"     && exit 1

echo -n -e '\nExtract boot.img?(N/y): '
read a
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  ./abootimg -x old-boot.img
  sed -i '1d' bootimg.cfg
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nExpand initrd.img?(N/y): '
  read a
fi 
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  rm -rf ramdisk
  mkdir ramdisk
  cd ramdisk
  gunzip -c ../initrd.img | cpio -i
  cd ..
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nCopy modules?(N/y): '
  read a
fi
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cd ramdisk
  ls -sh ./lib/modules/
  rm -f ./lib/modules/*
  find $BUILD_DIR ! -path $BUILD_DIR'/_repack/*' -a -name '*.ko' -exec cp {} ./lib/modules/ \;
  ${CROSS_COMPILE}strip --strip-unneeded ./lib/modules/*.ko
  ls -sh ./lib/modules/
  cd ..
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nRepack initrd.img?(N/y): '
  read a
fi
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cd ramdisk
  find . | cpio -o -H newc | gzip > ../new-initrd.img
  cd ..
  ls -rush *initrd.img
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nCopy zImage?(N/y): '
  read a
fi
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  cp $BUILD_DIR/arch/arm/boot/zImage new-zImage
  ls -rush *zImage
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nRepack boot.img?(N/y): '
  read a
fi
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  ./abootimg --create boot.img -f bootimg.cfg -k new-zImage -r new-initrd.img
  #./abootimg -u boot.img -k new-zImage -r new-initrd.img
  ls -rush *boot.img
fi

if [ "a$a" != 'ay' -a "a$a" != 'aY' ]; then
  echo -n -e '\nCreate ZIP?(N/y): '
  read a
fi
if [ "a$a" = 'ay' -o "a$a" = 'aY' ]; then
  rm -f new.zip new-signed.zip
  #cp kernel.zip new.zip
  7z a new.zip boot.img META-INF | grep ing
  ./tools/signzip.sh new.zip
  mv new-signed.zip new-kernel.zip
  rm -f new.zip
fi

echo


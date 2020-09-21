#!/bin/bash

kernel_dir="../linux"
base_dir=$(pwd)

display_help () {
	echo "Kernel Testing System - Copyright (C) 2020 Titouan (Stalone) S. <talone@boxph.one>

Usage : kts get|build [options]"
}

case $1 in
	get)
		mkdir -p .source

		case $2 in
			linux|kernel)
				git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git $kernel_dir
				;;
			busybox)
				cd .source && wget https://www.busybox.net/downloads/busybox-1.31.1.tar.bz2 -O - | tar -xjf -
				mv busybox-1.31.1 busybox && cd $base_dir
				;;
			*)
				echo "Unknown software $2; possible options are:

- linux
- busybox"
				;;
		esac
		;;
	build)
		case $2 in
			linux|kernel)
				cd $kernel_dir
				make x86_64_defconfig
				make -j5
				;;
			busybox)
				cd .source/busybox
				#make defconfig
				make -j5
				;;
			initram)
				rm -rf .initram
				mkdir $base_dir/.initram

				# Install kernel modules
				cd $kernel_dir
				make INSTALL_MOD_PATH=$base_dir/.initram modules_install

				# Install Busybox
				cd $base_dir/.source/busybox
				make CONFIG_PREFIX=$base_dir/.initram install
				cp $base_dir/init $base_dir/.initram/

				# Add system librairies
				cd $base_dir/.initram
				mkdir usr/lib lib64
				cp /usr/lib/libm.so.6 usr/lib
				cp /usr/lib/libresolv.so.2 usr/lib
				cp /usr/lib/libc.so.6 usr/lib
				cp /lib64/{ld-linux-x86-64.so.2,ld-2.32.so} lib64

				# Make initramfs
				chown -R root:root $base_dir/.initram
				find . -print0 | cpio --null -ov --format=newc | gzip - > initramfs-tiny.img
				;;
			*)
				echo "Unknown software $2; possible options are:

- linux
- busybox
- initram"
				;;
		esac
		;;
	run)
		qemu-system-x86_64 -m 256 -kernel $kernel_dir/arch/x86_64/boot/bzImage -initrd $base_dir/.initram/initramfs-tiny.img -append 'console=ttyS0 debug=all' -nographic -usb -enable-kvm
		;;
	*)
		display_help
		;;
esac

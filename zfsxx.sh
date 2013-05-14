#!/bin/sh -xe

cd $HOME/src/new-nza-ws/proto/root_i386
rm -f $HOME/zfsxx.tar
tar cf $HOME/zfsxx.tar \
	kernel/amd64/genunix kernel/genunix \
	kernel/kmdb/amd64/genunix kernel/kmdb/genunix \
	kernel/drv/amd64/zfs kernel/drv/zfs \
	kernel/fs/amd64/zfs kernel/fs/zfs \
	lib/amd64/libzfs.so.1 lib/libzfs.so.1 \
	usr/lib/amd64/libzpool.so.1 usr/lib/libzpool.so.1 \
	sbin/zfs \
	sbin/zpool \
	usr/bin/ztest \
	usr/bin/i86/ztest \
	usr/bin/amd64/ztest \
	usr/sbin/zdb \
	usr/sbin/i86/zdb \
	usr/sbin/amd64/zdb \
	kernel/misc/amd64/isal

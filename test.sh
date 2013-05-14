#!/bin/sh -ex

ZXX_POOL="qa"
ZXX_FS="test"
ZXX_MNT="/volumes/$ZXX_POOL"
ZXX_STAMP="`date "+%Y.%m.%d-%H:%M:%S"`"
ZXX_TESTS="/export/home/qa/tests/bug+sha1crc32+isal3mx2"
ZXX_ELAPSED="600"
ZXX_INTERVAL="10"

mkdir -p "$ZXX_TESTS"
cd "$ZXX_TESTS"

zxx_pool() {
	sudo /sbin/zpool destroy $ZXX_POOL || true
	sudo /sbin/zpool create -f -m $ZXX_MNT $ZXX_POOL \
		mirror c6t5000C50041D3F761d0 c6t5000C50041D6E3A1d0 \
		mirror c6t5000C50041D7ADBDd0 c6t5000C50041D7AEC9d0 \
		mirror c6t5000C50041D12E45d0 c6t5000C50041D13B61d0 \
		mirror c6t5000C50041D40B25d0 c6t5000C50041D41BB9d0 \
		special mirror c1t5000A72A3006C443d0 c1t5000A72A3006C445d0

#		c0t5000C50041D3BD33d0 c0t5000C50041D3DB37d0 \
#		c0t5000C50041D1B8EBd0 c0t5000C50041D3E2D3d0 \
#		c0t5000C50041D3BC7Bd0 c0t5000C50041D4286Fd0 \
#		special mirror c0t5000A7203006C443d0 c0t5000A7203006C445d0
	sudo /sbin/zpool set dedup_meta_ditto=1 $ZXX_POOL
#	sudo /sbin/zpool set specialclass=meta $ZXX_POOL
	sudo /sbin/zpool set ddt_desegregation=on $ZXX_POOL
	sudo /sbin/zpool set dedup_best_effort=on $ZXX_POOL
#	sudo /sbin/zpool set dedup_hi_best_effort={0-100} $ZXX_POOL
#	sudo /sbin/zpool set dedup_lo_best_effort={0-100} $ZXX_POOL
	sudo /sbin/zfs create $ZXX_POOL/$ZXX_FS
	sudo /sbin/zfs set specialclass=meta $ZXX_POOL/$ZXX_FS
	sudo /usr/bin/chown -R qa $ZXX_MNT
	echo "zfs_dedup_prefetch/W 0" | sudo /usr/bin/mdb -kw
}

#for ZXX_DEDUP in off on verify sha256 sha256,verify sha1crc32; do
for ZXX_DEDUP in sha256; do
  for ZXX_RS in 4k 8k 16k 32k 64k 128k; do
    for ZXX_RW in write read 100 50 0; do
	case "$ZXX_RW" in
	read|write)
		ZXX_MODE=sequential
		ZXX_OP=operation
		;;
	100|50|0)
		ZXX_MODE=random
		ZXX_OP=rdpct
		;;
	esac

	ZXX_DIR="dedup=$ZXX_DEDUP+recordsize=$ZXX_RS+$ZXX_OP=$ZXX_RW+mode=$ZXX_MODE"
	if [ -s "$ZXX_DIR/output/flatfile.html" ]; then
		continue
	else
		rm -rf $ZXX_DIR
	fi

	mkdir $ZXX_DIR
	cd $ZXX_DIR

	zxx_pool
	sudo /sbin/zfs set dedup=$ZXX_DEDUP $ZXX_POOL/$ZXX_FS
	sudo /sbin/zfs set recordsize=$ZXX_RS $ZXX_POOL/$ZXX_FS

	cat >vdbench.in <<-EOF
	#Xcompratio=1
	#Xdedupratio=4
	#Xdedupunit=$ZXX_RS
	fsd=fsd1,anchor=$ZXX_MNT/$ZXX_FS,depth=2,width=2,files=8,size=1G
	fwd=fwd1,fsd=fsd1,$ZXX_OP=$ZXX_RW,xfersize=$ZXX_RS,fileio=$ZXX_MODE,fileselect=$ZXX_MODE,threads=1
	rd=rd1,fwd=fwd1,fwdrate=max,format=yes,elapsed=$ZXX_ELAPSED,interval=$ZXX_INTERVAL
	EOF

#	zpool iostat -v $ZXX_POOL $ZXX_INTERVAL >zpool_iostat.txt 2>zpool_iostat.err &
#	iostat -xnz $ZXX_INTERVAL >iostat.txt 2>iostat.err &
	zpool status $ZXX_POOL $ZXX_INTERVAL >zpool_status.txt 2>zpool_status.err &
#	zpool status -D $ZXX_POOL $ZXX_INTERVAL >zpool_-D_status.txt 2>zpool_-D_status.err &
	vdbench -f vdbench.in
	pkill zpool || true
	pkill iostat || true
	zpool get all $ZXX_POOL >zpool_get_all.txt 2>zpool_get_all.err
	sudo /sbin/zpool scrub $ZXX_POOL
	until zpool status $ZXX_POOL | grep -q 'scan: scrub repaired 0'; do sleep 10; done
	cd ..
    done
  done
done

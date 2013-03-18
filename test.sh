#!/bin/sh -ex

ZXX_POOL="qa"
ZXX_FS="test"
ZXX_MNT="/volumes/$ZXX_POOL"
ZXX_STAMP="`date "+%Y.%m.%d-%H:%M:%S"`"
ZXX_TESTS="/export/home/qa/tests/$ZXX_STAMP"
ZXX_ELAPSED="600"
ZXX_INTERVAL="60"

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
	sudo /sbin/zfs create $ZXX_POOL/$ZXX_FS
	sudo /usr/bin/chown -R qa $ZXX_MNT
}

for ZXX_DEDUP in off on verify sha256 sha256,verify; do
  for ZXX_RS in 4k 8k 16k 32k 64k 128k; do
    for ZXX_RW in read write 100 50 0; do
	zxx_pool
	sudo /sbin/zfs set dedup=$ZXX_DEDUP $ZXX_POOL/$ZXX_FS
	sudo /sbin/zfs set recordsize=$ZXX_RS $ZXX_POOL/$ZXX_FS
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
	mkdir dedup=$ZXX_DEDUP+recordsize=$ZXX_RS+$ZXX_OP=$ZXX_RW+mode=$ZXX_MODE
	cd dedup=$ZXX_DEDUP+recordsize=$ZXX_RS+$ZXX_OP=$ZXX_RW+mode=$ZXX_MODE

	cat >vdbench.in <<-EOF
	compratio=1
	dedupratio=4
	dedupunit=$ZXX_RS
	fsd=fsd1,anchor=$ZXX_MNT/$ZXX_FS,depth=2,width=2,files=8,size=4G
	fwd=fwd1,fsd=fsd1,$ZXX_OP=$ZXX_RW,xfersize=$ZXX_RS,fileio=$ZXX_MODE,fileselect=$ZXX_MODE,threads=8
	rd=rd1,fwd=fwd1,fwdrate=max,format=yes,elapsed=$ZXX_ELAPSED,interval=$ZXX_INTERVAL
	EOF

	zpool iostat $ZXX_POOL $ZXX_INTERVAL $(( $ZXX_ELAPSED / $ZXX_INTERVAL)) >zpool_iostat.txt 2>zpool_iostat.err &
	vdbench -f vdbench.in
	vdbench parseflat -i output/flatfile.html -o report.csv -c Xfersize rate resp MB/sec Read_rate Read_resp Write_rate Write_resp MB_read MB_write cpu_used cpu_user cpu_kernel cpu_wait cpu_idle -a
	zpool get all $ZXX_POOL >zpool_get_all.txt 2>zpool_get_all.err
	cd ..
    done
  done
done

#!/bin/sh -e

MILESTONE=0
DEDUP_RATIO=4

cd $HOME/tests/generic

for ZXX_DEDUP in off on verify sha256 sha256,verify; do
  for ZXX_RS in 4 8 16 32 64 128; do
    for ZXX_RW in read write 100 50 0; do
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

	case "$ZXX_RW" in
	read) MODE=0;;
	write) MODE=1;;
	100) MODE=2;;
	50) MODE=3;;
	0) MODE=4;;
	esac

	case "$ZXX_DEDUP" in
	off) DEDUP_TYPE=0;;
	on) DEDUP_TYPE=1;;
	verify) DEDUP_TYPE=2;;
	sha256) DEDUP_TYPE=3;;
	sha256,verify) DEDUP_TYPE=4;;
	esac

	cd dedup=$ZXX_DEDUP+recordsize=${ZXX_RS}k+$ZXX_OP=$ZXX_RW+mode=$ZXX_MODE
	rm -f report.csv
	vdbench parseflat -i output/flatfile.html -o report.csv -c rate resp MB/sec Read_rate Read_resp Write_rate Write_resp MB_read MB_write cpu_used cpu_user cpu_kernel cpu_wait cpu_idle -a 2>/dev/null
	test -s report.csv || exit 1
	printf "%d,%d,%d,%d,%d," $MILESTONE, $ZXX_RS $MODE $DEDUP_TYPE $DEDUP_RATIO
	tail -1 report.csv
	cd ..
    done
  done
done

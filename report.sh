#!/bin/sh -e

SCRIPTS=$(dirname $0)
export GDFONTPATH=/usr/local/lib/X11/fonts/webfonts

rm -f zfsxx.db
sqlite3 zfsxx.db <$SCRIPTS/zfsxx.sql

sqlite3 zfsxx.db <<EOF
.mode csv 
.import report.csv data
EOF

for k in sequential_read sequential_write random_read random_read_write random_write; do
  for i in total_mb rate resp cpu_kernel; do
	sqlite3 zfsxx.db <<-EOF >report.dat
	.mode tabs
	select data.block_size, dedup.term, $i
	from data, dict dedup, dict operation
	where dedup.up=1 and dedup.n=dedup_type
	and operation.up=0 and operation.term='$k' and operation.n=data.operation_type
	order by dedup.term, data.block_size;
	EOF

	# hack for gnuplot
	sed -i '' 's/^\(128.*\)$/\1\
/g' report.dat
	sed -i '' 's/^\(4.*\)$/\1\
\1/g' report.dat

	O=$(echo "select dsc from dict where up=0 and term='$k';" | sqlite3 zfsxx.db)
	U=$(echo "select dsc from dict where up=4 and term='$i';" | sqlite3 zfsxx.db)
	D=$(echo "select dsc from dict where up=3 and term='$i';" | sqlite3 zfsxx.db)

	gnuplot <<-EOF
	set terminal jpeg
	set output "${k}_${i}.jpg"
	set key out
	set key title "Dedup:" 
	set title "$O: $D"
	set ylabel "$U"
	set xlabel "block size, KB"
	set xrange [0:132]
	set xtics (4, 8, 16, 32, 64, 128)
	plot for [i=0:4] 'report.dat' using 1:3 every :::i::i w l title columnhead(2)
	EOF
	rm -f report.dat
  done
done

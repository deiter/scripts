#!/bin/sh -e

# gnuplot location
GNUPLOT=/usr/local/bin/gnuplot
# sqlite location
SQLITE=/usr/local/bin/sqlite3
# fonts for gnuplot
export GDFONTPATH=/usr/local/lib/X11/fonts/webfonts
# zfsxx scrips dir
SCRIPTS=$(dirname $0)

rm -f zfsxx.db
$SQLITE zfsxx.db <$SCRIPTS/zfsxx.sql

$SQLITE zfsxx.db <<EOF
.mode csv 
.import report.csv data
EOF

for k in sequential_read sequential_write random_read random_read_write random_write; do
  for i in total_mb rate resp cpu_kernel; do
	$SQLITE zfsxx.db <<-EOF >report.dat
	.mode tabs
	select data.block_size, dedup.dsc, $i
	from data, dict dedup, dict operation
	where dedup.up=1 and dedup.n=dedup_type
	and operation.up=0 and operation.term='$k' and operation.n=data.operation_type
	and data.milestone=0
	order by dedup.term, data.block_size;
	EOF

	# hack for gnuplot
	sed -i '' 's/^\(128.*\)$/\1\
/g' report.dat
	sed -i '' 's/^\(4.*\)$/\1\
\1/g' report.dat

	O=$(echo "select dsc from dict where up=0 and term='$k';" | $SQLITE zfsxx.db)
	U=$(echo "select dsc from dict where up=4 and term='$i';" | $SQLITE zfsxx.db)
	D=$(echo "select dsc from dict where up=3 and term='$i';" | $SQLITE zfsxx.db)
	M=$(echo "select dsc from dict where up=2 and n=0;" | $SQLITE zfsxx.db)
	R=$(echo "select max(dedup_ratio) from data where milestone=0;" | $SQLITE zfsxx.db)

	$GNUPLOT <<-EOF
	set terminal jpeg size 1024,768
	set output "${k}_${i}.jpg"
	set key out
	set key title "dedup\nchecksum:" 
	set title "$M\n$O: $D\ndedup ratio: $R"
	set ylabel "$U"
	set xlabel "block size, KB"
	set xrange [0:132]
	set xtics (4, 8, 16, 32, 64, 128)
	plot for [i=0:4] 'report.dat' using 1:3 every :::i::i w l title columnhead(2)
	EOF
	rm -f report.dat
  done
done

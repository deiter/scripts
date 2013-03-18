#!/bin/sh -ex

SCRIPTS=$(dirname $0)

rm -f zfsxx.db
sqlite3 zfsxx.db <$SCRIPTS/zfsxx.sql

sqlite3 zfsxx.db <<EOF
.mode csv 
.import report.csv data
EOF

#sqlite3 zfsxx.db <<EOF >report.dat
#.mode tabs
#select block_size, term, total_mb, rate, resp, cpu_kernel from data, dict
#        where operation_type=0 and up=1 and n=dedup_type;
#EOF

#sed -i '' 's/^\(128.*\)$/\1\
#/g' report.dat
#sed -i '' 's/^\(4.*\)$/\1\
#\1/g' report.dat

for k in sequential_read sequential_write random_read random_read_write random_write; do
  for i in total_mb rate resp cpu_kernel; do
	sqlite3 zfsxx.db <<-EOF >report.dat
	.mode tabs
	select block_size, term, $i
	from data, dict
	where operation_type=0 and up=1 and n=dedup_type;
	EOF

	# hack for gnuplot
	sed -i '' 's/^\(128.*\)$/\1\
/g' report.dat
	sed -i '' 's/^\(4.*\)$/\1\
\1/g' report.dat

	O=$(echo "select dsc from dict where up=0 and term='sequential_read';" | sqlite3 zfsxx.db)
	U=$(echo "select dsc from dict where up=4 and term='total_mb';" | sqlite3 zfsxx.db)
	D=$(echo "select dsc from dict where up=3 and term='total_mb';" | sqlite3 zfsxx.db)

	gnuplot <<-EOF
	set terminal jpeg
	set output "${i}_sequential_read.jpg"
	set key out
	set key title "Dedup:" 
	set title "$O: $D"
	set ylabel "$U"
	set xlabel "block size, KB"
	set xrange [0:132]
	set xtics (4, 8, 16, 32, 64, 128)
	plot for [i=0:4] 'report.dat' using 1:3 every :::i::i w l title columnhead(2)
	EOF
	exit
  done
done
exit

gnuplot <<EOF
set terminal jpeg
set output "mb_sequential_read.jpg"
set key out
set key title "Dedup:" 
set title "sequential read: MBPS"
set ylabel "MBPS"
set xlabel "block size, KB"
set xrange [0:132]
set xtics (4, 8, 16, 32, 64, 128)
plot for [i=0:4] 'report.dat' using 1:3 every :::i::i w l title columnhead(2)
EOF

gnuplot <<'EOF'
set terminal jpeg
set output "iops_sequential_read.jpg"
set key out
set key title "Dedup:"
set title "sequential read: IOPS"
set ylabel "IOPS"
set xlabel "block size, KB"
set xrange [0:132]
set xtics (4, 8, 16, 32, 64, 128)
plot for [i=0:4] 'report.dat' using 1:4 every :::i::i w l title columnhead(2)
EOF

gnuplot <<'EOF'
set terminal jpeg
set output "response_sequential_read.jpg"
set key out
set key title "Dedup:"
set title "sequential read: response"
set ylabel "response, ms"
set xlabel "block size, KB"
set xrange [0:132]
set xtics (4, 8, 16, 32, 64, 128)
plot for [i=0:4] 'report.dat' using 1:5 every :::i::i w l title columnhead(2)
EOF

gnuplot <<'EOF'
set terminal jpeg
set output "cpu_sequential_read.jpg"
set key out
set key title "Dedup:"
set title "sequential read: CPU"
set ylabel "CPU, %"
set xlabel "block size, KB"
set xrange [0:132]
set xtics (4, 8, 16, 32, 64, 128)
plot for [i=0:4] 'report.dat' using 1:6 every :::i::i w l title columnhead(2)
EOF

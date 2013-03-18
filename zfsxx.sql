drop table dic_data;
create table dic_data (
	up integer,
	n integer,
	term text
);

-- 0 dictionary: type of operation
insert into dic_data values(0, 0, 'sequential read');
insert into dic_data values(0, 1, 'sequential write');
insert into dic_data values(0, 2, 'random read');
insert into dic_data values(0, 3, 'random 50% read, 50% write');
insert into dic_data values(0, 4, 'random write');

-- 1 dictionary: type of dedup
insert into dic_data values(1, 0, 'off');
insert into dic_data values(1, 1, 'on');
insert into dic_data values(1, 2, 'verify');
insert into dic_data values(1, 3, 'sha256');
insert into dic_data values(1, 4, 'sha256,verify');

-- 2 dictionary: milestone
insert into dic_data values(2, 0, '4.0m23');

drop table data;
create table data (
	milestone integer,
	block_size integer,
	operation_type integer,
	dedup_type integer,
	dedup_ratio real,
	rate real,
	resp real,
	total_mb real,
	read_rate real,
	read_resp real,
	write_rate real,
	write_resp real,
	read_mb real,
	write_mb real,
	cpu_used real,
	cpu_user real,
	cpu_kernel real,
	cpu_wait real,
	cpu_idle real
);

# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::DB;
use strict;

use Gedafe::Global qw(%g);

use DBI;
use DBD::Pg 1.20; # 1.20 has constants for data types

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(
	DB_Connect
	DB_GetNumRecords
	DB_FetchList
	DB_GetRecord
	DB_AddRecord
	DB_UpdateRecord
	DB_GetCombo
	DB_DeleteRecord
	DB_GetDefault
	DB_ParseWidget
	DB_ID2HID
	DB_HID2ID
	DB_GetBlobType
	DB_GetBlobName
	DB_DumpBlob
	DB_RawField
	DB_DumpTable
);

sub DB_AddRecord($$$);
sub DB_Connect($$);
sub DB_DB2HTML($$);
sub DB_DeleteRecord($$$);
sub DB_DumpBlob($$$$);
sub DB_DumpTable($$$);
sub DB_ExecQuery($$$$$);
sub DB_FetchList($$);
sub DB_FetchListSelect($$);
sub DB_GetBlobName($$$$);
sub DB_GetBlobType($$$$);
sub DB_GetCombo($$$);
sub DB_GetDefault($$$);
sub DB_GetNumRecords($$);
sub DB_GetRecord($$$$);
sub DB_HID2ID($$$);
sub DB_ID2HID($$$);
sub DB_Init($$);
sub DB_MergeAcls($$);
sub DB_ParseWidget($);
sub DB_PrepareData($$);
sub DB_RawField($$$$);
sub DB_ReadDatabase($);
sub DB_ReadFields($$$);
sub DB_ReadTableAcls($$);
sub DB_ReadTables($$);
sub DB_Record2DB($$$$);
sub DB_UpdateRecord($$$);
sub DB_Widget($$);

my %type_widget_map = (
	'date'      => 'text(size=12)',
	'time'      => 'text(size=12)',
	'timestamp' => 'text(size=22)',
	'timestamptz' => 'text(size=28)',
	'int2'      => 'text(size=6)',
	'int4'      => 'text(size=12)',
	'int8'      => 'text(size=12)',
	'numeric'   => 'text(size=12)',
	'float8'    => 'text(size=12)',
	'bpchar'    => 'text(size=40)',
	'text'      => 'text',
	'name'      => 'text(size=20)',
	'bool'      => 'checkbox',
	'bytea'     => 'file',
);

sub DB_Init($$)
{
	my ($user, $pass) = @_;
	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass) or
		return undef;

	# read database
	$g{db_database} = DB_ReadDatabase($dbh);

	# read tables
	$g{db_tables} = DB_ReadTables($dbh, $g{db_database});
	defined $g{db_tables} or return undef;

	# order tables
	$g{db_tables_list} = [ sort { $g{db_tables}{$a}{desc} cmp
		$g{db_tables}{$b}{desc} } keys %{$g{db_tables}} ];

	# read table acls
	DB_ReadTableAcls($dbh, $g{db_tables}) or return undef;

	# read fields
	$g{db_fields} = DB_ReadFields($dbh, $g{db_database}, $g{db_tables});
	defined $g{db_fields} or return undef;

	# order fields
	for my $table (@{$g{db_tables_list}}) {
		$g{db_fields_list}{$table} =
			[ sort { $g{db_fields}{$table}{$a}{order} <=>
				$g{db_fields}{$table}{$b}{order} }
				keys %{$g{db_fields}{$table}}
			];
	}

	return 1;
}

sub DB_ReadDatabase($)
{
	my $dbh = shift;
	my ($sth, $query, $data);
	my %database = ();

	# PostgreSQL version
	$query = "SELECT VERSION()";
	$sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	$data = $sth->fetchrow_arrayref();
	$sth->finish;
	if($data->[0] =~ /^PostgreSQL (\d+\.\d+)/) {
		$database{version} = $1;
	}
	else {
		# we don't support versions older than 7.0
		# if VERSION() doesn't exist, assume 7.0
		$database{version} = '7.0';
	}

	# database oid
	my $oid;
	$query = "SELECT oid FROM pg_database WHERE datname = '$dbh->{Name}'";
	$sth = $dbh->prepare($query);
	$sth->execute() or die $sth->errstr;
	$data = $sth->fetchrow_arrayref() or die $sth->errstr;
	$oid = $data->[0];
	$sth->finish;

	# read database name from database comment
	$query = "SELECT description FROM pg_description WHERE objoid = $oid";
	$sth = $dbh->prepare($query);
	$sth->execute() or die $sth->errstr;
	$data = $sth->fetchrow_arrayref();
	$database{desc} = $data ? $data->[0] : $dbh->{Name};
	$sth->finish;

	return \%database;
}

sub DB_ReadTables($$)
{
	my ($dbh, $database) = @_;
	my %tables = ();
	my ($query, $sth, $data);

	# combo
	# 7.0: views have relkind 'r'
	# 7.1: views have relkind 'v'

	# tables
	$query = <<'END';
SELECT c.relname
FROM pg_class c
WHERE (c.relkind = 'r' OR c.relkind = 'v')
AND c.relname !~ '^pg_'
END
	$sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		$tables{$data->[0]} = { };
		if($data->[0] =~ /^meta|(_list|_combo)$/) {
			$tables{$data->[0]}{hide} = 1;
		}
		if($data->[0] =~ /_rep$/) {
			$tables{$data->[0]}{report} = 1;
		}
	}
	$sth->finish;

	# read table comments as descriptions
	if($database->{version} >= 7.2) {
		$query = <<'END';
SELECT c.relname, obj_description(c.oid, 'pg_class')
FROM pg_class c
WHERE (c.relkind = 'r' OR c.relkind = 'v')
AND c.relname !~ '^pg_'
END
	}
	else {
		$query = <<'END';
SELECT c.relname, d.description 
FROM pg_class c, pg_description d
WHERE (c.relkind = 'r' OR c.relkind = 'v')
AND c.relname !~ '^pg_'
AND c.oid = d.objoid
END
	}
	$sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		next unless defined $tables{$data->[0]};
		$tables{$data->[0]}{desc} = $data->[1];
	}
	$sth->finish;

	# set not-defined table descriptions
	for my $table (keys %tables) {
		next if defined $tables{$table}{desc};
		if(exists $tables{"${table}_list"} and defined
			$tables{"${table}_list"}{desc})
		{
			$tables{$table}{desc} = $tables{"${table}_list"}{desc};
		}
		else {
			$tables{$table}{desc} = $table;
		}
	}

	# meta_tables
	$query = 'SELECT meta_tables_table, meta_tables_attribute, meta_tables_value FROM meta_tables';
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		next unless defined $tables{$data->[0]};
		my $attr = lc($data->[1]);
		$tables{$data->[0]}{meta}{$attr}=$data->[2];
		if($attr eq 'hide' and $data->[2]) {
			$tables{$data->[0]}{hide}=1;
		}
	}
	$sth->finish;

	return \%tables;
}

sub DB_MergeAcls($$)
{
	my ($a, $b) = @_;

	$a = '' unless defined $a;
	$b = '' unless defined $a;
	my %acls = ();
	for(split('',$a)) {
		$acls{$_}=1;
	}
	for(split('',$b)) {
		$acls{$_}=1;
	}
	return join('',keys %acls);
}

sub DB_ReadTableAcls($$)
{
	my ($dbh, $tables) = @_;

	my ($query, $sth, $data);

	# users
	my %db_users;
	$query = 'SELECT usename, usesysid FROM pg_user';
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		$db_users{$data->[1]} = $data->[0];
	}
	$sth->finish;

	# groups
	my %db_groups;
	$query = 'SELECT groname, grolist FROM pg_group';
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		my $group = $data->[1];
		if(defined $group) {
			$group =~ s/^{(.*)}$/$1/;
			my @g = split /,/, $group;
			$db_groups{$data->[0]} = [@db_users{@g}];
		}
		else {
			$db_groups{$data->[0]} = [];
		}
	}
	$sth->finish;

	# acls
	$query = "SELECT c.relname, c.relacl FROM pg_class c WHERE (c.relkind = 'r' OR c.relkind='v') AND relname !~ '^pg_'";
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		next unless defined $data->[0];
		next unless defined $data->[1];
		my $acldef = $data->[1];
		$acldef =~ s/^{(.*)}$/$1/;
		my @acldef = split(',', $acldef);
		map { s/^"(.*)"$/$1/ } @acldef;
		acl: for(@acldef) {
			/(.*)=(.*)/;
			my $who = $1; my $what = $2;
			if($who eq '') {
				# PUBLIC: assign permissions to all db users
				for(values %db_users) {
					$tables->{$data->[0]}{acls}{$_} =
						DB_MergeAcls($tables->{$data->[0]}{acls}{$_}, $what);
				}
			}
			elsif($who =~ /^group (.*)$/) {
				# group permissions: assign to all db groups
				for(@{$db_groups{$1}}) {
					$tables->{$data->[0]}{acls}{$_} =
						DB_MergeAcls($tables->{$data->[0]}{acls}{$_}, $what);
				}
			}
			else {
				# individual user: assign just to this db user
				$tables->{$data->[0]}{acls}{$who} =
					DB_MergeAcls($tables->{$data->[0]}{acls}{$who}, $what);
			}
		}
	}

	$sth->finish;

	return 1;
}

# DB_Widget: determine widget from type if not explicitely defined
sub DB_Widget($$)
{
	my ($fields, $f) = @_;

	if(defined $f->{widget} and $f->{widget} eq 'isearch'){
		my $r  = $f->{reference};
		my $rt = $g{db_tables}{$r};
		defined $rt or die "table $f->{reference}, referenced from $f->{table}:$f->{field}, not found.\n";
		if(defined $fields->{$r}{"${r}_hid"}) {
			# Combo with HID
			return "hidisearch(ref=$r)";
		}
		return "isearch(ref=$r)";
	}


	return $f->{widget} if defined $f->{widget};

	# HID and combo-boxes
	if($f->{type} eq 'int4' or $f->{type} eq 'int8') {
		if(defined $f->{reference}) {
			my $r  = $f->{reference};
			my $rt = $g{db_tables}{$r};
			defined $rt or die "table $f->{reference}, referenced from $f->{table}:$f->{field}, not found.\n";
			my $combo = "${r}_combo";
			if(defined $g{db_tables}{$combo}) {
				if(defined $fields->{$r}{"${r}_hid"}) {
					# Combo with HID
					return "hidcombo(combo=$combo,ref=$r)";
				}
				return "idcombo(combo=$combo)";
			}
			if(defined $fields->{$r}{"${r}_hid"}) {
				# Plain with HID
				return "hid(ref=$r)";
			}
			return "text";
		}
		return $type_widget_map{$f->{type}};
	}
	elsif($f->{type} eq 'varchar') {
		my $len = $f->{atttypmod}-4;
		if($len <= 0) {
			return 'text';
		}
		else {
			return "text(size=$len,maxlength=$len)";
		}
	}
	else {
		my $w = $type_widget_map{$f->{type}};
		defined $w or die "unknown widget for type $f->{type} ($f->{table}:$f->{field}).\n";
		return $w;
	}
}

# Parse widget specification, split args, verify if it is a valid widget
sub DB_ParseWidget($)
{
	my ($widget) = @_;
	$widget =~ /^(\w+)(\((.*)\))?$/ or die "syntax error for widget: $widget";
	my ($type, $args_str) = ($1, $3);
	my %args=();
	if(defined $args_str) {
		for my $w (split('\s*,\s*',$args_str)) {
			$w =~ s/^\s+//;
			$w =~ s/\s+$//;
			$w =~ /^(\w+)\s*=\s*(.*)$/ or die "syntax error in $type-widget argument: $w";
			$args{$1}=$2;
		}
	}

	# verify
	if($type eq 'idcombo' or $type eq 'hidcombo') {
		defined $args{'combo'} or
			die "widget $widget: mandatory argument 'combo' not defined";
	}
	if($type eq 'hidcombo' or $type eq 'hidisearch') {
		my $r = $args{'ref'};
		defined $r or
			die "widget $widget: mandatory argument 'ref' not defined";
		defined $g{db_tables}{$r} or
			die "widget $widget: no such table: $r";
		defined $g{db_fields}{$r}{"${r}_hid"} or
			die "widget $widget: table $r has no HID";
	}

	return ($type, \%args);
}

sub DB_ReadFields($$$)
{
	my ($dbh, $database, $tables) = @_;
	my ($query, $sth, $data);
	my %fields = ();

	# fields
	$query = <<'END';
SELECT a.attname, t.typname, a.attnum, a.atthasdef, a.atttypmod
FROM pg_class c, pg_attribute a, pg_type t
WHERE c.relname = ? AND a.attnum > 0
AND a.attrelid = c.oid AND a.atttypid = t.oid
AND a.attname != ('........pg.dropped.' || a.attnum || '........')
ORDER BY a.attnum
END
	$sth = $dbh->prepare($query);
	for my $table (keys %$tables) {
		$sth->execute($table) or die $sth->errstr;
		my $order = 1;
		while ($data = $sth->fetchrow_arrayref()) {
			if($data->[0] eq 'meta_sort') {
				$tables->{$table}{meta_sort}=1;
			}
			else {
				$fields{$table}{$data->[0]} = {
					field => $data->[0],
					order => $order++,
					type => $data->[1],
					attnum => $data->[2],
					atthasdef => $data->[3],
					atttypmod => $data->[4] 
				};
			}
		}
	}
	$sth->finish;

	my %field_descs = ();

	# read field comments as descriptions
	if($database->{version} >= 7.2) {
		$query = <<'END';
SELECT a.attname, col_description(a.attrelid, a.attnum)
FROM pg_class c, pg_attribute a
WHERE c.relname = ? AND a.attnum > 0
AND a.attrelid = c.oid
AND a.attname != ('........pg.dropped.' || a.attnum || '........')
END
	}
	else {
		$query = <<'END';
SELECT a.attname, d.description
FROM pg_class c, pg_attribute a, pg_description d
WHERE c.relname = ? AND a.attnum > 0
AND a.attrelid = c.oid
AND a.oid = d.objoid
AND a.attname != ('........pg.dropped.' || a.attnum || '........')
END
	}

	$sth = $dbh->prepare($query);
	for my $table (keys %$tables) {
		$sth->execute($table) or die $sth->errstr;
		while ($data = $sth->fetchrow_arrayref()) {
			defined $data->[1] and $data->[1] !~ /^\s*$/ or next;
			$fields{$table}{$data->[0]}{desc}=$data->[1];
			$field_descs{$data->[0]} = $data->[1];
		}
	}
	$sth->finish;

	# set not-defined field descriptions
	for my $table (keys %$tables) {
		for my $field (keys %{$fields{$table}}) {
			my $f = $fields{$table}{$field};
			if(not defined $f->{desc}) {
				if(defined $field_descs{$field}) {
					$f->{desc} = $field_descs{$field};
				}
				else {
					$f->{desc} = $field;
				}
			}
		}
	}

	# defaults
	$query = <<'END';
SELECT d.adsrc FROM pg_attrdef d, pg_class c WHERE
c.relname = ? AND c.oid = d.adrelid AND d.adnum = ?;
END
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	for my $table (keys %$tables) {
		for my $field (keys %{$fields{$table}}) {
			if(! $fields{$table}{$field}{atthasdef}) { next; }
			$sth->execute($table, $fields{$table}{$field}{attnum}) or die $sth->errstr;
			my $d = $sth->fetchrow_arrayref();
			$fields{$table}{$field}{default} = $d->[0];
			$sth->finish;
		}
	}

	# meta fields
	my %meta_fields = ();
	$query = <<'END';
SELECT meta_fields_table, meta_fields_field, meta_fields_attribute,
meta_fields_value FROM meta_fields
END
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		$meta_fields{lc($data->[0])}{lc($data->[1])}{lc($data->[2])} =
			$data->[3];
	}
	$sth->finish;

	# foreign-key constraints (REFERENCES)
	$query = <<'END';
SELECT tgargs from pg_trigger, pg_proc where pg_trigger.tgfoid=pg_proc.oid AND pg_trigger.tgname
LIKE 'RI_ConstraintTrigger%' AND pg_proc.proname = 'RI_FKey_check_ins'
END
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		my @d = split(/(?:\000|\\000)/,$$data[0]); # DBD::Pg 0.95: \\000, DBD::Pg 0.98: \000
		$meta_fields{$d[1]}{$d[4]}{reference} = $d[2];
	}
	$sth->finish;

	# if there is a HID field, then hide the ID field
	for my $view (keys %$tables) {
		my $table = $view; $table =~ /^(.*)_list$/ and $table = $1; 
		if(defined $fields{$view}{"${table}_hid"} and
		   defined $fields{$view}{"${table}_id"})
	   	{
			$fields{$view}{"${table}_id"}{hide_list}=1;
		}
	}

	# go through every table and field and fill-in:
	# - table information in reference fields
	# - meta information from meta_fields
	# - widget from type (if not specified)
	table: for my $table (keys %$tables) {
		field: for my $field (keys %{$fields{$table}}) {
			my $f = $fields{$table}{$field};
			my $m = undef;
			if(defined $meta_fields{$table}) {
				$m = $meta_fields{$table}{$field};
			}
			if(defined $m) {
				$f->{widget}    = $m->{widget};
				$f->{reference} = $m->{reference};
				$f->{copy}      = $m->{copy};
				$f->{sortfunc}  = $m->{sortfunc};
				$f->{markup}    = $m->{markup};
				$f->{align}     = $m->{align};
				$f->{hide_list} = $m->{hide_list};
			}
			#if(! defined $f->{widget}) {
			$f->{widget} = DB_Widget(\%fields, $f);
			#}
		}
	}

	return \%fields;
}

sub DB_Connect($$)
{
	my $user = shift;
	my $pass = shift;
	my $dbh;
	if($dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass)) {
		if(not defined $g{db_meta_loaded}) {
			DB_Init($user, $pass) or return undef;
			$g{db_meta_loaded} = 1;
		}
		return $dbh;
	}
	return undef;
}

sub DB_GetDefault($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;

	my $query = $g{db_fields}{$table}{$field}{default};
	return undef unless defined $query;

	$query = "SELECT ".$query;
	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or die $sth->errstr;
	my $d = $sth->fetchrow_arrayref();
	my $default = $d->[0];
	$sth->finish;

	return $default;
}

sub DB_DB2HTML($$)
{
	my $str = shift;
	my $type = shift;

	# undef -> ''
	$str = '' unless defined $str;

	# trim space
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;

	if($type eq 'bool') {
		$str = ($str ? 'yes' : 'no');
	}
	if($type eq 'text' and $str !~ /<[^>]+>/) { #make sure the text does not contain html
		$str =~ s/\n/<BR>/g;
	}
	if($str eq '') {
		$str = '&nbsp;';
	}

	return $str;
}

# this is merely an envelope for DB_FetchList()
sub DB_GetNumRecords($$)
{
	my $s = shift;
	my $spec = shift;

	$spec->{countrows} = 1;
	return DB_FetchList($s, $spec);
}

sub DB_FetchListSelect($$)
{
	my $dbh = shift;
	my $spec = shift;
	my $v = $spec->{view};

	# does the view/table exist?
	defined $g{db_fields_list}{$v} or die "no such table: $v\n";

	# go through fields and build field list for SELECT (...)
	my @fields = @{$g{db_fields_list}{$v}};
	my @select_fields;
	for my $f (@fields) {
		if($g{db_fields}{$v}{$f}{type} eq 'bytea') {
			push @select_fields, "substring($f,1,position(' '::bytea in $f)-1)";
		}
		else {
			push @select_fields, $f;
		}
	}

	my @query_parameters = ();

	my $query = "SELECT ";
	$query .= $spec->{countrows} ? "COUNT(*)" : join(', ',@select_fields);
	$query .= " FROM $v";
	my $searching=0;
	if(defined $spec->{search_field} and defined $spec->{search_value}
		and $spec->{search_field} ne '' and $spec->{search_value} ne '')
	{
		my $type = $g{db_fields}{$v}{$spec->{search_field}}{type};


		if($type eq 'date') {
			$query .= " WHERE $spec->{search_field} = ? ";
			push @query_parameters, "$spec->{search_value}";
		}
		elsif($type eq 'bool') {
			$query .= " WHERE $spec->{search_field} = ? ";
			push @query_parameters, "$spec->{search_value}";
		}
		elsif($type eq 'bytea') {
			$query .= " WHERE position(?::bytea in $spec->{search_field}) != 0";
			push @query_parameters, "$spec->{search_value}";
		}
		else {
			$query .= " WHERE $spec->{search_field} ~*  ? ";
			push @query_parameters, ".*$spec->{search_value}.*";
		}
		$searching=1;
	}
	if(defined $spec->{filter_field} and defined $spec->{filter_value}) {
		if($searching) {
			$query .= ' AND';
		}
		else {
			$query .= ' WHERE';
		}
		$query .= " $spec->{filter_field} = ? ";
		push @query_parameters, "$spec->{filter_value}";
	}
	unless ($spec->{countrows}) {
		if (defined $spec->{orderby} and $spec->{orderby} ne '') {
			if (defined $g{db_fields}{$v}{$spec->{orderby}}{sortfunc}) {
				my $f = $g{db_fields}{$v}{$spec->{orderby}}{sortfunc};
				$query .= " ORDER BY $f($spec->{orderby})";
			} else {
				$query .= " ORDER BY $spec->{orderby}";
			}
			if ($spec->{descending}) {
				$query .= " DESC";
			}
			if (defined $g{db_tables}{$v}{meta_sort}) {
				$query .= ", $v.meta_sort";
			}
			else {
				# if sorting on a non unique field,
				# then the order of the record is not
				# guaranteed -> this can be confusing
				# while scrolling.
				# try to put order by sorting additionally
				# with first field, assumed to be the ID
				$query .= ", $fields[0]";
			}
		} elsif (defined $g{db_tables}{$v}{meta_sort}) {
			$query .= " ORDER BY $v.meta_sort";
		}
		if (defined $spec->{limit} and $spec->{limit} != -1 and !$spec->{export})
		{
			$query .= " LIMIT $spec->{limit}";
		}
		if (defined $spec->{offset} and !$spec->{countrows}) {
			$query .= " OFFSET $spec->{offset}";
		}
	}

	
	# print "\n<!-- $query -->\n" unless $spec->{export};
	# this is kind of useless now that query's are made with the ? placeholders.

	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	
	for(1..scalar(@query_parameters)){
		#count from 1 to number_of_parameters including.
		#sql parameters start at 1. 
		$sth->bind_param($_,shift @query_parameters);
	}

	$sth->execute() or die $sth->errstr . " ($query)";
	return (\@fields, $sth);
}

sub DB_FetchList($$)
{
	my $s = shift;
	my $spec = shift;

	my $dbh = $s->{dbh};
	my $user = $s->{user};
	my $v = $spec->{view};

	# fetch one row more than necessary, so that we
	# can find out when we are at the end (skip if DB_GetNumRecords)
	$spec->{limit}++ unless $spec->{countrows};

	my ($fields, $sth) = DB_FetchListSelect($dbh, $spec);

	# if this is actually a call to DB_GetNumRecords()
	if($spec->{countrows}) {
		my $data = $sth->fetchrow_arrayref();
		$sth->finish or die $sth->errstr;
		return $data->[0];
	}

	# the idea of the %list hash, which then gets passed to GUI_ListTable
	# is that it is a self-contained description of the data. It shouldn't
	# be necessary to go look at db_tables and db_fields to figure out how
	# to display the data, so we need to provide all the required
	# information here
	my %list = (
		spec => $spec,
		data => [],
		fields => $fields,
		acl => defined $g{db_tables}{$spec->{table}}{acls}{$user} ?
			$g{db_tables}{$spec->{table}}{acls}{$user} : ''
	);
	my $col = 0;
	my @columns;
	for my $f (@{$list{fields}}) {
		$columns[$col] = {
			field     => $f,
			desc      => $g{db_fields}{$v}{$f}{desc},
			align     => $g{db_fields}{$v}{$f}{align},
			hide_list => $g{db_fields}{$v}{$f}{hide_list},
			markup    => $g{db_fields}{$v}{$f}{markup},
			type      => $g{db_fields}{$v}{$f}{type},
		};
		$col++;
	}
	$list{columns} = \@columns;

	# fetch the data
	while(my $data = $sth->fetchrow_arrayref()) {
		my $col;
		my @row;
		for($col=0; $col<=$#$data; $col++) {
			push @row, $spec->{export} ? $data->[$col] :
				DB_DB2HTML($data->[$col], $columns[$col]{type});
		}

		push @{$list{data}}, [ $data->[0], \@row ];
	}
	die $sth->errstr if $sth->err;

	# are we at the end?
	if(scalar @{$list{data}} != $spec->{limit}) {
		$list{end} = 1
	}
	else {
		$list{end} = 0;
		pop @{$list{data}}; # we did get one more than requested
	}
	# decrement temporarily incremented LIMIT count
	$spec->{limit}--;

	return \%list;
}

sub DB_GetRecord($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;
	my $record = shift;

	my @fields_list = @{$g{db_fields_list}{$table}};
	#update the query to prevent listing binary data
	my @select_fields = @fields_list;
	for(@select_fields){
		if($g{db_fields}{$table}{$_}{type} eq 'bytea'){
			$_ = "substring($_,1,position(' '::bytea in $_)-1)";
		}
	}

	# fetch raw data
	my $data;
	my $query = "SELECT ";
	$query .= join(', ',@select_fields); # @{$g{db_fields_list}{$table}});
	$query .= " FROM $table WHERE ${table}_id = $id";
	my $sth;
	$sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	$data = $sth->fetchrow_arrayref() or
		die ($sth->err ? $sth->errstr : "Record not found ($query)\n");

	# transorm raw data into record
	my $i=0;
	for(@fields_list) {
		$record->{$_} = $data->[$i];
		$i++;
	}
	
	return 1;
}

sub DB_ID2HID($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;

	return unless defined $id and $id ne '';
	my $q = "SELECT ${table}_hid FROM ${table} WHERE ${table}_id = '$id'";
	my $sth = $dbh->prepare_cached($q) or die $dbh->errstr;
	$sth->execute or die $sth->errstr;
	my $d = $sth->fetchrow_arrayref();
	die $sth->errstr if $sth->err;

	return $d->[0];
}

sub DB_HID2ID($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $hid = shift;

	return unless defined $hid and $hid ne '';
	my $q = "SELECT ${table}_id FROM ${table} WHERE ${table}_hid = ?";
	my $sth = $dbh->prepare_cached($q) or die $dbh->errstr;
	$sth->execute($hid) or die $sth->errstr;
	my $d = $sth->fetchrow_arrayref();
	die $sth->errstr if $sth->err;

	return $d->[0];
}

sub DB_PrepareData($$)
{
	$_ = shift;
	$_ = '' unless defined $_;
	my $type = shift;
	s/^\s+//;
	s/\s+$//;

	# quoting for the SQL statements
	# obsolete since migration to placeholder querys
	# insert ... values(?,?) etc.
	
	
	#s/\\/\\\\/g;
	#s/'/\\'/g;

	if($type eq 'bool') {
		$_ = ($_ ? '1' : '0');
	}

	# this is a hack. It should be implemented in GUI.pm or
	# (better) with a widget-type
	if($type eq 'numeric') {
		if(/^(\d*):(\d+)$/) {
			my $hours = $1 or 0;
			my $mins = $2;
			$_ = $hours+$mins/60;
		}
	}

	if($_ eq '') {
		$_ = undef;
	}

	return $_;
}

sub DB_Record2DB($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;
	my $dbdata = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_fields_list}{$table}};

	my $f;
	for $f (@fields_list) {
		my $type = $fields->{$f}{type};
		my $data = $record->{$f};

		$data = DB_PrepareData($data, $type);

		$dbdata->{$f} = $data;
	}
}

sub DB_ExecQuery($$$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $query = shift;
	my $data = shift;
	my $fields = shift;
	
	my @stringtypes = qw(
		date
		time
		timestamp
		int2
		int4
		int8
		numeric
		float8
		bpchar
		text
		name
		bool
	);
	my @binarytypes = ('bytea');
	
	
	
	my %datatypes = ();
	for(@$fields){
		$datatypes{$_} = $g{db_fields}{$table}{$_}{type};
	}
	
	#print "<!-- Executing: $query -->\n";
	
	my $sth = $dbh->prepare($query) or die $dbh->errstr;
	
	my $paramnumber = 1;
	for(@$fields){
		my $type = $datatypes{$_};
		my $data = $data->{$_};
		if(grep (/^$type$/,@stringtypes)){
			$sth->bind_param($paramnumber,$data);
		}
		if(grep (/^$type$/,@binarytypes)){
			#note the reference to the large blob
			$sth->bind_param($paramnumber,$$data,{ pg_type => DBD::Pg::PG_BYTEA });
		}
		$paramnumber++;
	}
	my $res = $sth->execute() or do {
		# report nicely the error
		$g{db_error}=$sth->errstr; return undef;
	};
	if($res ne 1 and $res ne '0E0') {
		die "Number of rows affected is not 1! ($res)";
	}
	return 1;
}

sub DB_AddRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = grep !/${table}_id/, @{$g{db_fields_list}{$table}};
	
	# filter-out readonly fields
	@fields_list = grep { not defined $g{db_fields}{$table}{$_}{widget} or $g{db_fields}{$table}{$_}{widget} ne 'readonly' } @fields_list;

	my %dbdata = ();
	DB_Record2DB($dbh, $table, $record, \%dbdata);

	my $query = "INSERT INTO $table (";
	$query   .= join(', ',@fields_list);
	$query   .= ") VALUES (";
	my $first = 1;
	for(@fields_list) {
		if($first) {
			$first = 0;
		}
		else {
			$query .= ', ';
		}
		$query .= '?'
	}
	$query   .= ")";
	return DB_ExecQuery($dbh,$table,$query,\%dbdata,\@fields_list);
}

sub DB_UpdateRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_fields_list}{$table}};

	# filter-out readonly fields
	@fields_list = grep { $g{db_fields}{$table}{$_}{widget} ne 'readonly' } @fields_list;

	# filter-out bytea fields that have value=undef
	# these should keep the value that is now in the database.
	@fields_list = grep { defined($record->{$_}) or $g{db_fields}{$table}{$_}{type} ne 'bytea' } @fields_list;
	
	my %dbdata = ();
	DB_Record2DB($dbh, $table, $record, \%dbdata);


	my @updates;
	my $query = "UPDATE $table SET ";
	my @updatefields;
	for(@fields_list) {
		if($_ eq "id") { next; }
		if($_ eq "${table}_id") { next; }
		push @updates,"$_ = ?";
		push @updatefields,$_;
	}
	$query .= join(', ',@updates);
	$query .= " WHERE ${table}_id = $record->{id}";

	return DB_ExecQuery($dbh,$table,$query,\%dbdata,\@updatefields);
}

sub DB_GetCombo($$$)
{
	my $dbh = shift;
	my $combo_view = shift;
	my $combo_data = shift;

	my $query = "SELECT id, text FROM $combo_view";
	if(defined $g{db_tables}{$combo_view}{meta_sort}) {
		$query .= " ORDER BY meta_sort";
	}
	else {
		$query .= " ORDER BY text";
	}
	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	my $data;
	while($data = $sth->fetchrow_arrayref()) {
		$data->[0]='' unless defined $data->[0];
		$data->[1]='' unless defined $data->[1];
		push @$combo_data, [$data->[0], $data->[1]];
	}
	die $sth->errstr if $sth->err;

	return 1;
}

sub DB_DeleteRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;

	my $query = "DELETE FROM $table WHERE ${table}_id = $id";

	#print "<!-- Executing: $query -->\n";
	my $sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or do {
		# report nicely the error
		$g{db_error}=$sth->errstr; return undef;
	};

	return 1;
}

sub DB_GetBlobName($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;

	my $idcolumn = "${table}_id";
	if($table =~ /\w+_list/){
		#tables that end with _list are actualy views and have their
		# id column as the first column of the view
		$idcolumn = $g{db_fields_list}{$table}[0];
	}

	my $query = "Select substring($field,1,position(' '::bytea in $field)-1) from $table where $idcolumn=$id";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or return undef;
	return $data->[0];
}

sub DB_GetBlobType($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;

	my $idcolumn = "${table}_id";
	if($table =~ /\w+_list/){
		#tables that end with _list are actualy views and have their
		# id column as the first column of the view
		$idcolumn = $g{db_fields_list}{$table}[0];
	}

	my $query = "Select substring($field,position(' '::bytea in $field)+1,position('#'::bytea in $field)-(position(' '::bytea in $field)+1)) from $table where $idcolumn=$id";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or return undef;
	return $data->[0];
}

sub DB_DumpBlob($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;

	my $idcolumn = "${table}_id";
	if($table =~ /\w+_list/){
		#tables that end with _list are actualy views and have their
		# id column as the first column of the view. 
		$idcolumn = $g{db_fields_list}{$table}[0];
	}
	
	my $query = "Select position('#'::bytea in $field)+1,octet_length($field) from $table where $idcolumn=$id";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return -1;
	my $data = $sth->fetchrow_arrayref() or return -1;
	my $startpos = $data->[0] || 0;
	my $strlength = $data->[1] || 0;
	$sth->finish();
	my $endpos = $strlength-($startpos-1);
	my $dumpquery = "Select substring($field,?,?) from $table where $idcolumn=$id";
	my $dumpsth = $dbh->prepare($dumpquery);
	my $blobdata;
	$dumpsth->execute($startpos,$endpos) or return -1;
	$blobdata = $dumpsth->fetchrow_arrayref() or return -1;
	# I know it is not nice to do the print here but I don't want to make the memory footprint
	# to large so returning the blob to a GUI routine is not possible.
	print $blobdata->[0];
	return 1;
}

sub DB_RawField($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;

	my $query = "Select $field from $table where ${table}_id = $id";
	# print STDERR $query."\n";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or return undef;
	return $data->[0];
}

sub DB_DumpTable($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $view = defined $g{db_tables}{"${table}_list"} ?
			"${table}_list" : $table;	
	my $atribs = shift;

	my @fields = @{$g{db_fields_list}{$view}};
	# update the query to prevent listing binary data
	my @select_fields = @fields;
	for(@select_fields){
		if($g{db_fields}{$view}{$_}{type} eq 'bytea'){
			$_ = "substring($_,1,position(' '::bytea in $_)-1)";
		}
	}

	my $query = "SELECT ";
	$query .= join(', ',@select_fields);
	$query .= " FROM $view";
	
	# fix this for placeholders

	my $first = 1;
	for my $field (keys(%$atribs)){
		if($first){
			$query .= " where ";
		}else{
			$query .= " and ";
		}
		my $value = $atribs->{$field};
		my $type = $g{db_fields}{$view}{$field}{type};
		if($type eq 'date') {
			$query .= " $field = '$value'";
		}
		elsif($type eq 'bool') {
			$query .= " $field = '$value'";
		}
		else {
			$query .= " $field ~* '.*$value.*'";
		}
	}

	my $sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;

	my (@row, $data);
	
	$data=$sth->rows."\n";
	
	$first = 1;
	my $numcolumns = scalar @select_fields;
	while(@row = $sth->fetchrow_array()) {
		$first = 1;
		for (0..$numcolumns-1){
			my $field=$row[$_];
			if(!$field||$field eq ""){
				$field = " ";
			}
			
			if(not $first){
				$data.="\t";
			}
			$first = 0;
			$field =~ s/\t/\&\#09\;/gm;
			$field =~ s/\n/\&\#10\;/gm;
			$field =~ s/[\r\f]//gm;
			
			$data .= $field;
		}
		$data .= "\n";
	}
	$sth->finish();
	if(length($data)>20000){
		$data = "Resultset exeeds desirable size.\n";
	}
	return $data;
}

1;

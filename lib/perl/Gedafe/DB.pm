# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::DB;
use strict;

#use Data::Dumper;
use Gedafe::Global qw(%g);

use DBI;
use DBD::Pg;

# use DBI;# done in start.pl

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(
	DB_Connect
	DB_FetchList
	DB_GetRecord
	DB_AddRecord
	DB_UpdateRecord
	DB_GetCombo
	DB_DeleteRecord
	DB_GetDefault
	DB_ID2HID
	DB_HID2ID
);

sub DB_Init($$)
{
	my $user = shift;
	my $pass = shift;
	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass) or return undef;
	my $sth;

	# tmp vars
	my $query;
	my $data;
	my $table;
	my $field;

#AND not exists (select 1 from pg_views where viewname = c.relname)

	# tables
	$g{db_tables} = {};
	$query = <<'END';
SELECT c.relname
FROM pg_class c
WHERE c.relkind = 'r'
AND c.relname !~ '^pg_'
END
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		$g{db_tables}{$data->[0]} = {};
	}
	$sth->finish;

	# descriptions + db_editable_tables_list
	$query = <<'END';
SELECT c.relname, d.description 
FROM pg_class c, pg_description d
WHERE c.relkind = 'r'
AND c.relname !~ '^pg_'
AND c.relname !~ '(^meta_|(_combo|_list|_rep)$)'
AND c.oid = d.objoid
ORDER BY d.description
END
	$g{db_editable_tables_list} = [];
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		push @{$g{db_editable_tables_list}}, "$data->[0]";
		$g{db_tables}{$data->[0]}{desc} = $data->[1];
	}
	$sth->finish;

	# reports
	$query = <<'END';
SELECT c.relname, d.description
FROM pg_class c, pg_description d
WHERE c.relkind = 'r'
AND c.relname !~ '^pg_'
AND c.relname ~ '_rep$'
AND c.oid = d.objoid
ORDER BY d.description
END
	$g{db_report_views} = [];
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		push @{$g{db_report_views}}, "$data->[0]";
		$g{db_tables}{$data->[0]}{desc} = $data->[1];
	}
	$sth->finish;

	# meta tables
	$query = 'SELECT meta_tables_table, meta_tables_filterfirst, meta_tables_hide FROM meta_tables';
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		next if not defined $g{db_tables}{$data->[0]};
		$g{db_tables}{$data->[0]}{filterfirst} = $data->[1];
		if($data->[2]) { @{$g{db_editable_tables_list}} = grep {$_ ne $data->[0]} @{$g{db_editable_tables_list}}; }
	}
	$sth->finish;

	# fields
	$query = <<'END';
SELECT a.attname, t.typname, a.attnum, a.atthasdef
FROM pg_class c, pg_attribute a, pg_type t
WHERE c.relname = ? AND a.attnum > 0
AND a.attrelid = c.oid AND a.atttypid = t.oid
ORDER BY a.attnum
END
	$g{db_fields} = {};
	$g{db_fields_list} = {};
	$sth = $dbh->prepare($query);
	foreach $table (keys %{$g{db_tables}}) {
		#next if $table =~ /(^meta_|_combo$)/;
		#print "<!-- Executing: $query with $table -->\n";
		$sth->execute($table) or return undef;
		while ($data = $sth->fetchrow_arrayref()) {
			if($data->[0] eq 'meta_sort') {
				$g{db_tables}{$table}{meta_sort}=1;
			}
			else {
				push @{$g{db_fields_list}{$table}}, $data->[0];
				$g{db_fields}{$table}{$data->[0]} = {
					type => $data->[1],
					desc => $data->[0],
					attnum => $data->[2],
					atthasdef => $data->[3],
				};
			}
		}
	}
	$sth->finish;

	# field descriptions
	$query = <<'END';
SELECT a.attname, d.description
FROM pg_class c, pg_attribute a, pg_description d
WHERE c.relname = ? AND a.attnum > 0
AND a.attrelid = c.oid
AND a.oid = d.objoid
END
	$sth = $dbh->prepare($query);
	foreach $table (keys %{$g{db_tables}}) {
		$sth->execute($table) or return undef;
		while ($data = $sth->fetchrow_arrayref()) {
			$g{db_fields}{$table}{$data->[0]}{desc}=$data->[1];
		}
	}
	$sth->finish;

	# defaults
	$query = <<'END';
SELECT d.adsrc FROM pg_attrdef d, pg_class c WHERE
c.relname = ? AND c.oid = d.adrelid AND d.adnum = ?;
END
	$sth = $dbh->prepare($query);
	foreach $table (keys %{$g{db_tables}}) {
		foreach $field (@{$g{db_fields_list}{$table}}) {
			if(! $g{db_fields}{$table}{$field}{atthasdef}) { next; }
			$sth->execute($table, $g{db_fields}{$table}{$field}{attnum}) or return undef;
			my $d = $sth->fetchrow_arrayref();
			$g{db_fields}{$table}{$field}{default} = $d->[0];
			$sth->finish;
		}
	}

	# meta fields
	my %meta_fields;
	#$query = 'SELECT meta_fields_field, meta_fields_widget, meta_fields_copy FROM meta_fields';
	$query = 'SELECT * FROM meta_fields';
	$sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_hashref()) {
		my $field = $data->{meta_fields_field};
		if(defined $data->{meta_fields_widget}) {
			my $d = $data->{meta_fields_widget};
			$d =~ s/^\s+//; $d=~s/\s+$//;
			$meta_fields{$field}{widget} = $d;
		}
		if(defined $data->{meta_fields_copy}) {
			$meta_fields{$field}{copy} = $data->{meta_fields_copy};
		}
		else {
			$meta_fields{$field}{copy} = 0;
		}
		if(defined $data->{meta_fields_sortfunc}) {
			my $d = $data->{meta_fields_sortfunc};
			$d =~ s/^\s+//; $d=~s/\s+$//;
			$meta_fields{$field}{sortfunc} = $d;
		}
	}
	$sth->finish;


	# foreign-key constraints (REFERENCES)
	$query = <<'END';
SELECT tgargs from pg_trigger, pg_proc where pg_trigger.tgfoid=pg_proc.oid AND pg_trigger.tgname
LIKE 'RI_ConstraintTrigger%' AND pg_proc.proname = 'RI_FKey_check_ins'
END
	$sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		my @d = split(/\\000/,$$data[0]);
		$meta_fields{$d[4]}{reference} = $d[2];
	}
	$sth->finish;

#	print "\n";
#	print Dumper(\%meta_fields);

	# combo
	$query = <<'END';
SELECT 1
FROM pg_class c
WHERE c.relkind = 'r'
AND c.relname = ?
END
	$sth = $dbh->prepare($query);
	foreach $table (keys %{$g{db_tables}}) {
		#print "<!-- Executing: $query with ${table}_combo -->\n";
		$sth->execute("${table}_combo");
		if($sth->rows==0) { next; }
		$g{db_tables}{$table}{combo}=1;
	}
	$sth->finish;

	# hid
	foreach $table (keys %{$g{db_tables}}) {
		if(exists $g{db_fields}{$table}{"${table}_hid"}) {
			$g{db_tables}{$table}->{hid} = 1;
		}
	}

	# go through every table and field and fill-in:
	# - table information in reference fields
	# - meta information from meta_fields
	table: foreach $table (keys %{$g{db_tables}}) {
		field: foreach $field (@{$g{db_fields_list}{$table}}) {
			my $f = $g{db_fields}{$table}{$field};
			if(defined $meta_fields{$field}) {
				my $m = $meta_fields{$field};
				$f->{widget}    = $m->{widget}    if exists $m->{widget};
				$f->{reference} = $m->{reference} if exists $m->{reference};
				$f->{copy}      = $m->{copy}      if exists $m->{copy};
				$f->{sortfunc}  = $m->{sortfunc}  if exists $m->{sortfunc};
			}
			if(! exists $f->{reference}) {
				next field;
			}
			my $ref = $f->{reference};
			if(! exists $g{db_tables}{$ref}) {
				next field;
			}
			my $rt = $g{db_tables}{$ref};

			if(exists $rt->{combo}) {
				$f->{ref_combo} = 1;
			}
			if(exists $rt->{hid}) {
				$f->{ref_hid} = 1;
			}
		}
	}

	# users
	my %db_users;
	$query = 'SELECT usename, usesysid FROM pg_user';
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		$db_users{$data->[1]} = $data->[0];
	}
	$sth->finish;

	# groups
	my %db_groups;
	$query = 'SELECT groname, grolist FROM pg_group';
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		my $g = $data->[1];
		if(defined $g) {
			$g =~ s/^{(.*)}$/$1/;
			my @g = split /,/, $g;
			$db_groups{$data->[0]} = [@db_users{@g}];
		}
		else {
			$db_groups{$data->[0]} = [];
		}
	}
	$sth->finish;

	# acls
	$query = "SELECT relname, relacl FROM pg_class WHERE relkind = 'r' AND relname !~ '^pg_'";
	$sth = $dbh->prepare($query) or return undef;
	#print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		if(not defined $data->[0]) { next; }
		if(not defined $data->[1]) { next; }
		my $acldef = $data->[1];
		$acldef =~ s/^{(.*)}$/$1/;
		my @acldef = split(',', $acldef);
		map { s/^"(.*)"$/$1/ } @acldef;
		my %acl_level = ();
		acl: foreach(@acldef) {
			/(.*)=(.*)/;
			my $who = $1; my $what = $2;
			if($who eq '') {
				foreach(values %db_users) {
					if(not defined $acl_level{$_}) {
						$g{db_tables}{$data->[0]}{acls}{$_} = $what;
						$acl_level{$_} = 1;
					}
				}
			}
			elsif($who =~ /^group (.*)$/) {
				foreach(@{$db_groups{$1}}) {
					if(not defined $acl_level{$_} or $acl_level{$_} < 2) {
						$g{db_tables}{$data->[0]}{acls}{$_} = $what;
						$acl_level{$_} = 2;
					}
				}
			}
			else {
				$g{db_tables}{$data->[0]}{acls}{$who} = $what;
			}
		}
	}
	$sth->finish;

#	print "\n";
#	print Dumper($g{db_tables});

#	$dbh->disconnect;
}

sub DB_Connect($$) {
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

	if($g{db_fields}{$table}{$field}{ref_hid}) {
		my $ref = $g{db_fields}{$table}{$field}{reference};
		$query = "${ref}_id2hid($query)";
	}

	$query = "SELECT ".$query;

	my $sth = $dbh->prepare_cached($query) or return undef;
	print "<!-- Executing: $query -->\n";
	$sth->execute() or return undef;
	my $d = $sth->fetchrow_arrayref();
	my $default = $d->[0];
	$sth->finish or return undef;

	return $default;
}

sub DB_FetchList($$$$;%)
{
	my $sth = shift;
	my $dbh = shift;
	my $table = shift;
	my $errorref = shift;
	my %otherargs = @_;

	my $orderby = $otherargs{'-orderby'};
	my $descending = $otherargs{'-descending'};
	my $limit = $otherargs{'-limit'};
	my $offset = $otherargs{'-offset'};
	my $search_field = $otherargs{'-search_field'};
	my $search_value = $otherargs{'-search_value'};
	my $filter_field = $otherargs{'-filter_field'};
	my $filter_value = $otherargs{'-filter_value'};
	my $fieldsref = $otherargs{'-fields'};

	my @fields;
	if(defined $fieldsref) {
		@fields = @$fieldsref;
	}
	else {
		@fields = @{$g{db_fields_list}{$table}};
	}

	# construct statement handle
	if(! $$sth) {
		my $query = "SELECT ";
		$query .= join(', ',@fields);
		$query .= " FROM $table";
		if(defined $search_field and defined $search_value
			and $search_field ne '' and $search_value ne '')
		{
			my $type = $g{db_fields}{$table}{$search_field}{type};
			if($type eq 'date') {
				$query .= " WHERE $search_field = '$search_value'";
			}
			elsif($type eq 'bool') {
				$query .= " WHERE $search_field = '$search_value'";
			}
			else {
				$query .= " WHERE $search_field ~ '$search_value'";
			}
			if(defined $filter_field and defined $filter_value) {
				$query .= " AND";
			}
		}
		if(defined $filter_field and defined $filter_value) {
			$query .= " WHERE $filter_field = '$filter_value'";
		}
		if(defined $orderby and $orderby ne '') {
			if(defined $g{db_fields}{$table}{$orderby}{sortfunc}) {
				my $f = $g{db_fields}{$table}{$orderby}{sortfunc};
				$query .= " ORDER BY $f($orderby)";
			}
			else {
				$query .= " ORDER BY $orderby";
			}
			if(defined $descending and $descending) {
				$query .= " DESC";
			}
			if(defined $g{db_tables}{$table}{meta_sort}) {
				$query .= ", $table.meta_sort";
			}
		}
		elsif(defined $g{db_tables}{$table}{meta_sort}) {
			$query .= " ORDER BY $table.meta_sort";
		}
		if(defined $limit) {
			$query .= " LIMIT $limit";
		}
		if(defined $offset) {
			$query .= " OFFSET $offset";
		}
		$$sth = $dbh->prepare_cached($query) or goto ERROR;
		print "<!-- Executing: $query -->\n";
		$$sth->execute() or goto ERROR;
	}

	my $data = $$sth->fetchrow_arrayref();
	if(! defined $data) {
		#$$sth->finish or goto ERROR;
		return undef;
	}

	my @html_data;
	my $f;
	my $i=0;
	for $f (@fields) {
		my $type = $g{db_fields}{$table}{$f}{type};
		push @html_data, DB_DB2HTML($data->[$i],$type);
		$i++;
	}

	return \@html_data;

ERROR:
	$$errorref=$dbh->errstr;
	return undef;
}

sub DB_GetRecord($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;
	my $record = shift;

	my @fields_list = @{$g{db_fields_list}{$table}};

	# fetch raw data
	my $data;
	my $query = "SELECT ";
	$query .= join(', ', @fields_list);
	$query .= " FROM $table WHERE ${table}_id = $id";
	my $sth;
	$sth = $dbh->prepare_cached($query) or return undef;
	$sth->execute() or return undef;
	$data = $sth->fetchrow_arrayref() or return undef;
	$sth->finish or return undef;

	# transorm raw data into record
	my %dbdata = ();
	my $i=0;
	foreach(@fields_list) {
		$dbdata{$_} = $data->[$i];
		$i++;
	}
	DB_DB2Record($dbh, $table, \%dbdata, $record) or return undef;
	
	return 1;
}

sub DB_ID2HID($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $data = shift;

	if((not defined $data) or  ($data eq '') or (not defined $g{db_fields}{$table}{$field}{ref_hid})) { return $data; }
	my $ref = $g{db_fields}{$table}{$field}{reference};
	my $q = "SELECT ${ref}_id2hid('$data')";
	my $sth = $dbh->prepare_cached($q) or return undef;
	$sth->execute or return undef;
	my $d = $sth->fetchrow_arrayref();
	$sth->finish;
	return $d->[0];
}

sub DB_HID2ID($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $data = shift;

	if((not defined $data) or  ($data eq '') or (not defined $g{db_fields}{$table}{$field}{ref_hid})) { return $data; }
	my $ref = $g{db_fields}{$table}{$field}{reference};
	my $q = "SELECT ${ref}_hid2id('$data')";
	my $sth = $dbh->prepare_cached($q) or return undef;
	$sth->execute or return undef;
	my $d = $sth->fetchrow_arrayref();
	$sth->finish;
	return $d->[0];
}

sub DB_DB2HTML($$)
{
	$_ = shift;
	$_ = '' unless defined $_;
	my $type = shift;
	s/^\s+//;
	s/\s+$//;

	if($type eq 'bool') {
		$_ = (/^(t|true|y|yes|TRUE|1)$/ ? '1' : '0');
	}

	return $_;
}

sub DB_HTML2DB($$)
{
	$_ = shift;
	$_ = '' unless defined $_;
	my $type = shift;
	s/^\s+//;
	s/\s+$//;

	# quoting for the SQL statements
	s/\\/\\\\/g;
	s/'/\\'/g;

	if($type eq 'bool') {
		$_ = ($_ ? '1' : '0');
	}

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

sub DB_DB2Record($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $dbdata = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_fields_list}{$table}};

	my $f;
	foreach $f (@fields_list) {
		my $type = $fields->{$f}{type};
		my $data = $dbdata->{$f};
		
		$data = DB_DB2HTML($data, $type);

		$data = DB_ID2HID($dbh, $table, $f, $data);
		$record->{$f} = $data;
	}
	return 1;
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
	foreach $f (@fields_list) {
		my $type = $fields->{$f}{type};
		my $data = $record->{$f};

		$data = DB_HTML2DB($data, $type);
		$data = DB_HID2ID($dbh, $table, $f, $data);
		$dbdata->{$f} = $data;
	}

	return 1;
}

sub DB_AddRecord($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;
	my $err = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = grep !/${table}_id/, @{$g{db_fields_list}{$table}};
	
	# filter-out readonly fields
	@fields_list = grep { not defined $g{db_fields}{$table}{$_}{widget} or $g{db_fields}{$table}{$_}{widget} ne 'readonly' } @fields_list;

	my %dbdata = ();
	DB_Record2DB($dbh, $table, $record, \%dbdata) or do {
		$$err=$dbh->errstr;
		return undef;
	};

	my $query = "INSERT INTO $table (";
	$query   .= join(', ',@fields_list);
	$query   .= ") VALUES (";
	my $first = 1;
	foreach(@dbdata{@fields_list}) {
		if($first) {
			$first = 0;
		}
		else {
			$query .= ', ';
		}
		if(defined $_) {
			$query .= "'$_'";
		}
		else {
			$query .= "NULL";
		}
	}
	#$query   .= join("', '",@dbdata{@fields_list});
	$query   .= ")";

	print "<!-- Executing: $query -->\n";
	my $sth = $dbh->prepare($query) or do {
		$$err=$dbh->errstr;
		return undef;
	};
	my $res = $sth->execute();
	if(not defined $res) {
		$$err=$dbh->errstr;
		return undef;
	}
	if($res != 1) {
		$$err = "Number of rows affected is not 1! ($res)";
		return undef;
	}
	$sth->finish or do {
		$$err=$dbh->errstr;
		return undef;
	};

	return 1;
}

sub DB_UpdateRecord($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;
	my $err = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_fields_list}{$table}};

	# filter-out readonly fields
	@fields_list = grep { $g{db_fields}{$table}{$_}{widget} ne 'readonly' } @fields_list;

	my %dbdata = ();
	DB_Record2DB($dbh, $table, $record, \%dbdata) or do {
		$$err = $dbh->errstr;
		return undef;
	};

	my @updates;
	my $query = "UPDATE $table SET ";
	foreach(@fields_list) {
		if($_ eq "id") { next; }
		if($_ eq "${table}_id") { next; }
		if(defined $dbdata{$_}) {
			push @updates, "$_ = '$dbdata{$_}'";
		}
		else {
			push @updates, "$_ = NULL";
		}
	}
	$query .= join(', ',@updates);
	$query .= " WHERE ${table}_id = $record->{id}";

	print "<!-- Executing: $query -->\n";
	my $sth = $dbh->prepare($query) or do {
		$$err = $dbh->errstr;
		return undef;
	};
	my $res = $sth->execute();
	if(not defined $res) {
		$$err = $dbh->errstr;
		return undef;
	}
	if($res != 1) {
		$$err = "Number of rows affected is not 1! ($res)";
		return undef;
	}
	$sth->finish or do {
		$$err = $dbh->errstr;
		return undef;
	};

	return 1;
}

sub DB_GetCombo($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $combo = shift;

	my $comboname = "${table}_combo";
	my $query = "SELECT id, text FROM $comboname";
	if(defined $g{db_tables}{$comboname}{meta_sort}) {
		$query .= " ORDER BY meta_sort";
	}
	else {
		$query .= " ORDER BY id";
	}
	my $sth = $dbh->prepare_cached($query) or return undef;
	$sth->execute() or return undef;
	my $data;
	while($data = $sth->fetchrow_arrayref()) {
		my $key = DB_DB2HTML($data->[0],'text');
		push @$combo, [$key, DB_DB2HTML($data->[1],'text')];
	}
	#$sth->finish;
	return 1;
}

sub DB_DeleteRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;

	my $query = "DELETE FROM $table WHERE ${table}_id = $id";

	print "<!-- Executing: $query -->\n";
	my $sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;
	#$sth->finish or return undef;

	return 1;
}

1;
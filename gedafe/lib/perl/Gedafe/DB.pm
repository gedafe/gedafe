# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::DB;
use strict;
use Gedafe::Global qw(%g);
use Data::Dumper;

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
	DB_GetMNCombo
	DB_DeleteRecord
	DB_GetDefault
	DB_ParseWidget
	DB_ID2HID
	DB_HID2ID
	DB_GetBlobType
	DB_GetBlobName
	DB_DumpBlob
	DB_RawField
	DB_DumpJSITable
	DB_DumpTable
	DB_FetchReferencedId
	DB_ReadDatabase
);


sub DB_AddRecord($$$);
sub DB_Connect($$$);
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
sub DB_GetMNCombo($$$$$);
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
sub DB_ReadSchemapath($$$);
sub DB_ReadTableAcls($$);
sub DB_ReadTables($$);
sub DB_Record2DB($$$$);
sub DB_UpdateRecord($$$);
sub DB_Widget($$);
sub DB_filenameSql($);

my %type_widget_map = (
	'date'      => 'text(size=12)',
	'time'      => 'text(size=12)',
	'timestamp' => 'text(size=22)',
	'timestamptz' => 'text(size=28)',
	'int2'      => 'text(size=6)',
	'int4'      => 'text(size=12)',
	'int8'      => 'text(size=12)',
	'numeric'   => 'text(size=12)',
	'float4'    => 'text(size=12)',
	'float8'    => 'text(size=12)',
	'bpchar'    => 'text(size=40)',
	'text'      => 'text',
	'name'      => 'text(size=20)',
	'bool'      => 'checkbox',
	'bytea'     => 'file'
);


sub DB_Init($$)
{
	my ($user, $pass) = @_;
	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass) or
		return undef;


	# read database
	$g{db_database} = DB_ReadDatabase($dbh);
	
	# set and store schema search path
	$g{conf}{visibleschema} 
		= DB_ReadSchemapath($dbh,$g{conf},$g{db_database}{version});

	# read tables
	$g{db_tables} = DB_ReadTables($dbh, $g{db_database});
	defined $g{db_tables} or return undef;

	# order tables
	$g{db_tables_list} = [ sort { $g{db_tables}{$a}{desc} cmp
		$g{db_tables}{$b}{desc} } keys %{$g{db_tables}} ];

	# read table acls
	DB_ReadTableAcls($dbh, $g{db_tables}) or return undef;

	# read fields adding information about virtual fields into $g{db_mnfields}
	($g{db_fields},$g{db_mnfields}) = DB_ReadFields($dbh, $g{db_database}, $g{db_tables});
	defined $g{db_fields} or return undef;

	# order fields
	for my $table (@{$g{db_tables_list}}) {
		$g{db_fields_list}{$table} =
			[ sort { $g{db_fields}{$table}{$a}{order} <=>
				$g{db_fields}{$table}{$b}{order} }
				keys %{$g{db_fields}{$table}}
			];
	}



#	Here you can use Dumper to inspect parts of $g
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

sub DB_ReadSchemapath($$$){

	my $dbh  = shift;
	my $conf = shift;
	my $dbversion = shift;
	my %visibleschema=();

	# set schema search path. 
	if( $dbversion >= 7.2) {
		my $realpath;
		if (defined  $conf->{schema}) {
			if (defined $conf->{schema_search_path})   {
			 	$realpath = $conf->{schema_search_path};
				
			} else { # Schema Search path set to default schema
				$realpath ="'" . $conf->{schema} . "'" ;
			}
		} else {	# No default Schema defined	
			$conf->{schema}='public';
			$realpath .=" '\$user', 'public'";
			if (defined $conf->{schema_search_path})   {
				print STDERR "Gedafe: Warning: No schema ",
					"parameter in call of Start()\n";
				print STDERR "Gedafe: Warning: Schema search",
					" path dropped\n"; 
			}
		}
		my $query = "SET SEARCH_PATH TO ". $realpath . ";\n"  ;
		$conf->{schemapathquery}=$query;

		my @REALPATH = split (/,/o , $realpath );
		for my $p ( @REALPATH ) {
			$p =~ s/\s//og; # trim whitespace
			$p =~ s/\'//og; # dequote
			$visibleschema{$p}=1;
		}
	}
	return \%visibleschema;
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
	if($database->{version} >= 7.3) {
	$query = <<END;
SELECT c.relname, n.nspname
FROM pg_class c, pg_namespace n
WHERE (c.relkind = 'r' OR c.relkind = 'v')
AND   (c.relname !~ '^pg_')
AND   (c.relnamespace = n.oid) 
AND   (n.nspname != 'information_schema')
END
	} else { # no schema support before 7.3
        $query = <<END;
SELECT c.relname
FROM pg_class c
WHERE (c.relkind = 'r' OR c.relkind = 'v')
AND   (c.relname !~ '^pg_')
END

	}
	$sth = $dbh->prepare($query) or return undef;
	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
		$tables{$data->[0]} = { };
		if($data->[0] =~ /^meta|(_list|_combo)$/) {
			$tables{$data->[0]}{hide} = 1;
		}
		if($database->{version} >= 7.2 ){
			# Save time to enumerate schemas . It is not nice
			# to write to $g here. But fast.
			# Enumerate only tables and schemas that are visible
			# per schema search path

			if (defined $g{conf}{visibleschema}{$data->[1]}) {
				if ( not $tables{$data->[0]}{hide} ){
					push (@{$g{tables_per_schema}{$data->[1]}}
					,$data->[0])
				}
			} else { # inside of invisible schema
				$tables{$data->[0]}{hide} = 1;
			}
	
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
		# reorder navi-link entries for speed. (Hack Alarm ?)
		if ( my ($num) = ($attr =~ m/^\s*quicklink\(([0-9])\)\s*/ ) ) {
		#print STDERR "quicklink (",$num,") =",$data->[2]," found\n";
			if ( my ($url,$icon,$alt)= 
			($data->[2] =~ m/foot\(\s*"([^"]*)"\s*,\s*"([^"]*)"\s*,\s*"([^"]*)"\s*\)/ )){

				#print STDERR "quicklink vals  $url, $icon, $alt found\n";
				$tables{$data->[0]}{has_quicklinks} = 1;
				$tables{$data->[0]}{quicklinks}[$num]{url}=$url;
				$tables{$data->[0]}{quicklinks}[$num]{icon}=$icon;
				$tables{$data->[0]}{quicklinks}[$num]{alt}=$alt;
					
			}
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
		next unless defined $tables->{$data->[0]};
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

	if(defined $f->{widget} and $f->{widget} eq 'jsisearch'){
		my $r  = $f->{reference};
		my $rt = $g{db_tables}{$r};
		defined $rt or die "table $f->{reference}, referenced from $f->{table}:$f->{field}, not found.\n";
		if(defined $fields->{$r}{"${r}_hid"}) {
			# Combo with HID
			return "hjsisearch(ref=$r)";
		}
		return "jsisearch(ref=$r)";
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
	if($type eq 'idcombo' or $type eq 'hidcombo' or $type eq 'combo') {
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
	if($type eq 'mncombo') {
		defined $args{'combo'} or
			die "widget $widget: mandatory argument 'combo' not defined";
	}
	if($type eq 'file2fs') {
		defined $args{'server'} or
			die "widget $widget: mandatory argument 'server' not defined";
	}
	return ($type, \%args);
}

sub DB_ReadFields($$$)
{
	my ($dbh, $database, $tables) = @_;
	my ($query, $sth, $data);
	my %fields = ();
	my %mnfields = ();

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
				$f->{javascript}= $m->{javascript};
				$f->{widget}	= $m->{widget};
				$f->{reference} = $m->{reference};
				$f->{copy}	  = $m->{copy};
				$f->{sortfunc}  = $m->{sortfunc};
				$f->{markup}	= $m->{markup};
				$f->{align}	 = $m->{align};
				$f->{hide_list} = $m->{hide_list};
				$f->{ordered} = $m->{ordered};
			}
			#if(! defined $f->{widget}) {
			$f->{widget} = DB_Widget(\%fields, $f);
			#}
		}
	}


	# meta virtual fields
	my %meta_mnfields = ();
	$query = <<'END';


SELECT meta_mncombo_atable, meta_mncombo_vfield, 
meta_mncombo_reference, a.attname
FROM meta_mncombo m, pg_class c, pg_attribute a
WHERE c.relname = meta_mncombo_reference AND a.attnum = 2 
AND a.attrelid = c.oid 
AND a.attname != ('........pg.dropped.' || a.attnum || '........')
END

	
	# to insert/update/delete data in M:N table we need to know real order of its fields
	#  
	# {mnfirstref_name} is the name of the table referenced by the first field of the M:N table
	# {mnfirstfield_name} is the name of the first field of the M:N table
	# {mnsecondfield_name} is the name of the second fileld of the M:N table
		
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		$meta_mnfields{lc($data->[0])}{lc($data->[1])}{atable} = lc($data->[0]);
		$meta_mnfields{lc($data->[0])}{lc($data->[1])}{btable} = _DB_GetMNComboSecondFieldReference($dbh,lc($data->[2]),lc($data->[0]));
		$meta_mnfields{lc($data->[0])}{lc($data->[1])}{reference} = lc($data->[2]);
		$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnfirstref_name} = _DB_GetMNComboFieldReference($dbh,lc($data->[2]),2);
		$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnsecondref_name} = _DB_GetMNComboFieldReference($dbh,lc($data->[2]),3);
			
		if (lc($data->[0]) eq $meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnfirstref_name}) {
			$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnfirstfield_name} =  lc($data->[3]);
			$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnsecondfield_name} = _DB_GetMNComboField($dbh,lc($data->[2]),3);
		}else{
			$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnfirstfield_name} =  _DB_GetMNComboField($dbh,lc($data->[2]),3);
			$meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnsecondfield_name} = lc($data->[3]);
		}
		
		defined $meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnfirstref_name} or
		die "ERROR: mnfield lc($data->[0])/lc($data->[3]) doesn't reference any table";
		
		defined $meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnsecondref_name} or
		die "ERROR: mnfield lc($data->[0])/ $meta_mnfields{lc($data->[0])}{lc($data->[1])}{mnsecondref_name} doesn't reference any table";
		my $table = lc($data->[0]);
		my $meta_mnfield = lc($data->[1]);
		my $mnf = $meta_mnfields{$table}{$meta_mnfield};
		
		$fields{$table}{$meta_mnfield} = ();
		$fields{$table}{$meta_mnfield}{widget} = $mnf->{widget};
		$fields{$table}{$meta_mnfield}{reference} = lc($data->[2]);
		$fields{$table}{$meta_mnfield}{virtual} = "true";
		
		my $vm = $meta_fields{$table}{$meta_mnfield};
		if(defined $vm) {
			$fields{$table}{$meta_mnfield}{order} = $vm->{order};
			$fields{$table}{$meta_mnfield}{desc} = $vm->{desc};
			$fields{$table}{$meta_mnfield}{copy} = $vm->{copy};
			$fields{$table}{$meta_mnfield}{sortfunc} = $vm->{sortfunc};
			$fields{$table}{$meta_mnfield}{markup} = $vm->{markup};
			$fields{$table}{$meta_mnfield}{align} = $vm->{align};
			$fields{$table}{$meta_mnfield}{widget} = $vm->{widget};
			$fields{$table}{$meta_mnfield}{hide_list} = $vm->{hidelist};
			$fields{$table}{$meta_mnfield}{ordered} = $vm->{ordered};
		}   
		
		defined $fields{$table}{$meta_mnfield}{widget} or  
		$fields{$table}{$meta_mnfield}{widget} = "mncombo(combo=".$meta_mnfields{lc($data->[0])}{lc($data->[1])}{btable}."_combo)";

		#hide tables from web page
		$g{db_tables}{lc($data->[3])}{hide} = "1";
	}
	$sth->finish;
	return \%fields, \%meta_mnfields;
}

sub DB_Connect($$$)
{
	my ($s, $user, $pass) = @_;

	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass)
		or return undef;

	if(not defined $g{db_meta_loaded}) {
		DB_Init($user, $pass) or return undef;
		$g{db_meta_loaded} = 1;
		#print STDERR "DB_Connect -> DB_Init succesful\n";
	}

	# Set Schema search path in case database conncetion is new.	
	# Can we really do that ? DB operator MUST touch all gedafe-cgi
	# scripts, after adding/changing schemas or evil things will happen. 
	$dbh->do($g{conf}{schemapathquery}) or 
		die "could not set search path";

	return $dbh;
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
	defined $g{db_fields_list}{$v}[0] or die "no such table: $v\n";

	#print STDERR "View $v\n seems to be defined\n";
	#print STDERR "First el in fieldlist : $g{db_fields_list}{$v}[0]\n";
	# go through fields and build field list for SELECT (...)
	my @fields = grep {$g{db_fields}{$v}{$_}{virtual} ne 'true'} @{$g{db_fields_list}{$v}};
	
	my @select_fields;
	for my $f (@fields) {
		if($g{db_fields}{$v}{$f}{type} eq 'bytea') {
			push @select_fields, DB_filenameSql($f);
		}
		else {
			push @select_fields, $f;
		}
	}
	
	if(!$g{db_tables}{$spec->{table}}{report} 
	   and !$spec->{export}
	   and $g{db_tables}{$spec->{table}}{meta}{showref}){
		#the list of tables that we want to find reference counts for
		my @showrefs = split(/,/,
					 $g{db_tables}{$spec->{table}}{meta}{showref});
		
		
		for my $showref(@showrefs){
			next unless(defined $g{db_tables}{$showref}{acls}{$spec->{user}} 
					and $g{db_tables}{$showref}{acls}{$spec->{user}}=~/r/);
			
			#now find the column that references us.
			my $refcolumn = undef;
			for my $refcol (@{$g{db_fields_list}{$showref}}){
				my $refcolref = $g{db_fields}{$showref}{$refcol}{reference};
				next if(!defined $refcolref);
				if( $refcolref eq 
					$spec->{table}){
					$refcolumn = $refcol;
				}
			}
			die($spec->{table}." not referenced from $showref in meta_tables showref") if(!defined $refcolumn);
			
			push @select_fields,"(select count(*) from $showref where $refcolumn = $select_fields[0]) as meta_rc_$showref";
			push @fields,"meta_rc_$showref#$refcolumn";
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

		if($spec->{search_field}=~/meta_rc_(.*)/){
			$query .= " WHERE $select_fields[0] in (select $spec->{table}_id from $spec->{table} WHERE $1 = ?)";
			push @query_parameters, "$spec->{search_value}";
		}elsif($type eq 'date') {
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
	# print STDERR  "$query\n";
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

sub DB_FetchReferencedId($$$$){
	my $s = shift;
	my $table = shift;
	my $column = shift;
	my $id = shift;
	my $dbh = $s->{dbh};
	my $query = "select $column as ref from $table where $table"."_id = ?";
	my $sth= $dbh->prepare($query);
	my $res = $sth->execute($id);
	my @data = $sth->fetchrow_array();
	return $data[0];
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
		my $ref = undef;
		my $reference = undef;
		if(defined $g{db_fields}{$spec->{table}}{$f}){
			$ref =  $g{db_fields}{$spec->{table}}{$f}{reference};
			#Create reference link only if user can read and write the table
			$reference = $ref if(defined $ref
					 and defined $g{db_tables}{$ref}{acls}{$user}
					 and $g{db_tables}{$ref}{acls}{$user} =~ /r/
					 and $g{db_tables}{$ref}{acls}{$user} =~ /w/);
		}
		if($f =~ /meta_rc_(.*)#(.*)/){
		   $columns[$col]
			= {field	 => $f,
			   desc	  => $1,
			   align	 => '"LEFT"',
			   refcount  => 1,
			   tar_field => $2,
			   type	  => 'int4'
			       
			  };
		}else{
		    $columns[$col]
			= {field     => $f,
			   desc      => $g{db_fields}{$v}{$f}{desc},
			   align     => $g{db_fields}{$v}{$f}{align},
			   hide_list => $g{db_fields}{$v}{$f}{hide_list},
			   markup    => $g{db_fields}{$v}{$f}{markup},
			   type      => $g{db_fields}{$v}{$f}{type},
			   reference => $reference,
			  };
		}
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

	#my @fields_list = @{$g{db_fields_list}{$table}};
	my ($fields_listref, $mnfields_listref) = _DB_GetFields($table);
	my @fields_list =  @$fields_listref;
	my @mnfields_list =  @$mnfields_listref;
	
	#update the query to prevent listing binary data
	my @select_fields = @fields_list;
	for(@select_fields){
		if($g{db_fields}{$table}{$_}{type} eq 'bytea'){
			$_ = DB_filenameSql($_);
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
	   # correct decimal commas to decimal points. This is a hack 
	   # that should be made configurable. Also 
	   # remove blanks and other non-numeric characters 			
	   if ($type eq 'numeric' ){
			 s/[.,]([\d\s]+)$/p$1/;
			 s/[,.]//g ;
			 s/p/./;
		 s/[-;_#\/\\|\s]//g
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
		if($type eq "bytea") {
			#note the reference to the large blob
			$sth->bind_param($paramnumber,$$data,{ pg_type => DBD::Pg::PG_BYTEA });
		}
		else {
			$sth->bind_param($paramnumber,$data);
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
	my ($fields_listref, $mnfields_listref) = _DB_GetFields($table);
	my @fields_list =  @$fields_listref;
	my @mnfields_list =  @$mnfields_listref;
	@fields_list = grep !/${table}_id/, @fields_list;
	
	# filter-out readonly fields
	@fields_list = grep { not defined $g{db_fields}{$table}{$_}{widget} or $g{db_fields}{$table}{$_}{widget} ne 'readonly' } @fields_list;

	my %dbdata = ();
	DB_Record2DB($dbh, $table, $record, \%dbdata);

	my $query = _DB_Insert($table, \@fields_list);
	my ($result,$oid) = DB_ExecQueryOID($dbh,$table,$query,\%dbdata,\@fields_list);
	
	my $ID = _DB_GetID($dbh,$table,$oid);
	if (defined $ID){
		if (scalar(@mnfields_list) ne 0 and $result){
			for my $vfield (@mnfields_list){       
        			my $mntable = $g{db_fields}{$table}{$vfield}{reference};
				#first field in mntable
				my $mntable_first = $g{db_mnfields}{$table}{$vfield}{mnfirstref_name};
                		@fields_list = @{$g{db_fields_list}{$mntable}};
				@fields_list = grep !/${mntable}_id/, @fields_list;
				
				if ( $g{db_fields}{$table}{$vfield}{ordered} eq "1"){
					@fields_list = grep !/${mntable}_order/, @fields_list;
					push @fields_list, "${mntable}_order";
				}

				my $fname = "field_".$vfield;
              
				my @mntable_fields = $g{s}{cgi}->param($fname);
                		if (scalar(@mntable_fields) ne 0){
					my $order = scalar(@mntable_fields);
						
					for my $val (@mntable_fields){
						my @mntable_row;
						if ( $mntable_first eq $table ){
							push @mntable_row, $ID;
							push @mntable_row, $val;
						}else {
							push @mntable_row, $val;
							push @mntable_row, $ID;
						}
						if ( $g{db_fields}{$table}{$vfield}{ordered} eq "1"){
							push @mntable_row, $order--;
						}
						print STDERR ($query);
						$query = _DB_InsertMN($mntable, \@fields_list,\@mntable_row);
						
						DB_ExecQueryMN($dbh,$mntable,$query,\@fields_list);
					}
				}
			}
		}
	}
	return $result;
}

sub DB_UpdateRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my ($fields_listref, $mnfields_listref) = _DB_GetFields($table);
	my @fields_list =  @$fields_listref;
	my @mnfields_list =  @$mnfields_listref;
	
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
    
	my $result = DB_ExecQuery($dbh,$table,$query,\%dbdata,\@updatefields);
	my $ID =  $record->{id};
        
	if (defined $result and scalar(@mnfields_list) ne 0) {$result = _DB_UpdateMN($dbh,$table,\@fields_list,\@mnfields_list,$ID)};
	return $result;
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
	print STDERR "$query\n";
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

sub DB_GetBlobMetaData($$$$)
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


	my $query = "Select substring($field,1,position('#'::bytea in $field)-1) from $table where $idcolumn=$id";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or return undef;
	my $metadata = $data->[0];

	$metadata =~ /(.*) (.+)$/ or die('blob metadata: $metadata incorrect');
	my $filename = $1;
	$filename =~ s/gedafe_PROTECTED_sPace/ /g;
	$filename =~ s/gedafe_PROTECTED_hAsh/#/g;
	return ($filename,$2);
}

sub DB_GetBlobName($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;
	my @metadata= DB_GetBlobMetaData($dbh,$table,$field,$id);
	return $metadata[0];
}

sub DB_GetBlobType($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $id = shift;
	my @metadata= DB_GetBlobMetaData($dbh,$table,$field,$id);
	return $metadata[1];
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
			$_ = DB_filenameSql($_);
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
	my $maxsize = $g{conf}{max_dumpsize};
	$maxsize = 10000 unless($maxsize);
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
			if(length($data) > $maxsize){
			    $data = "Resultset exeeds desirable size.\n";
			}

		}
		$data .= "\n";
	}
	$sth->finish();
	return $data;
}

sub DB_DumpJSITable($$$)
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
			$_ = DB_filenameSql($_);
		}
	}

	my $query = "SELECT ";
	$query .= join(', ',@select_fields);
	$query .= " FROM $view";
	
	

	my $first = 1;
	for my $field (keys(%$atribs)){
		if($first){
			$query .= " where ";
		}else{
			$query .= " and ";
		}
		$first = 0;
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

	my (@row, $numrecs,$jsheader,$jsfooter);
	
	$jsheader = "<script language=\"javascript\">\n<!--\n";
	$jsfooter = "//-->\n</script>\n";

	#prints everywhere to stream data to client.


	my $sth = $dbh->prepare($query) or return undef;
	unless($sth->execute()){
	    print $jsheader."dberror = true;\n".$jsfooter;
	    return;
	}

	$numrecs=$sth->rows;


	if($numrecs == -1){
	    print $jsheader."dberror = true;\n".$jsfooter;
	    return;
	}elsif($numrecs > 1500){
	    print $jsheader."toolarge = true;\n".$jsfooter;
	    return;
	}
		
	print $jsheader."idata = new Array($numrecs);\n".$jsfooter;

	$first = 1;
	my $numcolumns = scalar @select_fields;
	my $dataline;
	my $recno = 0;

	my $collecting = 1;

	print $jsheader;

	while(@row = $sth->fetchrow_array()) {
		$first = 1;
		print "idata[$recno] = new Array(\"";
		for (0..$numcolumns-1){
			my $field=$row[$_];
			if(!$field||$field eq ""){
				$field = " ";
			}
			
			if(not $first){
				print '","';
			}
			$first = 0;
			$field =~ s/\t/\&\#09\;/gm;
			$field =~ s/\n/\&\#10\;/gm;
			$field =~ s/\"/\&\#34\;/gm;
			$field =~ s/[\r\f]//gm;
			
			print $field;
		}
		print "\");\n";
		if($recno % 100 == 0){
		    print $jsfooter;
		    print $jsheader."progress(".(100*$recno/$numrecs).");\n".$jsfooter;
		    print $jsheader;
		}
		$recno++;
	}
	$sth->finish();
	print $jsfooter;
}

sub DB_filenameSql($){
	my $column = shift;
	return "decode(replace(replace(encode(substring($column,1,position(' '::bytea in $column)-1),'escape'), 'gedafe_PROTECTED_sPace'::text, ' '::text), 'gedafe_PROTECTED_hAsh'::text, '#'::text),'escape')";
}

sub DB_GetMNCombo($$$$$)
{
	my $s = shift;
	my $combo_view = shift;
	my $combo_data = shift;
	my $vfield = shift;
	my $op = shift;

	my $q = $s->{cgi};
	
	my $dbh = $s->{dbh};
	my $table = $q->url_param('table');
	my $mncombo_filter = undef;
	$mncombo_filter = $q->url_param('id');
	
	my $mncombo_atable = $table;
	my $mncombo_reference = $g{db_mnfields}{$table}{$vfield}{reference};
	my $mncombo_btable = $g{db_mnfields}{$table}{$vfield}{btable};
	my $mncombo_aid = $g{db_mnfields}{$table}{$vfield}{mnfirstfield_name};
	my $mncombo_bid = $g{db_mnfields}{$table}{$vfield}{mnsecondfield_name};

	my $aid = $mncombo_atable."_id";
	my $bid = $mncombo_btable."_id";
	my $rid = $mncombo_reference."_id";

	my $mncombo_view = $g{db_fields}{$table}{$vfield}{widget};
	$mncombo_view =~ s/^(\s)*mncombo\((\s)*combo(\s)*=(\s)*//;
	$mncombo_view =~ s/(\s)*\)(\s)*$//;
	
	my  $query = "";
	if ((not defined  $mncombo_filter and $op eq ' not in ') or (defined  $mncombo_filter)){
		$query .= "SELECT * from ".$mncombo_view." ";
		if (defined  $mncombo_filter){
			$query .= "WHERE  id $op ";
			$query .= "(SELECT  $bid ";
			if ($mncombo_atable eq $mncombo_btable) {
				$query .= "FROM	$mncombo_reference, $mncombo_atable ";
			}
			else{
				$query .= "FROM	$mncombo_reference, $mncombo_atable, $mncombo_btable ";
			};
			$query .= "WHERE   $aid = $mncombo_filter AND ";
			$query .= "		$mncombo_aid = $aid AND ";
			$query .= "		$bid = $mncombo_bid ";
			if ($g{db_fields}{$table}{$vfield}{ordered} eq '1'){
				$query .= " ORDER BY ".$mncombo_reference."_order DESC";
			};
			$query .= ")";
		
		};
		
		
		my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
		$sth->execute() or die $sth->errstr;
		my $data;
		while($data = $sth->fetchrow_arrayref()) {
			$data->[0]='' unless defined $data->[0];
			$data->[1]='' unless defined $data->[1];
			push @$combo_data, [$data->[0], $data->[1]];
		}
		die $sth->errstr if $sth->err;
	}

	return 1;
};

sub DB_ExecQueryMN($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $query = shift;
	my $fields = shift;
	my $sth = $dbh->prepare($query) or die $dbh->errstr;
	my $res = $sth->execute() or do {
		# report nicely the error
		$g{db_error}=$sth->errstr; return undef;
	};
	if($res ne 1 and $res ne '0E0') {
		die "Number of rows affected is not 1! ($res)";
	}
	return 1;
};


sub _DB_GetID($$$){
	my $dbh = shift;
	my $table = shift;
	my $oid = shift;
	my $id = undef;
	my $table_id = $table."_id";
	
	# ID from the last insert into table
	my $query = "SELECT $table_id FROM $table WHERE oid = $oid";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or die $sth->errstr;
	$id = $data->[0];
	$sth->finish;
	
	return $id;
};

sub _DB_Difference($$){
	my $A = shift; 
	my $B = shift;
	my %seen = ();
	my @result = ();
	
	foreach my $item (@$B) {$seen{$item} = 1};
	foreach my $item (@$A){
		unless ($seen{$item}) {
			push @result, $item;
		}
	}
	return \@result;
};


sub _DB_GetIDMN($$$$$){
	my $dbh = shift;
	my $table = shift;
	my $oid = shift;
	my $field = shift;
	my $mntable_second = shift;
	my @result = ();
	my $table_id = $table."_id";
	
	# ID from the last insert into table
	my $query = "SELECT $mntable_second FROM $table WHERE $field = $oid";
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	
	while (my $data = $sth->fetchrow_arrayref()) {
		push @result, $data->[0];
	}
	$sth->finish;
	
	return \@result;
};

sub _DB_UpdateMN($$$){
	my $dbh = shift;
	my $table = shift;
	my $fields_listref =  shift;
	my $mnfields_listref = shift;
	my $ID = shift;
	
	my @fields_list =  @$fields_listref;
	my @mnfields_list =  @$mnfields_listref;
	
	my $query;
	my $result = 1;
	
	print STDERR Dumper(\@mnfields_list);
	
	for my $vfield (@mnfields_list){ 
		my $mntable = $g{db_fields}{$table}{$vfield}{reference};
		my $mntable_first = $g{db_mnfields}{$table}{$vfield}{mnfirstref_name};
				@fields_list = @{$g{db_fields_list}{$mntable}};
		@fields_list = grep !/${mntable}_id/, @fields_list;
		@fields_list = grep !/${mntable}_order/, @fields_list;
		
		my $fname = "field_".$vfield;
		
		#new list         
		my @mntable_fields = $g{s}{cgi}->param($fname);
		if ( scalar(@mntable_fields) ne 0 ){
			#old list
			my $mncombo_firstfield = $g{db_mnfields}{$table}{$vfield}{mnfirstfield_name};
			my $mncombo_secondfield = $g{db_mnfields}{$table}{$vfield}{mnsecondfield_name};
			my $mntable_fields_old = _DB_GetIDMN($dbh, $mntable, $ID, $mncombo_firstfield, $mncombo_secondfield );
			#delete list
			my $mntable_fields_delete = _DB_Difference($mntable_fields_old, \@mntable_fields);
			#add list
			my $mntable_fields_add = _DB_Difference(\@mntable_fields, $mntable_fields_old);
			#update order
			
			if (scalar(@$mntable_fields_delete) ne 0){
				for my $val (@$mntable_fields_delete){
					my @mntable_row = ();
					if ( $mntable_first eq $table ){
						push @mntable_row, $ID;
						push @mntable_row, $val;
					}else {
						push @mntable_row, $val;
						push @mntable_row, $ID;
					}
					$query = _DB_DeleteMN($mntable, \@fields_list,\@mntable_row);
					$result = DB_ExecQueryMN($dbh,$mntable,$query,\@fields_list);
				}
			}
			if ( scalar(@$mntable_fields_add) ne 0){
				if ( $g{db_fields}{$table}{$vfield}{ordered} eq "1"){
					push @fields_list, "${mntable}_order";
				};
				my $order = scalar(@mntable_fields);
				
				for my $val (@$mntable_fields_add){
					my @mntable_row = ();
					if ( $mntable_first eq $table ){
						push @mntable_row, $ID;
						push @mntable_row, $val;
					}else {
						push @mntable_row, $val;
						push @mntable_row, $ID;
					}
					if ( $g{db_fields}{$table}{$vfield}{ordered} eq "1"){
							push @mntable_row, $order--;
					}
					
					$query = _DB_InsertMN($mntable, \@fields_list,\@mntable_row);
					print STDERR ("Update $query \n");
					$result = DB_ExecQueryMN($dbh,$mntable,$query,\@fields_list);
				}
			}
			if ( scalar(@mntable_fields) ne 0 and $g{db_fields}{$table}{$vfield}{ordered} eq "1"){
				@fields_list = grep !/${mntable}_order/, @fields_list;
				push @fields_list, "${mntable}_order";
				
				my $order = 1;#scalar(@mntable_fields);
				
				for my $val (@mntable_fields){
					my @mntable_row = ();
					if ( $mntable_first eq $table ){
						push @mntable_row, $ID;
						push @mntable_row, $val;
					}else {
						push @mntable_row, $val;
						push @mntable_row, $ID;
					}
					push @mntable_row, $order++;
					
					$query = _DB_UpdateOrderMN($mntable, \@fields_list,\@mntable_row);
					print STDERR ("UPDATE ORDER $query\n");
					$result = DB_ExecQueryMN($dbh,$mntable,$query,\@fields_list);
				}
			}
		}
	}
	return $result;
};


sub _DB_Insert($$){
	my $table = shift;
	my $fields_list = shift;
	my $query = "INSERT INTO $table (";
	$query   .= join(', ',@$fields_list);
	$query   .= ") VALUES (";
	my $first = 1;
	for(@$fields_list) {
		if($first) {
			$first = 0;
		}
		else {
			$query .= ', ';
		}
		$query .= '?'
	}
	$query   .= ");";
	return $query;
};

sub _DB_InsertMN($$$){
	my $table = shift;
	my $fields_list = shift;
	my $values = shift;
  
	my $query = "INSERT INTO $table (";
	$query   .= join(', ',@$fields_list);
	$query   .= ") VALUES (";
	$query   .= join(', ',@$values);
	$query   .= ");";
	
	return $query;
};

sub _DB_DeleteMN($$$){
	my $table = shift;
	my $fields_list = shift;
	my $values = shift;
	my $query = "DELETE FROM $table WHERE ";
	
	for (my $i = @$fields_list - 1; $i > 0; $i--){
		$query.= "@$fields_list[$i] = @$values[$i] AND "; 
	}
	
	$query.= "@$fields_list[0] = @$values[0]";
	return $query;
};

sub _DB_UpdateOrderMN($$$){
	my $table = shift;
	my $fields_list = shift;
	my $values = shift;
	my $query = "UPDATE $table SET @$fields_list[2] = @$values[2] WHERE ";
	
	for (my $i = 1; $i > 0; $i--){
		$query.= "@$fields_list[$i] = @$values[$i] AND "; 
	}
	
	$query.= "@$fields_list[0] = @$values[0]";
	return $query;
};


sub _DB_GetFields($){
	my $table = shift;
	my @fields_list;
	my @mnfields_list;
	
	my @wmnfields = @{$g{db_fields_list}{$table}};
	foreach my $nvf (@wmnfields){
		if (not $g{db_fields}{$table}{$nvf}{virtual} eq 'true'){
			push @fields_list, $nvf;
		}else{
			push @mnfields_list, $nvf; 
		}
	} 
	return (\@fields_list, \@mnfields_list);
};


sub DB_ExecQueryOID($$$$$)
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
	print STDERR ("DB_ExecQueryOID \n");
	my $res = $sth->execute() or do {
		# report nicely the error
		$g{db_error}=$sth->errstr; return undef;
	};
	my $oid = $sth->{'pg_oid_status'};
	if($res ne 1 and $res ne '0E0') {
		die "Number of rows affected is not 1! ($res)";
	}
	return 1, $oid;
};

sub _DB_GetMNComboField($$$){
	# helper function - returns M:N table field name from the given position
	# eg. publauthor ((publauthor_publication,2)(publauthor_author,3))
	
	my $dbh = shift;
	my $mntable = shift;
	my $mntable_position = shift;
	
	my $query = "SELECT attname FROM pg_class c, pg_attribute a WHERE ";
	$query.="c.relname ='$mntable' AND ";
	$query.= "a.attrelid = c.oid AND attnum=$mntable_position";
	 
	my $sth = $dbh->prepare($query);
	$sth->execute() or return undef;
	my $data = $sth->fetchrow_arrayref() or die $sth->errstr;
	my $table_attr = $data->[0];
	$sth->finish;
	
	return $table_attr;
};


sub _DB_GetMNComboFieldReference($$$){
	# helper function - returns M:N table field reference from the given position
	# eg. publauthor ((publication,2)(person,3))
	
	my $dbh = shift;
	my $mntable = shift;
	my $mntable_position = shift;
	
	my $query = "SELECT attname FROM pg_class c, pg_attribute a WHERE ";
	$query.="c.relname ='$mntable' AND ";
	$query.= "a.attrelid = c.oid AND attnum=$mntable_position";
	 
	my $sth = $dbh->prepare($query);
	$sth->execute() or die $dbh->errstr;
	my $data = $sth->fetchrow_arrayref() or die $sth->errstr;
	my $table_attr = $data->[0];
	$sth->finish;
	
	my $reftable = _DB_GetFieldReference($dbh, $mntable, $table_attr);
	return $reftable;
};


sub _DB_GetMNComboSecondFieldReference($$$){
	my $dbh = shift;
	my $mntable = shift;
	my $mncombo_first = shift;
	my $mncombo_second = undef;
	
	my $mn_first =  _DB_GetMNComboFieldReference($dbh,$mntable,2);
	my $mn_second = _DB_GetMNComboFieldReference($dbh,$mntable,3);
	
	if ($mncombo_first eq $mn_first){
		$mncombo_second = $mn_second;
	}else{
		$mncombo_second = $mn_first;
	}
	return $mncombo_second;
};

sub _DB_GetFieldReference($$$){
	my $dbh = shift;
	my $table = shift;
	my $table_attr = shift;
	
	my $query="SELECT DISTINCT tgargs FROM pg_class,pg_trigger WHERE relfilenode=tgconstrrelid AND ";
	$query.=" relname='$table' AND tgargs LIKE '%$table_attr%'";
	my $sth = $dbh->prepare($query);
	$sth->execute() or die $dbh->errstr;
	my $data = $sth->fetchrow_arrayref() or die "TABLE $table does have defined CONSTRAINT on column $table_attr\n $sth->errstr";
	
	#"$1\000publauthor\000publication\000UNSPECIFIED\000publauthor_publication\000publication_id\000";
	my @reflist = split('\000',$data->[0]);
	$sth->finish;
	
	return $reflist[2];
}


1;

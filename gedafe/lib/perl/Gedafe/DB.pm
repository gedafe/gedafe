# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::DB;
use strict;

#use Data::Dumper qw(Dumper);

use Gedafe::Global qw(%g);

use DBI;
use DBD::Pg 1.20; # 1.20 has constants for data types


use Gedafe::Util qw(
	DataTree
	DataUnTree
);


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
	DB_DumpJSITable
	DB_DumpTable
	DB_FetchReferencedId
	DB_FetchReferencedSearchValues
	DB_ReadDatabase
);


sub DB_AddRecord($$$);
sub DB_Connect($$$);
sub DB_DB2HTML($$);
sub DB_DeleteRecord($$$);
sub DB_DumpBlob($$$$);
sub DB_DumpTable($$$);
sub DB_ExecQuery($$$$$;$);
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
sub DB_ReadSchemapath($$$);
sub DB_ReadTableAcls($$);
sub DB_ReadTables($$);
sub DB_Record2DB($$$$);
sub DB_UpdateRecord($$$$);
sub DB_Widget($$);
sub DB_filenameSql($);
sub DB_FetchReferencedSearchValues($$$$$);

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
	'bytea'     => 'file',
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
SELECT c.relname, n.nspname,c.relkind
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
		if($database->{version} >= 7.1 ){
			if($data->[2] =~ /v/){
				$tables{$data->[0]}{isview} = 1;
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


	#experiment with primary key finding
	#
	#first initialise the $tables structure with
	#a default primary key that ensures backward compatibility on
	#postgres <7.3: every $table has $table_id as primary key 
	
	for(keys(%tables)){
		$tables{$_}{foreign} = {};
		$tables{$_}{foreign_pairs} = {};
	}

	#now if we have a resonably new postgres, find the actual 
	#primary keys
	my ($subquery,$subdata,$substh);
	
	$query = <<'END';
select relname,array_dims(conkey) from pg_constraint,pg_class where conrelid=pg_class.oid and contype = 'p';
END
	$sth = $dbh->prepare($query) or return undef;

	$sth->execute() or return undef;
	while ($data = $sth->fetchrow_arrayref()) {
	    next unless defined $tables{$data->[0]};
	    $tables{$data->[0]}{primary} = [];
	    $data->[1] =~ /(\d+)\]/;
	    for(1..$1){
		$subquery = <<END;
select attname from pg_attribute,pg_constraint,pg_class where conrelid=pg_class.oid and attrelid=pg_class.oid and pg_class.relname='$data->[0]' and attnum = conkey[$_] and contype='p' and not attisdropped;
END
		
		$substh = $dbh->prepare($subquery) or return undef;
		$substh->execute();
		$subdata = $substh->fetchrow_arrayref();
		push @{$tables{$data->[0]}{primary}},$subdata->[0];
	    }
	}
	$sth->finish;

	for(keys %tables){
	    if(!$tables{$_}{hide} 
	       and $_ !~ /^meta_/ 
	       and !$tables{$_}{isview}){
		print STDERR "testing: $_\n";
		if(!$tables{$_}{primary} or scalar @{$tables{$_}{primary}}==0){
		    die("Table \"$_\" seems to have no primary keys, Gedafe needs a primary key for every <I>visible</i> table to work properly<br>");
		}
	    }
	}

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

	# isearch has been deprecated
	#if(defined $f->{widget} and $f->{widget} eq 'isearch'){
	#	my $r  = $f->{reference};
	#	my $rt = $g{db_tables}{$r};
	#	defined $rt or die "table $f->{reference}, referenced from $f->{table}:$f->{field}, not found.\n";
	#	if(defined $fields->{$r}{"${r}_hid"}) {
	#		# Combo with HID
	#		return "hidisearch(ref=$r)";
	#	}
	#	return "isearch(ref=$r)";
	#}

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
	if($f->{type} eq 'varchar') {
		my $len = $f->{atttypmod}-4;
		if($len <= 0) {
			return 'text';
		}
		else {
			return "text(size=$len,maxlength=$len)";
		}
	} else {
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

	# defaults and serials
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
			if($d->[0] =~ /^nextval\((.*)_seq'::text\)$/){
			    $fields{$table}{$field}{serial} = 1;
			}
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
	
	# we need to save some stuff about what columns for a table contain
	# foreign keys. We find that information out here.
	# however we need to make sure that $g{db_tables} exits first
	#
	die('We need $g{db_tables} to store foreign key info.') unless $g{db_tables};
	$query = <<'END';
SELECT tgargs,pg_trigger.oid from pg_trigger, pg_proc where pg_trigger.tgfoid=pg_proc.oid AND pg_trigger.tgname LIKE 'RI_ConstraintTrigger%' AND pg_proc.proname = 'RI_FKey_check_ins'
END
	$sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		#next line doesn't work on foreign keys that span multiple columns
		#$meta_fields{$d[1]}{$d[4]}{reference} = $d[2];
		#here is how tgargs works:
		#<argument name>\000<referer>\000<target>\000<UNSPECIFIED>\000rcol1\000tcol1\000rcol2\000tcol2...
		
		my ($constraint,$args,$target,$referer);
		$constraint = $$data[1];
		$args = $$data[0];
		my @d = split(/(?:\000|\\000)/,$$data[0]); # DBD::Pg 0.95: \\000, DBD::Pg 0.98: \000
		$target = $d[2];
		$referer = $d[1];
		#splice first 4 elements, we already dealt with them
		@d = splice @d,4;
		#print STDERR "R: ".join(' ',@d)." ".scalar @d."\n"; 
		
		$g{db_tables}{$referer}{foreign}{$constraint} = [];
		
		while(scalar @d > 0){
			#unshift pairs of columns
			my $rcol = shift @d;
			my $tcol = shift @d;
			#not too usefull naming here... due to backwards compatibility
			$meta_fields{$referer}{$rcol}{reference} = $target;
			$meta_fields{$referer}{$rcol}{targetcolumn} = $tcol;
			
			#we save the constraint oid to group columns that belong to the
			#same constraint later.
			$meta_fields{$referer}{$rcol}{refconstraint} = $constraint;
			
			#also save this field in the tables foreign key constraint list.
			push @{$g{db_tables}{$referer}{foreign}{$constraint}}, $rcol;	

			#and save it in the hash of referencing fields
			$g{db_tables}{$referer}{foreign_pairs}{$rcol} = $tcol;
		}

		
		
		
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
                        if ($field eq 'meta_bgcolour'){
                               ###$g{db_tables}{$table}{meta}{linecolourfield}
                               $g{db_tables}{$table}{bgcolor_field_index}
                                =  $f->{order}-1; # calculate nr of column
                               $f->{hide_list}=1; # suppress color column
                        }

			my $m = undef;
			if(defined $meta_fields{$table}) {
				$m = $meta_fields{$table}{$field};
			}
			if(defined $m) {
			        $f->{javascript}    = $m->{javascript};
				$f->{widget}        = $m->{widget};
				$f->{reference}     = $m->{reference};
				$f->{targetcolumn}  = $m->{targetcolumn};
				$f->{refconstraint} = $m->{refconstraint};
				$f->{copy}          = $m->{copy};
				$f->{sortfunc}      = $m->{sortfunc};
				$f->{markup}        = $m->{markup};
				$f->{align}         = $m->{align};
				$f->{hide_list}     = $m->{hide_list};
				if  ( defined $m->{bgcolor_field} 
				      and $m->{bgcolor_field} == 1 ){
				   # calculate nr of column 
				   # and override meta_bgcolor field
				   ###$g{db_tables}{$table}{meta}{linecolourfield}
				   $g{db_tables}{$table}{bgcolor_field_index}
				    =  $f->{order}-1 ;
                                   $f->{hide_list}=1; # suppress color column

				}
			}
			#if(! defined $f->{widget}) {
			$f->{widget} = DB_Widget(\%fields, $f);
			#}
				
		}
	}

	return \%fields;
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
	my @fields = @{$g{db_fields_list}{$v}};
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
	   and !$spec->{rowcount}
	   and $g{db_tables}{$spec->{table}}{meta}{showref}){
		#the list of tables that we want to find reference counts for
		my @showrefs = split(/,/,
				     $g{db_tables}{$spec->{table}}{meta}{showref});
	    
	    
		for my $showref(@showrefs){	
				
  			my $showrefindex = 0;
			my ($sr,$explicittarget)= 
				( $showref=~ m/^\s*(.*)\((.*)\)\s*/o);
			$showref = $sr if (defined  $sr );

			next unless(defined $g{db_tables}{$showref}{acls}{$spec->{user}} 
				    and $g{db_tables}{$showref}{acls}{$spec->{user}}=~/r/);
			
			#now find the column that references us.
			my $constraintnumber = 0;
			my %refcolumns = ();
			if (defined  $explicittarget ){
			    my @rcollist = split(',',$explicittarget);
			    for my $constraint(keys %{$g{db_tables}{$showref}{foreign}}){
				my @cfcols = ();
				for(@{$g{db_tables}{$showref}{foreign}{$constraint}}){
				    if($g{db_fields}{$showref}{$_}{reference} eq $spec->{table}){
					push @cfcols,$_;
				    }
				}

				#compare nr of ellements
				next unless(@rcollist == @cfcols);
				#thats a lot of trouble to go through to compare two arrays
				next unless (join('|',sort(@rcollist)) eq join('|',sort(@cfcols)));
				
				#once we are here this is the first foreign key constraint that 
				#matches
				for(@{$g{db_tables}{$showref}{foreign}{$constraint}}){
				    $constraintnumber = $g{db_fields}{$showref}{$_}{refconstraint};
				    $refcolumns{$_} = $g{db_fields}{$showref}{$_}{targetcolumn};
				}

				#enough browsing through lists now
				last;
			    }
			} else {
			CONSTRAINT: for my $constraint (keys %{$g{db_tables}{$showref}{foreign}}){
				for(@{$g{db_tables}{$showref}{foreign}{$constraint}}){
				    my $target = $g{db_fields}{$showref}{$_}{targetcolumn};
				    $constraintnumber = $g{db_fields}{$showref}{$_}{refconstraint};
				    if($g{db_fields}{$showref}{$_}{reference} eq $spec->{table} &&
				       grep(/^$target$/,@{$g{db_tables}{$spec->{table}}{primary}})){
					$refcolumns{$_} = $g{db_fields}{$showref}{$_}{targetcolumn};
				    }else{
					#this constraint doesnt match... find a new one
					%refcolumns = ();
					next CONSTRAINT;
				    }
				}
				#this constraint matches... no need to look any further..
				last;
			    }
			}
			die("Although meta_tables suggests that we should 'showref' to table [$showref] from this table [$spec->{table}] it appears that there is no foreign key constraint that represents this relation.<p> Error occured ") 
			    if(keys(%refcolumns)==0);
			
			my $countquery = "(select count(*) from $showref where ";
			my @comparelist = ();
			for(keys %refcolumns){
			    push @comparelist," $showref.$_ = $spec->{table}.$refcolumns{$_} ";
			}
			$countquery .= join(' and ',@comparelist)." ) as meta_rc_$showref";
			push @select_fields,$countquery;

			push @fields,"meta_rc_$showref#$constraintnumber";
		}
	    
	}
	my @query_parameters = ()
;
	my $query = "SELECT ";
	$query .= $spec->{countrows} ? "COUNT(*)" : join(', ',@select_fields);
	$query .= " FROM $v";
	my $searching=0;
	if(defined $spec->{search} and ref($spec->{search}) eq 'ARRAY'
		and scalar(@{$spec->{search}})>0)
	{
		my @tree = @{$spec->{search}};
		my $type;
		my @ands = ();
		for my $line (@tree){
		    my $field = $line->{field};
		    #build expression that is the conjunction of all fields in db
		    if($field eq '#ALL#'){
			my @fieldlist = ();
			my $fields = $g{db_fields}{$spec->{view}};
			foreach(@{$g{db_fields_list}{$spec->{view}}}) {
			    next if($g{db_fields}{$spec->{view}}{$_}{type} eq 'bytea');
			    if($g{db_fields}{$spec->{view}}{$_}{type} eq 'bool'){
				push @fieldlist,"(CASE WHEN $_ THEN ' true ' ELSE ' false ' END)";
			    }else{
				push @fieldlist,$_;
}

			}
			$field = join("||' '||",@fieldlist);
		    }

		    if($field =~ /meta_rc_(.*)/){
			#here be dragons.
			#
			#The thing is, meta_rc_COLNAME is a column from $table while we are looking at $view
			#so... we have to find out if for this row of $view, $table has a row with COLNAME 
			#that matches $value...

			my $qtmp = "(? IN (SELECT $1 FROM $spec->{table} AS rc_$line->{count} WHERE ";
			push @query_parameters, $line->{value};


			#now match up all the primary keys, 
			#luckily they appear in both $table and $view
			my @prilist = @{$g{db_tables}{$spec->{table}}{primary}};
			for(@prilist){
			    $_ = "rc_$line->{count}.$_ = $spec->{view}.$_";
			}
			$qtmp.= join(' AND ', @prilist);
			$qtmp.= "))";

			push @ands, $qtmp;
		    } else {
			#roll out tree of conjuctions and disjunctions
			my @ors = @{$line->{tree}};
			foreach my $or (@ors){
			    my @innerand = @$or;
			    foreach my $and (@innerand){
				if($line->{op} =~ /like/){
				    $and = "%$and%";
				}
				$and = "(".$field." ".$line->{op}." '".$and."')";
			    }
			    $or = join " AND ",@innerand;
			    $or = "( $or ) ";
			}
			push @ands,"( ".join(" OR ",@ors)." ) ";
		    }
		}
		$query .= " WHERE ".join(" AND ",@ands);
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
				# with primary key fields
			    for(@{$g{db_tables}{$spec->{table}}{primary}}){
				$query.=",$_";
			    }
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
	print STDERR "$query \n";

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
    my $row = shift;
    my $target = $g{db_fields}{$table}{$column}{reference};
    my $constraint = $g{db_fields}{$table}{$column}{refconstraint};
    my @reffields = @{$g{db_tables}{$table}{foreign}{$constraint}};

    my $dbh = $s->{dbh};
    my $query = "select ".join(',',@reffields)." from $table where ";
    my @idlist = ();
    for(keys %{$row->[0]}){
	push @idlist, " $_ = ? ";
    }
    $query .= join(' and ',@idlist);
    my $sth= $dbh->prepare($query);

    print STDERR "FRI: $query\n";

    my $paramnumber = 1;
    for(keys %{$row->[0]}){
	#print STDERR "FRI: $_ -> $row->[0]{$_}\n";
	$sth->bind_param($paramnumber,$row->[0]{$_});
	$paramnumber++;
    }
    
    my $res = $sth->execute();
    my $data = $sth->fetchrow_hashref();
    return $data;
}

#given a row and a rtable+constraint that references us,
#returns the hash of columnnames -> values that link to 
#the row.
sub DB_FetchReferencedSearchValues($$$$$){
    my $s = shift;
    my $row = shift;
    my $table = shift;
    my $rtable = shift;
    my $constraint = shift;
 
    
    #print STDERR "FRSV constraint: $constraint\n";
    
    my @rlist = @{$g{db_tables}{$rtable}{foreign}{$constraint}};

    my @reffields = ();
    for(@rlist){
	push @reffields,$g{db_tables}{$rtable}{foreign_pairs}{$_};
    }

    my $dbh = $s->{dbh};
    my $query = "select ".join(',',@reffields)." from $table where ";
    my @idlist = ();
    for(keys %{$row->[0]}){
	push @idlist, " $_ = ? ";
    }
    $query .= join(' and ',@idlist);

    #print STDERR "FRSV: $query\n";
    my $sth= $dbh->prepare($query);

    my $paramnumber = 1;
    for(keys %{$row->[0]}){
	$sth->bind_param($paramnumber,$row->[0]{$_});
	$paramnumber++;
    }
    
    my $res = $sth->execute();
    my $data = $sth->fetchrow_hashref();

    return $data;
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
			= {field     => $f,
			   desc      => $g{db_tables}{$1}{desc},
			   rtable    => $1,
			   align     => '"LEFT"',
			   refcount  => 1,
			   constraint => $2,
			   type      => 'int4'
			       
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


	#find column numbers for every primary key and store them in 
	#$list{keys}
	my $fieldcounter = 0;
	my %primary = ();
	for my $primarykey (@{$g{db_tables}{$spec->{table}}{primary}}){
	    $fieldcounter = 0;
	    for(@{$list{columns}}){
		#print STDERR "$_->{field} ... $primarykey\n";
		if($_->{field} eq $primarykey){
		    $primary{$primarykey} = $fieldcounter;
		}
		$fieldcounter++;
	    }
	}
	$list{keys} = \%primary;

	# fetch the data
	while(my $data = $sth->fetchrow_arrayref()) {
		my $col;
		my @row;
		for($col=0; $col<=$#$data; $col++) {
			push @row, $spec->{export} ? $data->[$col] :
				DB_DB2HTML($data->[$col], $columns[$col]{type});
		}
		my %privalue = ();
		for(keys %{$list{keys}}){
		    $privalue{$_} = $row[$list{keys}{$_}];
		}
		push @{$list{data}}, [\%privalue, \@row ];
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
	my $keys = shift;
	my $record = shift;

	my @fields_list = @{$g{db_fields_list}{$table}};
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
	$query .= " FROM $table WHERE ";
	my @keylist = (); 
	for(keys %$keys){
	    push @keylist, " $_ = ? ";
	}
	$query .= join " AND ",@keylist;
	my $sth;

	$sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	my $paramnumber = 1;
	for(keys %$keys){
	    $sth->bind_param($paramnumber,$keys->{$_});
	    $paramnumber++;
	}

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

sub DB_ExecQuery($$$$$;$)
{
	my $dbh = shift;
	my $table = shift;
	my $query = shift;
	my $data = shift;
	my $fields = shift;
	my $keys = shift;

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

	#if primary keys are defined, bind them now.
	if($keys){
	    for(keys %$keys){
		$sth->bind_param($paramnumber,$keys->{$_});
		$paramnumber++;
	    }
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
	my @fields_list = grep {!$fields->{$_}{serial}} @{$g{db_fields_list}{$table}};
	
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

sub DB_UpdateRecord($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;
	my $keys = shift;

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
	    #skip when serial
	    next if($g{db_fields}{$table}{$_}{serial});
	    push @updates,"$_ = ?";
	    push @updatefields,$_;
	}
	$query .= join(', ',@updates);


	$query .= " WHERE ";

	my @keylist = ();
	for(keys %$keys){
	    push @keylist, " $_ = ? ";
	}
	$query .= join " AND ",@keylist;

	return DB_ExecQuery($dbh,$table,$query,\%dbdata,\@updatefields,$keys);
}

sub DB_GetCombo($$$)
{
	my $dbh = shift;
	my $combo_view = shift;
	my $combo_data = shift;

	my $query = "SELECT * FROM $combo_view";
	if(defined $g{db_tables}{$combo_view}{meta_sort}) {
		$query .= " ORDER BY meta_sort";
	}
	else {
		$query .= " ORDER BY text";
	}
	# print STDERR "$query\n";
	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	my $data;
	while($data = $sth->fetchrow_hashref()) {
	    my %combohash = ();
	    for(keys %$data){
		next if($_ eq 'meta_sort');
		$combohash{$_} = $data->{$_} || '';
	    }
	    push @$combo_data, \%combohash;
	}
	die $sth->errstr if $sth->err;

	return 1;
}

sub DB_DeleteRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $keys = shift;

	my $query = "DELETE FROM $table WHERE ";

	my @keylist = ();
	for(keys %$keys){
	    push @keylist, " $_ = ? ";
	}
	$query .= join " AND ",@keylist;

	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	my $paramnumber = 1;
	for(keys %$keys){
	    $sth->bind_param($paramnumber,$keys->{$_});
	    $paramnumber++;
	}

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
	my $keys = shift;


	my $query = "SELECT SUBSTRING($field,1,position('#'::bytea in $field)-1) FROM $table WHERE ";

	my @keylist = ();
	for(keys %$keys){
	    push @keylist, " $_ = ? ";
	}
	$query .= join " AND ",@keylist;

	my $sth = $dbh->prepare($query);

	my $paramnumber = 1;
	for(keys %$keys){
	    $sth->bind_param($paramnumber,$keys->{$_});
	    $paramnumber++;
	}


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
    my $keys = shift;
    my @metadata= DB_GetBlobMetaData($dbh,$table,$field,$keys);
    return $metadata[0];
}

sub DB_GetBlobType($$$$)
{
    my $dbh = shift;
    my $table = shift;
    my $field = shift;
    my $keys = shift;
    my @metadata= DB_GetBlobMetaData($dbh,$table,$field,$keys);
    return $metadata[1];
}

sub DB_DumpBlob($$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $keys = shift;

	my $query = "SELECT position('#'::bytea in $field)+1,octet_length($field) FROM $table WHERE ";
	my @keylist = ();
	for(keys %$keys){
	    push @keylist, " $_ = ? ";
	}
	$query .= join " AND ",@keylist;

	my $sth = $dbh->prepare($query);

	my $paramnumber = 1;
	for(keys %$keys){
	    $sth->bind_param($paramnumber,$keys->{$_});
	    $paramnumber++;
	}


	$sth->execute() or return -1;
	my $data = $sth->fetchrow_arrayref() or return -1;
	my $startpos = $data->[0] || 0;
	my $strlength = $data->[1] || 0;
	$sth->finish();
	my $endpos = $strlength-($startpos-1);
	my $dumpquery = "SELECT substring($field,?,?) FROM $table WHERE ". join " AND ",@keylist;
	my $dumpsth = $dbh->prepare($dumpquery);
	my $blobdata;
	$dumpsth->bind_param(1,$startpos);
	$dumpsth->bind_param(2,$endpos);

	$paramnumber = 3;
	for(keys %$keys){
	    $dumpsth->bind_param($paramnumber,$keys->{$_});
	    $paramnumber++;
	}

	$dumpsth->execute() or return -1;
	$blobdata = $dumpsth->fetchrow_arrayref() or return -1;
	# I know it is not nice to do the print here but I don't want to make the memory footprint
	# to large so returning the blob to a GUI routine is not possible.
	print $blobdata->[0];
	return 1;
}

#Not entirely sure what this was used for once...
#Looks like we don't need it any more...
#sub DB_RawField($$$$)
#{
#	my $dbh = shift;
#	my $table = shift;
#	my $field = shift;
#	my $id = shift;
#
#	my $query = "Select $field from $table where ${table}_id = $id";
#	# print STDERR $query."\n";
#	my $sth = $dbh->prepare($query);
#	$sth->execute() or return undef;
#	my $data = $sth->fetchrow_arrayref() or return undef;
#	return $data->[0];
#}

#sub DB_DumpTable($$$)
#{
#	my $dbh = shift;
#	my $table = shift;
#	my $view = defined $g{db_tables}{"${table}_list"} ?
#			"${table}_list" : $table;	
#	my $atribs = shift;
#
#	my @fields = @{$g{db_fields_list}{$view}};
#	# update the query to prevent listing binary data
#	my @select_fields = @fields;
#	for(@select_fields){
#		if($g{db_fields}{$view}{$_}{type} eq 'bytea'){
#			$_ = DB_filenameSql($_);
#		}
#	}
#
#	my $query = "SELECT ";
#	$query .= join(', ',@select_fields);
#	$query .= " FROM $view";
#	
#	# fix this for placeholders
#
#	my $first = 1;
#	for my $field (keys(%$atribs)){
#		if($first){
#			$query .= " where ";
#		}else{
#			$query .= " and ";
#		}
#		my $value = $atribs->{$field};
#		my $type = $g{db_fields}{$view}{$field}{type};
#		if($type eq 'date') {
#			$query .= " $field = '$value'";
#		}
#		elsif($type eq 'bool') {
#			$query .= " $field = '$value'";
#		}
#		else {
#			$query .= " $field ~* '.*$value.*'";
#		}
#	}
#
#	my $sth = $dbh->prepare($query) or return undef;
#	$sth->execute() or return undef;
#
#	my (@row, $data);
#	
#	$data=$sth->rows."\n";
#	
#	$first = 1;
#	my $numcolumns = scalar @select_fields;
#	my $maxsize = $g{conf}{max_dumpsize};
#	$maxsize = 10000 unless($maxsize);
#	while(@row = $sth->fetchrow_array()) {
#		$first = 1;
#		for (0..$numcolumns-1){
#			my $field=$row[$_];
#			if(!$field||$field eq ""){
#				$field = " ";
#			}
#			
#			if(not $first){
#				$data.="\t";
#			}
#			$first = 0;
#			$field =~ s/\t/\&\#09\;/gm;
#			$field =~ s/\n/\&\#10\;/gm;
#			$field =~ s/[\r\f]//gm;
#			
#			$data .= $field;
#			if(length($data) > $maxsize){
#			    $data = "Resultset exeeds desirable size.\n";
#			}
#
#		}
#		$data .= "\n";
#	}
#	$sth->finish();
#	return $data;
#}

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
	}elsif($numrecs > 2500){
	    print $jsheader."toolarge = true;\n".$jsfooter;
	    return;
	}
		
	print $jsheader."idata = new Array($numrecs);\n".$jsfooter;


	#find column numbers of primary keys
	my $fieldcounter = 0;
	my %primary = ();
	for my $primarykey (@{$g{db_tables}{$table}{primary}}){
	    $fieldcounter = 0;
	    for(@select_fields){
		if($_ eq $primarykey){
		    $primary{$primarykey} = $fieldcounter;
		}
		$fieldcounter++;
	    }
	}



	$first = 1;

	my $numcolumns = scalar @select_fields;

	#add one column for keys hash if we need that
	my $morekeys =0;
	if(scalar keys(%primary)>1){
	    $morekeys = 1;
	}



	my $dataline;
	my $recno = 0;

	my $collecting = 1;

	print $jsheader;
	print "var morekeys = $morekeys;";
	
	my %keyhash;

	while(@row = $sth->fetchrow_array()) {
	    %keyhash = ();
	    for(keys %primary){
		$keyhash{$_} = $row[$primary{$_}];
	    }
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

	    if($morekeys){
		if(not $first){
		    print '","';
		}
		$first = 0;
		print DataUnTree(\%keyhash);
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


1;

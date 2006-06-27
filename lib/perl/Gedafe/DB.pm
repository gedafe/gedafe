# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::DB;
use strict;

#use Data::Dumper qw(Dumper);

use Gedafe::Global qw(%g);
use Gedafe::Util qw(SplitCommaQuoted);
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
	DB_DumpJSITable
	DB_DumpTable
	DB_FetchReferencedId
	DB_ReadDatabase
	DB_Format
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
sub DB_GetCombo($$$$$);
sub DB_GetDefault($$$);
sub DB_GetNumRecords($$);
sub DB_GetRecord($$$$);
sub DB_HID2ID($$$);
sub DB_ID2HID($$$);
sub DB_Init($$);
sub DB_MergeAcls($$);
sub DB_ParseWidget($;$);
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

sub DB_Init($$)
{
	my ($user, $pass) = @_;
	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass,{AutoCommit=>1,ShowErrorStatement=>1}) or
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
        # lets figure some things about our widgets and cache them
        # we do this after reading tables and fields since widgets
        # may reference fields from other tables so the $g cache must be complete.
	for my $table (@{$g{db_tables_list}}) {
            for my $field (keys %{$g{db_fields}{$table}}){
                my $f = $g{db_fields}{$table}{$field};
                  ($f->{widget_type},$f->{widget_args}) = DB_ParseWidget($f->{widget},$table)
    		        if $f->{widget};
            }
        }
	# order fields
	for my $table (@{$g{db_tables_list}}) {
		$g{db_fields_list}{$table} =
			[ sort { $g{db_fields}{$table}{$a}{order} <=>
				$g{db_fields}{$table}{$b}{order} }
				keys %{$g{db_fields}{$table}}
			];
		$g{db_real_fields_list}{$table} =
		        [ map { $g{db_fields}{$table}{$_}{virtual} ? () : ($_) }
			   @{$g{db_fields_list}{$table}}
                        ];

		$g{db_virtual_fields_list}{$table} =
		        [ map { $g{db_fields}{$table}{$_}{virtual} ? ($_) : () }
			   @{$g{db_fields_list}{$table}}
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

        if ($g{db_database}{version} < 8.1){
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
			# example: {ymca_root=arwdRxt/ymca_root,"group ymca_admin=arwdRxt/ymca_root","group ymca_user=r/ymca_root"}
			$acldef =~ s/^{(.*)}$/$1/;
			my @acldef = split(',', $acldef);
			map { s/^"(.*)"$/$1/ } @acldef;
			acl: for(@acldef) {
				/(.*)=([^\/]+)/ or next;
				my $who = $1; # user or group
				my $what = $2; # permissions
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
	} else {
		# roles
                my %db_rolemembers;
                $query = <<SQL;
SELECT r.rolname,
  ARRAY(SELECT b.rolname FROM pg_catalog.pg_auth_members m JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid) WHERE m.member = r.oid) as "member_of"
FROM pg_catalog.pg_roles r
ORDER BY 1;
SQL

                $sth = $dbh->prepare($query) or die $dbh->errstr;
       	        $sth->execute() or die $sth->errstr;
               	while ($data = $sth->fetchrow_hashref()) {
	               	push @{$db_rolemembers{$data->{rolname}}}, $data->{rolname};
		       	if ($data->{member_of} and $data->{member_of} =~ /{(.+)}/){
		     	       map { push @{$db_rolemembers{$_}}, $data->{rolname} } split /,/, $1;
			}
		}
                $sth->finish;

                # resolve all role-sub-memberships
                my $continue;
                do {
                    $continue = 0;
                    foreach my $role (sort keys %db_rolemembers){
                         foreach my $member (sort @{$db_rolemembers{$role}}){
                             foreach my $submember ( @{$db_rolemembers{$member}}){
                                 unless (grep {$_ eq $submember} @{$db_rolemembers{$role}}){
                                     push  @{$db_rolemembers{$role}}, $submember;
                                     $continue = 1;
                                 }
                             }
                         }                         
                    }                      
                } while ($continue);

                # acls
       	        $query = "SELECT c.relname, c.relacl FROM pg_class c WHERE (c.relkind = 'r' OR c.relkind='v') AND relname !~ '^pg_'";
                $sth = $dbh->prepare($query) or die $dbh->errstr;
               	$sth->execute() or die $sth->errstr;
                while ($data = $sth->fetchrow_hashref()) {
                       next unless defined $data->{relname};
                       next unless defined $data->{relacl};
                       next unless defined $tables->{$data->{relname}};
                       my $acldef = $data->{relacl};
		       my $t = $tables->{$data->{relname}};
                       # example: {ymca_root=arwdRxt/ymca_root,"ymca_admin=arwdRxt/ymca_root","ymca_user=r/ymca_root"}
                       $acldef =~ s/^{(.*)}$/$1/;
                       my @acldef = split(',', $acldef);
                       map { s/^"(.*)"$/$1/ } @acldef;
                       acl: for my $acl (@acldef) {
                               $acl =~ /(.*)=([^\/]+)/ or next;
                               my $who = $1; # user or group
                               my $what = $2; # permissions
                               if($who eq '') {
                                       # PUBLIC: assign permissions to all db users
                                       for(keys %db_rolemembers) {
                                               $t->{acls}{$_} = DB_MergeAcls($t->{acls}{$_}, $what);
                                       }
                               }
                               else {
                                       # group permissions: assign to all db groups
                                       for my $member (@{$db_rolemembers{$who}}) {
                                               $t->{acls}{$member} = DB_MergeAcls($t->{acls}{$member}, $what);
                                       }
                               }
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

	if($f->{type} eq 'numeric' or $f->{type} eq 'integer') {
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
		return 'text(size=12)';
	}
	elsif($f->{type} eq 'character' or $f->{type} eq 'text') {
		if(defined $f->{type_args}) {
			my $len = $f->{type_args};
			return "text(size=$len,maxlength=$len)";
		}
		else {
			if($f->{type} eq 'text') {
				return "text(size=60)";
			}
			else {
				return "text(size=20)";
			}
		}
	}
	elsif($f->{type} eq 'date' or $f->{type} eq 'time') {
		return 'text(size=12)';
	}
	elsif($f->{type} eq 'timestamp') {
		return 'text(size=22)';
	}
	elsif($f->{type} eq 'boolean') {
		return 'checkbox';
	}
	elsif($f->{type} eq 'bytea') {
		return 'file';
	}
	else {
		die "unknown widget for type $f->{type} ($f->{table}:$f->{field}).\n";
	}
}

# Parse widget specification, split args, verify if it is a valid widget
sub DB_ParseWidget($;$)
{
	my $widget = shift;
	my $table = shift;
	$widget =~ /^(\w+)(\((.*)\))?$/ or die "syntax error for widget: $widget - ".($table||'?');
	my ($type, $args_str) = ($1, $3);
	my %args=();
	if(defined $args_str) {
		for my $w (SplitCommaQuoted($args_str)) {
			$w =~ s/^\s+//;
			$w =~ s/\s+$//;
			$w =~ /^(\w+)\s*=\s*(.*)$/ or die "syntax error in $type-widget argument: $w";
			$args{$1}=$2;
		}
	}

	# verify
	if($type eq 'idcombo' or $type eq 'hidcombo' or $type eq 'combo') {
		defined $args{'combo'} or
			die "widget $widget: mandatory argument 'combo' not defined\n";
	}
	if($type eq 'hidcombo' or $type eq 'hidisearch') {
		my $r = $args{'ref'};
		defined $r or
			die "widget $widget: mandatory argument 'ref' not defined\n";
		defined $g{db_tables}{$r} or
			die "widget $widget: no such table: $r";
		defined $g{db_fields}{$r}{"${r}_hid"} or
			die "widget $widget: table $r has no HID";
	}
	if($type eq 'format_number') {
		my $t = $args{'template'};
		defined $t or
			die "widget $widget: mandatory argument 'template' not defined\n";
		$t =~ /(0|9|\.|,|PR|S|L|D|G|MI|PL|SG|RN|TH|th|V|EEEE)+/  or
			die "widget $widget: template '$t' doesn't seem to be valid\n";
	}
	if($type eq 'format_date' or $type eq 'format_timestamp') {
		my $t = $args{'template'};
		defined $t or
			die "widget $widget: mandatory argument 'template' not defined\n";
		$t =~ /((FM|TH|th|FX|SP)?(HH|HH12|HH24|MI|SS|MS|US|SSS|AM|[aApP]\.?[mM]\.?|Y,YYY|Y{1,4}|[bB]\.?[cC]\.?|[aA]\.?[dD]\.?|MONTH|[mM]onth|month|MON|[mM]on|MM|DAY|[dD]ay|D[yY]|dy|D{1,3}|WW?|IW|CC|J|Q|RM|rm|TZ|tz))+/  or
			die "widget $widget: template '$t' doesn't seem to be valid\n";
	}
        if($type eq 'file2fs') {
                defined $g{conf}{file2fs_dir} or
                        die "widget $widget: mandatory conf property file2fs_dir is not set in the cgi wrapper";
        }
        if($type eq 'mncombo') {
	       $args{'mntable'} or die "widget $widget has no mntable argument";
	       $args{'combo'} ||= "$args{mntable}_combo";
	       # in order to ba able to paint the mncombo widget I have to
	       # know which table it appears in
	       $args{__table} = $table;
	       my %refs;       
	       for ( sort { $g{db_fields}{$args{'mntable'}}{$a}{order} <=>
                              $g{db_fields}{$args{'mntable'}}{$b}{order} }
                       keys %{$g{db_fields}{$args{'mntable'}}}  ){
		   /_order$/ && do { $args{__mntable_order} = $_; next };
                   if ( exists $g{db_fields}{$args{mntable}}{$_}{reference} ) {
  		       my $reference =  $g{db_fields}{$args{mntable}}{$_}{reference};
  		       $refs{$_} = $reference;
  		       if ( $reference eq $table and not $args{__mntable_left}){
  		           $args{__mntable_left} = $_;
  		       } else {
  		           $args{__mntable_right} = $_;
  		           # if we are selfreferencing then we will prefer the field name
  		           # to the field order when identifying the left-hand columnt
  		           if ($args{__mntable_right} =~ /_$table$/){
  		             ($args{__mntable_left},$args{__mntable_right}) 
  		                 = ($args{__mntable_right},$args{__mntable_left});
                           }
  		       }  		       
  		   }
               }
	       die "$widget in $table is not setup as I expected. Maybe mntable: $args{mntable} is not correct. Check gedafe-sql.pod\n".
	         "<pre>widget arguments:\n".(join "", map{"'$_' = '$args{$_}'\n"} sort keys %args)."</pre>"
		   unless $args{__mntable_left} and $args{__mntable_right};
                                                        
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
SELECT c.relname, a.attname,
       format_type(a.atttypid, a.atttypmod),
       a.attnum,
       a.atthasdef,
       a.attnotnull
FROM pg_class c, pg_attribute a, pg_namespace n
WHERE a.attnum > 0
AND a.attrelid = c.oid
AND (c.relkind = 'r' OR c.relkind = 'v')
AND c.relname !~ '^pg_'
AND a.attname != ('........pg.dropped.' || a.attnum || '........')
AND c.relnamespace = n.oid
AND n.nspname != 'information_schema'
END
	$sth = $dbh->prepare($query);
	$sth->execute() or die $sth->errstr;
	while ($data = $sth->fetchrow_arrayref()) {
		my ($table, $field, $type_formatted, $attnum, $atthasdef,
		    $attnotnull) = @$data;
		defined $tables->{$table} or next;
		if($field eq 'meta_sort') {
			$tables->{$table}{meta_sort}=1;
		}
		else {
			$type_formatted =~ m{^([^\(]+)(?:\((.*)\))?$} or
				warn "WARNING: can't parse type definition $type_formatted\n";
			my ($type, $type_args) = ($1, $2);
			# character varying -> character
			$type =~ s/^character varying$/character/;
			# bpchar -> character
			$type =~ s/^bpchar$/character/;
			# name -> character
			$type =~ s/^name$/character/;
			# double precision -> numeric
			$type =~ s/^double precision$/numeric/;
			# real  -> numeric
			$type =~ s/^real$/numeric/;
			# bigint -> integer
			$type =~ s/^bigint$/integer/;
			# timestamp xxxx -> timestamp
			$type =~ s/^timestamp.*/timestamp/;
			# time without time zone -> time
			$type =~ s/^time without time zone/time/;
			$fields{$table}{$field} = {
				field      => $field,
				order      => $attnum,
				type       => $type,
				type_args  => $type_args,
				attnum     => $attnum,
				atthasdef  => $atthasdef,
				attnotnull => $attnotnull,
			};
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
	while ($data = $sth->fetchrow_hashref()) {
		$meta_fields{lc($data->{meta_fields_table})}{lc($data->{meta_fields_field})}{lc($data->{meta_fields_attribute})} =
			$data->{meta_fields_value};
		# lets find virtual mncombo fields hand let them spring into existance
		# if a matching table is available
		if (lc($data->{meta_fields_attribute}) eq 'widget' and
		    lc($data->{meta_fields_value}) =~ /^mncombo/ and
		    exists $fields{lc($data->{meta_fields_table})} ) {
		    $fields{lc($data->{meta_fields_table})}{lc($data->{meta_fields_field})}{virtual} = 1;
		    $fields{lc($data->{meta_fields_table})}{lc($data->{meta_fields_field})}{desc} ||= $data->{meta_fields_field};
		}
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
                #            table  field               remote table
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
                        if ($field eq 'meta_bgcolour'){
                               $g{db_tables}{$table}{bgcolor_field_index}
                                =  $f->{order}-1; # calculate nr of column
                               $f->{hide_list}=1; # suppress color column
                        }

			my $m = undef;
			if(defined $meta_fields{$table}) {
				$m = $meta_fields{$table}{$field};
			}
			if(defined $m) {
			        $f->{javascript}= $m->{javascript};
				$f->{widget}    = $m->{widget};
				$f->{reference} = $m->{reference};
				$f->{copy}      = $m->{copy};
				$f->{sortfunc}  = $m->{sortfunc};
				$f->{markup}    = $m->{markup};
				$f->{align}     = $m->{align};
				$f->{desc}      = $m->{desc} if defined $m->{desc};
				$f->{hide_list} = $m->{hide_list};
				$f->{order}     = $m->{order} if defined $m->{order};
				if  ( defined $m->{bgcolor_field} 
				      and $m->{bgcolor_field} == 1 ){
				   # calculate nr of column 
				   # and override meta_bgcolor field
				   $g{db_tables}{$table}{bgcolor_field_index}
				    =  $f->{order}-1 ;
                                   $f->{hide_list}=1; # suppress color column

				}
			}
			$f->{widget} = DB_Widget(\%fields, $f);
		}
	}

	return \%fields;
}


sub DB_Connect($$$)
{
	my ($s, $user, $pass) = @_;

	my $dbh = DBI->connect_cached("$g{conf}{db_datasource}", $user, $pass,{ShowErrorStatement=>1,AutoCommit=>1})
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

	if($type eq 'boolean') {
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

sub DB_SearchWhere($$)
{
	my ($view, $search_spec) = @_;
	defined $search_spec         or return undef;
	ref($search_spec) eq 'ARRAY' or return undef;
	scalar(@{$search_spec})>0    or return undef;

	my $query = '';
	my @query_params = ();
	my @ands = ();

	for my $line (@$search_spec){
		my $field = $line->{field};
		my $field_type;
		if($field eq '#ALL#') {
			my @fieldlist = ();
			for my $f (@{$g{db_real_fields_list}{$view}}) {
				next if($g{db_fields}{$view}{$f}{type} eq 'bytea');
				next if($g{db_fields}{$view}{$f}{type} eq 'boolean');
				push @fieldlist, "COALESCE(${f}::text, '')";
			}
			$field = '('.join("||' '||",@fieldlist).')::text';
			$field_type = 'text';
		}
		else {
			$field_type = $g{db_fields}{$view}{$field}{type};
		}

		$query .= ' AND ' if $query;
		$query .= '(';
		for my $search_elem (@{$line->{parsed}}) {
			my $op = $search_elem->{op};
			if(not defined $op) {
				if($field_type eq 'varchar' or $field_type eq 'text') {
					$op = 'ilike';
				}
				else {
					$op = '=';
				}
			}
			$query .= $search_elem->{join_op};
			$query .= '(';
			$query .= 'NOT ' if $search_elem->{neg};
			$query .= $field;
			$query .= " $op ";
			$query .= '?' if defined $search_elem->{operand};
			$query .= ')';
			if(defined $search_elem->{operand}) {
				if($op eq 'ilike') {
					push @query_params, "\%$search_elem->{operand}\%";
				}
				else {
					push @query_params, $search_elem->{operand};
				}
			}
		}
		$query .= ')';
	}
	#print STDERR "## search: $query\n";
	return $query, \@query_params;
}

sub DB_FetchListSelect($$)
{
	my $dbh = shift;
	my $spec = shift;
	my $v = $spec->{view};

	# does the view/table exist?
	defined $g{db_real_fields_list}{$v}[0] or die "no such table: $v\n";

	# go through fields and build field list for SELECT (...)
	my @fields = @{$g{db_real_fields_list}{$v}};
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
			my $refcolumn = undef;
			if (defined  $explicittarget ){
				$refcolumn = $explicittarget;
			} else { 
			    for my $refcol (@{$g{db_real_fields_list}{$showref}}){
				my $refcolref = $g{db_fields}{$showref}{$refcol}{reference};
				next if(!defined $refcolref);
				if( $refcolref eq 
				    $spec->{table}){
					$refcolumn = $refcol;
					last; # End loop to make sure we
					# find the first referencing col
				}
			    }
			}
			die($spec->{table}." not referenced from $showref in meta_tables showref") if(!defined $refcolumn);
			
			push @select_fields,"(select count(*) from $showref as meta_rcsr where meta_rcsr.$refcolumn = $spec->{view}.$select_fields[0]) as meta_rc_${showref}";

			push @fields,"meta_rc_$showref#$refcolumn";
		}
	    
	}
	my @query_parameters = ();

	my $query = "SELECT ";
	$query .= $spec->{countrows} ? "COUNT(*)" : join(', ',@select_fields);
	$query .= " FROM $v";

	my ($search_where, $search_params) = DB_SearchWhere($spec->{view}, $spec->{search});
	if(defined $search_where) {
		$query .= " WHERE $search_where" if defined $search_where;
		push @query_parameters, @$search_params;
	}
	if(defined $spec->{filter_field} and defined $spec->{filter_value}) {
		$query .= $search_where ? ' AND ' : ' WHERE ';
		$query .= "$spec->{filter_field} = ? ";
		push @query_parameters, $spec->{filter_value};
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
			= {field     => $f,
			   table     => $1,
			   desc      => $g{db_tables}{$1}{desc},
			   align     => '"LEFT"',
			   refcount  => 1,
			   tar_field => $2,
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

	my @fields_list = @{$g{db_real_fields_list}{$table}};
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
	$query .= join(', ',@select_fields); # @{$g{db_real_fields_list}{$table}});
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

	if($type eq 'boolean') {
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
	my @fields_list = @{$g{db_real_fields_list}{$table}};

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
		my $value = $data->{$_};
		if($type eq "bytea") {
			#note the reference to the large blob
			$sth->bind_param($paramnumber,$$value,{ pg_type => DBD::Pg::PG_BYTEA });
		}
		else {
			$sth->bind_param($paramnumber,$value);
		}
		$paramnumber++;
	}
	delete $g{db_error};
	my $res = $sth->execute() or do {
		# report nicely the error
		$g{db_error}=$sth->errstr; return undef;
	};
	if($res ne 1 and $res ne '0E0') {
		die "Number of rows affected is not 1! ($res)";
	}
	return $sth->{'pg_oid_status'};
}

sub DB_AddRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = grep !/${table}_id/, @{$g{db_real_fields_list}{$table}};
	
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
	$dbh->begin_work();
	my $oid = DB_ExecQuery($dbh,$table,$query,\%dbdata,\@fields_list)
	    or do { $dbh->rollback(); return undef };
	_DB_MN_AddRecord($dbh, $table, $record, $oid);
        $dbh->commit();
        return 1;
}

sub DB_UpdateRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $record = shift;

	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_real_fields_list}{$table}};

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

        delete $g{db_error};        
	$dbh->begin_work();
	DB_ExecQuery($dbh,$table,$query,\%dbdata,\@updatefields);
	if ($g{db_error}){ $dbh->rollback();return undef };
        _DB_MN_DeleteRecord($dbh, $table, $record->{id}) or return undef;
        _DB_MN_AddRecord($dbh, $table, $record, undef) or return undef;
        $dbh->commit();
        return 1;

}

sub DB_GetCombo($$$$$)
{
	my $dbh = shift;
	my $combo_view = shift;
	my $mnfield = shift; # handle to the fields attributs
	my $mnrecord = shift; # value of the value if the lefthand record
	my $combo_data = shift;

	# return data is id,text followed by a true/false column in the case of
        # mncombo where the last column tells us if the entrie is selected or not.
	# in mncombo mode the selected entries are orderd if an _order column exists

        my $basesort;
	if(defined $g{db_tables}{$combo_view}{meta_sort}) {
               $basesort .= " meta_sort";
	}
	else {
               $basesort .= " text";
        }

	my $query;
	if ($mnfield) {
	  if ($mnrecord){
	    $query .= <<SQL;
select id,text,true as IsSelected 
 from $combo_view,$mnfield->{mntable} 
 where $mnfield->{__mntable_left} = $mnrecord and $mnfield->{__mntable_right} = id
 order by
SQL
            if ($mnfield->{__mntable_order}){
               $query .= "$mnfield->{__mntable_order}";
            } else {
               $query .= $basesort;
            }
           } else {
            $query .= <<SQL;
select id,text,false as isselected from $combo_view
ORDER BY $basesort
SQL
           }
        } else {
            $query .= <<SQL;
select id,text from $combo_view
ORDER BY $basesort
SQL
	}
	# print STDERR "$query\n";
	my $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	$sth->execute() or die $sth->errstr." in view $combo_view: $query";	
	while(my $data = $sth->fetchrow_arrayref()) {
	        # replace undef with '' in @$data
   	        map {$_ ||= '' } @$data;		
		push @$combo_data, [@$data]; # we have to copy $data here since my only generates one instance!
	}

        if ( $mnfield and $mnrecord ) {
          $query = <<SQL;
 select id,text,false as IsSelected 
 from $combo_view 
 where id not in ( select $mnfield->{__mntable_right} from $mnfield->{mntable} where $mnfield->{__mntable_left} = $mnrecord )
 order by $basesort;
SQL
	  $sth = $dbh->prepare_cached($query) or die $dbh->errstr;
	  $sth->execute() or die $sth->errstr." in view $combo_view: $query";	
	  while(my $data = $sth->fetchrow_arrayref()) {
	        # replace undef with '' in @$data
   	        map {$_ ||= '' } @$data;		
		push @$combo_data, [@$data]; # we have to copy $data here since my only generates one instance!
	  }	
        }
	die $sth->errstr if $sth->err;
	return 1;
}

sub DB_DeleteRecord($$$)
{
	my $dbh = shift;
	my $table = shift;
	my $id = shift;
        my @deletes;
        # before we remove the record, lets see if there are any uploads
        # mentioned in an fs2file widget left
        for my $field (keys %{$g{db_fields}{$table}}){
            next unless $g{db_fields}{$table}{$field}{widget};
            my $type = $g{db_fields}{$table}{$field}{widget_type};
	    my $warg = $g{db_fields}{$table}{$field}{widget_args};
            next unless $type eq 'file2fs';
            my $root = "/$g{conf}{file2fs_dir}";
            $root =~ s|//+|/|g;
            $root =~ s|(.)/+$|$1|g;
            my $prefix = "/$warg->{uploadpath}";
            $prefix =~ s|//+|/|g;
            $prefix =~ s|(.)/+$|$1|g;
            my $pathref = $dbh->selectcol_arrayref("SELECT $field from $table WHERE ${table}_id = $id");
            my $path = "/$pathref->[0]";
            $path =~ s|//+|/|g;
            $path =~ s|(.)/+$|$1|g;
            # do not touch fields refering files that are NOT in the
            # directory specified by the uploadpath parameter of the file2fs widget
            next unless $path =~ m|^$prefix/|;
            # skip if we can not write the directory where the referenced file is stored
            next unless -w "$root$prefix";
            next unless -d "$root$prefix";
            # skip if the file does not exist;
            next unless -f "$root$path";
            # skip if someone tries to go UP
            # or has two dots in the filename for some
            # other reason
            next if $path =~ m{\.\.};
            push @deletes, "$root$path";
        }

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
		$idcolumn = $g{db_real_fields_list}{$table}[0];
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
		$idcolumn = $g{db_real_fields_list}{$table}[0];
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

	my @fields = @{$g{db_real_fields_list}{$view}};
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
		elsif($type eq 'boolean') {
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

	my @fields = @{$g{db_real_fields_list}{$view}};
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
		elsif($type eq 'boolean') {
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

my %DB_Format_functions = (
	'number_to_char'    => [ 'to_char',      'int' ],
	'timestamp_to_char' => [ 'to_char',      'timestamp' ],
	'date_to_char'      => [ 'to_char',      'date' ],
	'char_to_number'    => [ 'to_number',    'varchar' ],
	'char_to_timestamp' => [ 'to_timestamp', 'varchar' ],
	'char_to_date'      => [ 'to_date',      'varchar' ],
);
sub DB_Format($$$$) {
	my ($dbh,$function,$template,$data) = @_;
	return '' if !defined $data or $data =~ /^\s*$/;
	my $func = $DB_Format_functions{$function}[0] or die;
	my $type = $DB_Format_functions{$function}[1] or die;
	my $q = "SELECT $func(cast (? as $type),?)";
        delete $g{db_error};	        
	my $sth = $dbh->prepare_cached($q) or die $dbh->errstr;
	$sth->execute($data,$template) or do {
		$g{db_error}=$sth->errstr;
		return undef;
	};
	my $d = $sth->fetchrow_arrayref();
	die $sth->errstr if $sth->err;
	my $formatted = $d->[0];
	# trim spaces
	$formatted =~ s/^\s+//;
	$formatted =~ s/\s+$//;
	return $formatted;
}

# MN Combo Helper Funtions
sub _DB_OID2ID($$$){
        my ($dbh, $table, $oid) = @_;
	# ID from the last insert into table
	my $id = ($dbh->selectrow_array(qq{SELECT ${table}_id FROM $table WHERE oid = ?},undef,$oid))[0]
	    or die "Could not find SELECT ${table}_id FROM $table WHERE oid = $oid :".$dbh->errstr;
	return $id;
};

sub _DB_MN_Insert($$$$$){
       my ($table, $vfield, $left_id, $right_id, $order_val) = @_;
       my $wa = $g{db_fields}{$table}{$vfield}{widget_args};
       my $mntable = $wa->{mntable};
       my $left = $wa->{__mntable_left};
       my $right = $wa->{__mntable_right};
       my $order = $wa->{__mntable_order};
       my $query = "INSERT INTO $mntable ($left,$right";
       $query .= ",$order" if $order;
       $query .= ") VALUES ( $left_id, $right_id";
       $query .= ",$order_val" if $order and defined $order_val;
       $query .= ");";       
       return $query;
};

sub _DB_MN_DeleteRecord($$$){
       my ($dbh,$table,$left_id) = @_;
       my $mnfields_listref = $g{db_virtual_fields_list}{$table};
       return 1 unless ref $mnfields_listref eq 'ARRAY';
       foreach my $vfield (@$mnfields_listref) {
	   my $mn = $g{db_fields}{$table}{$vfield};
	   next unless $mn->{widget} and $mn->{widget_type} eq 'mncombo';
	   my $wa = $mn->{widget_args};
	   my $mntable = $wa->{mntable};
	   my $left = $wa->{__mntable_left};
	   $dbh->do(qq{DELETE FROM $mntable WHERE $left = ?},undef,$left_id);
      	   if ($dbh->err){ $dbh->rollback(); $g{db_error} = $dbh->errstr; return undef };
       }
       return 1;
};

sub _DB_MN_AddRecord($$$$)
{
        my ($dbh, $table, $record, $oid) = @_;

	my $mnfields_listref = $g{db_virtual_fields_list}{$table};
	return 1 unless ref $mnfields_listref eq 'ARRAY';

	my $id = $record->{id} || _DB_OID2ID($dbh,$table,$oid);

	foreach my $vfield (@$mnfields_listref) {
                my $mn = $g{db_fields}{$table}{$vfield};
		next unless $mn->{widget} and $mn->{widget_type} eq 'mncombo';
                my $order = 0;
		foreach my $val ( @{$record->{$vfield}} ) {
                      my $query = _DB_MN_Insert($table, $vfield, $id, $val , $order++);
                      DB_ExecQuery($dbh,$table,$query,undef,[]) 
          	          or do{ $dbh->rollback(); $g{db_error} = $dbh->errstr; return undef };
               }
       }
       return 1;
}

1;

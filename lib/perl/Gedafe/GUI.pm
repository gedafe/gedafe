# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2002 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::GUI;
use strict;
use Gedafe::Global qw(%g);
use Gedafe::DB qw(
	DB_FetchList
	DB_GetRecord
	DB_AddRecord
	DB_UpdateRecord
	DB_GetCombo
	DB_DeleteRecord
	DB_GetDefault
	DB_ID2HID
);
use Gedafe::Util qw(
	ConnectToTicketsDaemon
	MakeURL
	MyURL
	Template
	DropUnique
	UniqueFormStart
	UniqueFormEnd
	NextRefresh
);

use POSIX;
use Data::Dumper;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK    = qw(
	GUI_Entry
	GUI_List
	GUI_CheckFormID
	GUI_PostEdit
	GUI_Edit
	GUI_Delete
);

sub GUI_InitTemplateArgs($$)
{
	my ($s, $args) = @_;
	my $q = $s->{cgi};

	my $refresh = NextRefresh();

	$args->{DATABASE_DESC}=$g{db_database}{desc};

	$args->{DOCUMENTATION_URL}=$g{conf}{documentation_url};
	$args->{THEME}=$q->url_param('theme');

	my $stripped_url = MakeURL($s->{url}, {
				filterfirst_button => '',
				search_button => '',
			});
	$args->{BOOKMARK_URL}=MakeURL($stripped_url, {
				refresh => '',
	});
	$args->{REFRESH_URL}=MakeURL($stripped_url, {
				refresh => $refresh,
	});

	my $logout_url = MakeURL($stripped_url, {
				logout => 1,
				refresh => '',
			});
	$args->{LOGOUT_URL}=$logout_url;

	my $entry_url = MakeURL($stripped_url, {
				id => '',
				action => '',
				orderby => '',
				table => '',
				offset => '',
				filterfirst => '',
				combo_filterfirst => '',
				descending => '',
				search_field => '',
				search_value => '',
				reedit_action => '',
				reedit_data => '',
			});
	$args->{ENTRY_URL}=$entry_url;
	$args->{REFRESH_ENTRY_URL}=MakeURL($entry_url, {
				refresh => $refresh,
			});
}

sub GUI_Header($$)
{
	my ($s, $args) = @_;

	$args->{ELEMENT}='header';
	print Template($args);

	my $t;
	$args->{ELEMENT}='header_table';
	my $user = $args->{USER};

	my $save_table = $args->{TABLE};

	foreach $t (@{$g{db_tables_list}}) {
		next if $g{db_tables}{$t}{hide};
		next if $g{db_tables}{$t}{report};
		if(defined $g{db_tables}{$t}{acls}{$user} and
			$g{db_tables}{$t}{acls}{$user} !~ /r/) { next; }
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$args->{TABLE_TABLE}=$t;
		$args->{TABLE_DESC}=$desc;
		$args->{TABLE_URL}=MakeURL($args->{REFRESH_ENTRY_URL}, {
				action => 'list',
				table  => $t,
				});
		print Template($args);
	}
	delete $args->{TABLE_DESC};
	delete $args->{TABLE_URL};
	$args->{TABLE} = $save_table;

	$args->{ELEMENT}='header2';
	print Template($args);

	delete $args->{ELEMENT};

	$s->{header_sent}=1;
}

sub GUI_Footer($)
{
	my ($args) = @_;
	$args->{ELEMENT}='footer';
	print Template($args);
	delete $args->{ELEMENT};
}

sub GUI_Edit_Error($$$$$$)
{
	my ($s, $user, $str, $form_url, $data, $action) = @_;
	my $q = $s->{cgi};

	my %template_args = (
		PAGE => 'edit_error',
		USER => $user,
		TITLE => 'Database Error',
		ERROR => $str,
		REEDIT_URL => MakeURL($form_url, {
				action => 'reedit',
				reedit_action => $action,
				reedit_data => $data,
			}),
	);

	GUI_InitTemplateArgs($s, \%template_args);
	GUI_Header($s, \%template_args);

	$template_args{ELEMENT}='edit_error';
	print Template(\%template_args);

	GUI_Footer(\%template_args);
	exit;
}

sub GUI_CheckFormID($$)
{
	my ($s, $user) = @_;
	my $q = $s->{cgi};

	my $next_url = $q->param('next_url');
	my %template_args = (
		PAGE => 'doubleform',
		USER => $user,
		TITLE => "Duplicate Form",
		NEXT_URL => $next_url,
	);

	if(!DropUnique($s, $q->param('form_id'))) {
		print $q->header;
		GUI_InitTemplateArgs($q, \%template_args);
		GUI_Header($s, \%template_args);
		$template_args{ELEMENT}='doubleform';
		print Template(\%template_args);
		GUI_Footer(\%template_args);
		exit;
	}
}

sub GUI_Entry($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};

	my $refresh = NextRefresh();

	my %template_args = (
		USER => $user,
		TITLE => 'Entry',
		PAGE => 'entry',
	);

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header($s, \%template_args);

	$template_args{ELEMENT}='tables_list_header',
	print Template(\%template_args);

	my $t;
	$template_args{ELEMENT}='entrytable';
	foreach $t (@{$g{db_tables_list}}) {
		next if $g{db_tables}{$t}{hide};
		next if $g{db_tables}{$t}{report};
		if(defined $g{db_tables}{$t}{acls}{$user} and
			$g{db_tables}{$t}{acls}{$user} !~ /r/) { next; }
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$template_args{TABLE_DESC}=$desc;
		$template_args{TABLE_URL}= MakeURL($s->{url}, {
					action => 'list',
					table  => $t,
					refresh => $refresh,
				});
		print Template(\%template_args);
	}
	delete $template_args{TABLE_DESC};
	delete $template_args{TABLE_URL};

	$template_args{ELEMENT}='reports_list_header';
	print Template(\%template_args);

	$template_args{ELEMENT}='entrytable';
	foreach $t (@{$g{db_tables_list}}) {
		next if     $g{db_tables}{$t}{hide};
		next unless $g{db_tables}{$t}{report};
		if(defined $g{db_tables}{$t}{acls}{$user} and
			$g{db_tables}{$t}{acls}{$user} !~ /r/) { next; }
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$template_args{TABLE_DESC}=$desc;
		$template_args{TABLE_URL}= MakeURL($s->{url}, {
					action => 'list',
					table  => $t,
					refresh => $refresh,
				});
		$template_args{REPORT}=1;
		print Template(\%template_args);
	}

	GUI_Footer(\%template_args);
}

sub GUI_EditLink($$$)
{
	my ($s, $list, $row) = @_;
	my $edit_url;
	$edit_url = MakeURL($s->{url}, {
		action=>'edit',
		id=>$row->[0],
		refresh=>NextRefresh,
	}); 
	$template_args->{ELEMENT}='td_edit';
	$template_args->{EDIT_URL}=$edit_url;
	print Template(\%template_args);
	delete $template_args{EDIT_URL};
}

sub GUI_DeleteLink($$$)
{
	my ($s, $list, $row) = @_;
	my $delete_url;
	$delete_url =  MakeURL($s->{url}, {
		action=>'delete',
		id=>$row->[0],
		refresh=>NextRefresh,
	});
	$template_args{ELEMENT}='td_delete';
	$template_args{DELETE_URL}=$delete_url;
	return Template(\%template_args);
	delete $template_args{DELETE_URL};
}

sub GUI_ListTable($$$)
{
	my ($s, $list, $page) = @_;

	my $can_edit = ($list->{acl} =~ /w/);
	my $can_delete = $can_edit;

	my %template_args = (
		USER => $s->{user},
		PAGE => $page,
		URL => $s->{url},
		TABLE => $list->{spec}{view},
		TITLE => "$g{db_tables}{$list->{spec}{table}}{desc}",
		ORDERBY => $list->{spec}{orderby},
	);

	my $fields = $g{db_fields}{$list->{spec}{view}};

	# <TABLE>
	$template_args{ELEMENT}='table';
	print Template(\%template_args);
	$s->{in_table}=1; # die will put a </TABLE>

	# header
	$template_args{ELEMENT}='tr';
	print Template(\%template_args);
	for my $f (@{$list->{fields}}) {
		my $sort_url;
		if($list->{spec}{orderby} eq $f) {
			my $d = $list->{spec}{descending} ? '' : 1;
			$sort_url = MakeURL($s->{url}, { descending => $d });
		}
		else {
			$sort_url = MakeURL($s->{url}, { orderby => "$f", descending=>'' });
		}

		$template_args{ELEMENT}='th';
		$template_args{DATA}=$fields->{$f}{desc};
		$template_args{FIELD}=$f;
		$template_args{SORT_URL}=$sort_url;
		print Template(\%template_args);
	}
	delete $template_args{DATA};
	delete $template_args{FIELD};
	delete $template_args{SORT_URL};
	if($can_edit) {
		$template_args{ELEMENT}='th_edit';
		print Template(\%template_args);
	}
	if($can_delete) {
		$template_args{ELEMENT}='th_delete';
		print Template(\%template_args);
	}
	$template_args{ELEMENT}='xtr';
	print Template(\%template_args);

	# data
	for my $row (@{$list->{data}}) {
		$template_args{ELEMENT}='tr';
		print Template(\%template_args);

		for my $d (@{$row->[1]}) {
			$template_args{ELEMENT}='td';
			$template_args{DATA}=$d;
			print Template(\%template_args);
		}

		print GUI_EditLink($s, $list, $row) if $can_edit;
		print GUI_DeleteLink($s, $list, $row) if $can_delete;

		$template_args{ELEMENT}='xtr';
		delete $template_args{DATA};
		print Template(\%template_args);
	}

	# </TABLE>
	$template_args{ELEMENT}='xtable';
	print Template(\%template_args);
	$s->{in_table}=0;
}

sub GUI_ListButtons($$$$)
{
	my ($s, $list, $page, $position) = @_;

	my $next_refresh = NextRefresh;

	my $nextoffset = $list->{offset}+$list->{limit};
	my $prevoffset = $list->{offset}-$list->{limit};
	$prevoffset >= 0 or $prevoffset = 0;

	my $add_url  = $can_add ? MakeURL($s->{url}, {
			action => 'add',
			refresh => $next_refresh,
		}) : undef;

	my $prev_url = $list->{offset} != 0 ? MakeURL($s->{url},
		{ offset => $prevoffset }) : undef;
	my $next_url = $list->{end} ? MakeURL($s->{url},
		{ offset => $nextoffset }) : undef;

	$template_args{ELEMENT}='buttons';
	$template_args{ADD_URL}=$add_url;
	$template_args{PREV_URL}=$prev_url;
	$template_args{NEXT_URL}=$next_url;
	print Template(\%template_args);
}

sub GUI_List($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};
	my $table = $q->url_param('table');

	my %template_args = (
		USER => $user,
		PAGE => 'list',
		URL => $s->{url},
		TABLE => $table,
		TITLE => "$g{db_tables}{$table}{desc}",
	);

	# header
	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header($s, \%template_args);

	# build list-spec
	my %spec = (
		table => $table,
		view => defined $g{db_tables}{"${table}_list"} ?
			"${table}_list" : $table,
		offset => $q->url_param('offset') || 0,
		limit => $q->url_param('list_rows') || $g{conf}{list_rows},
		orderby => $q->url_param('orderby') || '',
		descending => $q->url_param('descending') || 0,
	);

	# fetch list
	my $list = DB_FetchList($s, \%spec);
	
	# top buttons
	GUI_ListButtons($s, $list, 'list', 'top');

	# display table
	GUI_ListTable($s, $list, 'list');

	# bottom buttons
	GUI_ListButtons($s, $list, 'list', 'bottom');

	# footer
	GUI_Footer(\%template_args);
}

# CGI.pm already encodes/decodes parameters, but we want to do it ourselves
# since we need to differentiate for example in reedit_data between a comma
# as value and a comma as separator. Therefore we use the escape '!' instead
# of '%'.
sub GUI_URL_Encode($)
{
	my ($str) = @_;
	defined $str or $str = '';
	$str =~ s/!/gedafe_PROTECTED_eXclamatiOn/g;
	$str =~ s/\W/'!'.sprintf('%2X',ord($&))/eg;
	$str =~ s/gedafe_PROTECTED_eXclamatiOn/'!'.sprintf('%2X',ord('!'))/eg;
	return $str;
}

sub GUI_URL_Decode($)
{
	my ($str) = @_;
	$str =~ s/!([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return $str;
}

sub GUI_Hash2Str($)
{
	my ($record) = @_;
	my @data = ();
	for my $f (keys %$record) {
		my $d = GUI_URL_Encode($record->{$f});
		push @data, "$f:$d";
	}
	return join(',', @data);
}

sub GUI_Str2Hash($)
{
	my ($str) = @_;
	my %hash = ();
	for my $s (split(/,/, $str)) {
		if($s =~ /^(.*?):(.*)$/) {
			$hash{$1} = GUI_URL_Decode($2);
		}
	}
	return \%hash;
}

sub GUI_WidgetRead($$)
{
	my ($s, $f) = @_;
	my $q = $s->{cgi};
	my $dbh = $s->{dbh};
	my $field = $f->{field};
	my $w = $f->{widget_type};

	my $value = $q->param("field_$field");

	if($w eq 'hid' or $w eq 'hidcombo') {
		if(defined $value and $value !~ /^\s*$/) {
			$value=DB_HID2ID($dbh,$f->{widget_args}{'ref'},$value);
		}
	}
}

sub GUI_PostEdit($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};

	my $action = $q->param('post_action');
	if(not defined $action) { return; }

	if(defined $q->param('button_cancel')) { return; }

	my $table = $q->url_param('table');

	## delete
	if($action eq 'delete') {
		if(!DB_DeleteRecord($dbh,$table,$q->param('id'))) {
			my %template_args = (
				PAGE => 'db_error',
				USER => $user,
				TITLE => 'Database Error'
			);
			GUI_InitTemplateArgs($q, \%template_args);
			GUI_Header($s, \%template_args);
			GUI_DB_Error($g{db_error}, MyURL($q));
			
			$template_args{ELEMENT}='db_error';
			$template_args{ERROR}=$g{db_error};
			$template_args{NEXT_URL}=MyURL($q);
			print Template(\%template_args);

			GUI_Footer(\%template_args);
		}
	}


	## add or edit:
	my %record;
	foreach($q->param) {
		if(/^field_(.*)/) {
			$record{$1} = $q->param($_);
		}
	}

	# combo
	my $p;
	foreach $p ($q->param) {
		if($p =~ /^combo_(.*)/) {
			my $f = $1;
			if((not defined $record{$f}) or ($record{$f} =~ /^\s*$/)) {
				$record{$f} = $q->param($p);
			}
		}
	}

	if($action eq 'add') {
		if(!DB_AddRecord($dbh,$table,\%record)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($s, $user, $g{db_error}, $q->param('form_url'), $data, $action);
		}
	}
	elsif($action eq 'edit') {
		$record{id} = $q->param('id');
		if(!DB_UpdateRecord($dbh,$table,\%record)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($s, $user, $g{db_error}, $q->param('form_url'), $data, $action);
		}
	}
}

sub GUI_Edit($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};
	my $action = $q->url_param('action');
	my $table = $q->url_param('table');
	my $id = $q->url_param('id');

	my $reedit = undef;
	if($action eq 'reedit') {
		$reedit = 1;
		$action = $q->url_param('reedit_action');
	}

	if(not exists $g{db_tables}{$table}) {
		die "Error: no such table ($table)";
	}

	my $title = $g{db_tables}{$table}{desc};
	$title =~ s/s\s*$//; # very rough :-)
	$title =~ s/^. //;
	my %template_args = (
		USER => $user,
		PAGE => 'edit',
		TABLE => $table,
		TITLE => $action eq 'add' ? "New $title" : "Edit $title",
		ACTION => $action,
		ID => $id,
		REEDIT => $reedit,
	);

	my $form_url = MakeURL($s->{url}, { refresh => NextRefresh() });
	my $next_url;
	my $cancel_url = MakeURL($form_url, {
		action => 'list',
		id => '',
		reedit_action => '',
		reedit_data => '',
	});
	if($action eq 'add') {
		$next_url = MakeURL($form_url, {
			action => $action,
			reedit_action => '',
			reedit_data => '',
		});
	}
	else {
		$next_url = $cancel_url;
	}

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header($s, \%template_args);

	# FORM
	UniqueFormStart($s, $next_url);
	print "<INPUT TYPE=\"hidden\" NAME=\"post_action\" VALUE=\"$action\">\n";

	# Initialise values
	my $fields = $g{db_fields}{$table};
	my @fields_list = @{$g{db_fields_list}{$table}};
	my %values = ();
	if($reedit) {
		GUI_Str2Hash($q->param('reedit_data'), \%values);
	}
	elsif($action eq 'edit') {
		my %record = ();
		DB_GetRecord($dbh,$table,$id,\%values);
	}
	elsif($action eq 'add') {
		# take filterfirst value if set
		my $ff_field = $g{db_tables}{$table}{meta}{filterfirst};
		my $ff_value = $q->url_param('filterfirst') || $q->url_param('combo_filterfirst') || '';
		if(defined $ff_value and defined $ff_field) {
			if(defined $g{db_fields}{$table}{$ff_field}{ref_hid}) {
				# convert ID reference to HID
				$values{$ff_field} = DB_ID2HID($dbh, $g{db_fields}{$table}{$ff_field}{reference}, $ff_value);
			}
		}
		# copy fields from previous add form
		foreach(@fields_list) {
			my $v = $q->param("field_$_") || $q->param("combo_$_");
			if(defined $v and $g{db_fields}{$table}{$_}{copy}) {
				$values{$_} = $v;
			}
		}
	}

	if($action eq 'edit') {
		print "<INPUT TYPE=\"hidden\" NAME=\"id\" VALUE=\"$id\">\n";
	}

	# Fields
	$template_args{ELEMENT} = 'editform_header';
	print Template(\%template_args);

	my $field;
	foreach $field (@fields_list) {
		if($field eq "${table}_id") { next; }

		my $value = exists $values{$field} ? $values{$field} : '';
		my $inputelem = GUI_EditField($s,$dbh,$table,$field,$value);

		$template_args{ELEMENT} = 'editfield';
		$template_args{FIELD} = $field;
		$template_args{LABEL} = $fields->{$field}{desc};
		$template_args{INPUT} = $inputelem,
		print Template(\%template_args);
	}
	delete $template_args{FIELD};
	delete $template_args{LABEL};
	delete $template_args{INPUT};
	
	# Fields
	$template_args{ELEMENT} = 'editform_footer';
	print Template(\%template_args);

	# Buttons
	$template_args{ELEMENT} = 'buttons';
	$template_args{CANCEL_URL} = $cancel_url;
	print Template(\%template_args);

	UniqueFormEnd($s, $form_url, $next_url);
	GUI_Footer(\%template_args);
}

sub GUI_MakeCombo($$$$$)
{
	my ($dbh, $table, $field, $name, $value) = @_;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	my $str;

	my $meta = $g{db_fields}{$table}{$field};
	if(exists $meta->{ref_combo}) {
		my @combo;
		if(not defined DB_GetCombo($dbh,$meta->{reference},\@combo)) {
			return undef;
		}
		$str = "<SELECT SIZE=\"1\" name=\"$name\">\n";
                # the empty option must not be empty! else the MORE ... disapears off screen
		$str .= "<OPTION VALUE=\"\">Make your Choice ...</OPTION>\n";
		foreach(@combo) {
			my $id = $_->[0];
			$id=~s/^\s+//; $id=~s/\s+$//;
			#my $text = "$_->[0] -- $_->[1]";
			my $text = $_->[1];
			if($value eq $id) {
				$str .= "<OPTION SELECTED VALUE=\"$id\">$text</OPTION>\n";
			}
			else {
				$str .= "<OPTION VALUE=\"$id\">$text</OPTION>\n";
			}
		}
		$str .= "</SELECT>\n";
	}
}

sub GUI_EditField($$$$)
{
	my ($dbh, $table, $field, $value) = @_;

	my $f = $g{db_fields}{$table}{$field};

	# get default from DB
	if(not defined $value or $value eq '') {
		$value = DB_GetDefault($dbh,$table,$field);
		if(not defined $value) {
			$value = '';
		}
	}

	if($widget eq 'readonly') {
		return $value || '&nbsp;';
	}

	if($widget eq 'area') {
		return "<TEXTAREA NAME=\"field_$field\" ROWS=\"4\" COLS=\"60\" WRAP=\"virtual\">".
			$value."</TEXTAREA>";
	}
	if($type eq 'date') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"10\" VALUE=\"".$value."\">";
	}
	if($type eq 'time') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"10\" VALUE=\"".$value."\">";
	}
	if($type eq 'timestamp') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"22\" VALUE=\"".$value."\">";
	}
	if($type eq 'int4') {
		my $out;
		if(exists $meta->{ref_combo}) {
			$out.="<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=10>";
		}
		else {
			$out.="<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=10 VALUE=\"$value\">";
		}
		$out .= GUI_MakeCombo($dbh, $table, $field, "combo_$field", $value);
		return $out;
	}
	if($type eq 'numeric' or $type eq 'float8') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"10\" VALUE=\"$value\">";
	}
	if($type eq 'bpchar') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"30\" VALUE=\"$value\">";
	}
	if($type eq 'text') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"40\" VALUE=\"$value\">";
	}
        if($type eq 'varchar') {                                                                                            
                return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"20\" MAXLENGTH=\"$length\" VALUE=\"$value\">";        
        }                                                                                                                   

	if($type eq 'name') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=\"20\" VALUE=\"$value\">";
	}
	if($type eq 'bool') {
		if($value) {
			return "<INPUT TYPE=\"checkbox\" NAME=\"field_$field\" VALUE=\"1\" CHECKED>";
		}
		else {
			return "<INPUT TYPE=\"checkbox\" NAME=\"field_$field\" VALUE=\"1\">";
		}
	}

	return "Unknown type: $type";
}

sub GUI_Delete($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};
	my $table = $q->url_param('table');
	my $id = $q->url_param('id');
	my $next_url = MakeURL($s->{url}, { action=>'list', id=>'' });

	my %template_args = (
		PAGE => 'delete',
		USER => $user,
		TITLE => "Delete Record",
		TABLE => $table,
		ID => $id,
		NEXT_URL => $next_url,
	);

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header($s, \%template_args);
	UniqueFormStart($s, $next_url);

	$template_args{ELEMENT}='delete';
	print Template(\%template_args);

	print "<INPUT TYPE=\"hidden\" NAME=\"post_action\" VALUE=\"delete\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"id\" VALUE=\"$id\">\n";
	UniqueFormEnd($s, $next_url, $next_url);
	GUI_Footer(\%template_args);
}

1;

# vi: tw=0

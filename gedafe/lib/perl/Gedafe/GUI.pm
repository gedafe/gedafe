# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::GUI;
use strict;
use Gedafe::Global qw(%g);
use Gedafe::DB;
use Gedafe::Util;

use CGI;
use POSIX;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(
	GUI_Entry
	GUI_List
	GUI_ListRep
	GUI_Form
	GUI_xForm
	GUI_CheckFormID
	GUI_PostEdit
	GUI_Edit
	GUI_Delete
	GUI_DB_Error
	GUI_DB_Error_Form
	GUI_NextRefresh
);

sub rand_ascii_32
{
	return sprintf "%04x%04x", rand()*(1<<16), rand()*(1<<16);
}

sub GUI_NextRefresh(;$)
{
	return rand_ascii_32;
}

sub GUI_DB2HTML($$)
{
	my $str = shift;
	my $type = shift;

	# undef -> ''
	$str = '' unless defined $str;

	# trim space
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;

	if($type eq 'text') {
		$str =~ s/\n/<BR>/;
	}
	if($str eq '') {
		$str = '&nbsp;';
	}

	return $str;
}

sub GUI_InitTemplateArgs($$)
{
	my $q = shift;
	my $args = shift;

	my $refresh = GUI_NextRefresh($q);

	$args->{DOCUMENTATION_URL}=$g{conf}{documentation_url};
	$args->{THEME}=$q->url_param('theme');

	my $stripped_url = MakeURL(MyURL($q), {
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

sub GUI_Header($)
{
	my $args = shift;

	$args->{ELEMENT}='header';
	print Template($args);

	my $t;
	$args->{ELEMENT}='header_table';
	my $user = $args->{USER};

	my $save_table = $args->{TABLE};
	
	foreach $t (@{$g{db_editable_tables_list}}) {
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
}

sub GUI_Footer($)
{
	my $args = shift;
	$args->{ELEMENT}='footer';
	print Template($args);
	delete $args->{ELEMENT};
}

sub GUI_Edit_Error($$$$$$)
{
	my $q = shift;
	my $user = shift;
	my $str = shift;
	my $form_url = shift;
	my $data = shift;
	my $action = shift;

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

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header(\%template_args);

	$template_args{ELEMENT}='edit_error';
	print Template(\%template_args);

	GUI_Footer(\%template_args);
	exit;
}

sub GUI_DB_Error($$)
{
	my $str = shift;
	my $url = shift;

	print Template({
		PAGE => 'db_error',
		ELEMENT => 'db_error',
		ERROR => $str,
		NEXT_URL => $url,
	});
	exit;
}

sub GUI_Form($)
{
	my $action = shift;
	print "<FORM ACTION=\"$action\" METHOD=\"POST\">\n";
}

sub GUI_GetUnique
{
	# unique_id
	my $socket = ConnectToTicketsDaemon();
	print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
	<$socket>;
	print $socket "GETUNIQUE\n";
	$_ = <$socket>;
	close($socket);
	if(! /^([\w-]+)$/) {
		die "Couldn't understand ticket daemon reply: $_";
	}
	return $1;
}

sub GUI_DropUnique($)
{
	my $unique_id = shift;
	if(defined $unique_id) {
		my $socket = ConnectToTicketsDaemon();
		print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
		<$socket>;
		print $socket "DROPUNIQUE $unique_id\n";
		$_ = <$socket>;
		close($socket);
		if(!/^OK$/) {
			return 0;
		}
	}
	return 1;
}

sub GUI_xForm($;$)
{
	my $form_url = shift;
	my $next_url = shift || $form_url;

	my $form_id = GUI_GetUnique;

	print "\n<INPUT TYPE=\"hidden\" NAME=\"form_id\" VALUE=\"$form_id\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"form_url\" VALUE=\"$form_url\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"next_url\" VALUE=\"$next_url\">\n";
	print "</FORM>\n";
}

sub GUI_CheckFormID($$)
{
	my $user = shift;
	my $q = shift;

	my $next_url = $q->param('next_url');
	my %template_args = (
		PAGE => 'doubleform',
		USER => $user,
		TITLE => "Duplicate Form",
		NEXT_URL => $next_url,
	);

	if(!GUI_DropUnique($q->param('form_id'))) {
		print $q->header;
		GUI_InitTemplateArgs($q, \%template_args);
		GUI_Header(\%template_args);
		$template_args{ELEMENT}='doubleform';
		print Template(\%template_args);
		GUI_Footer(\%template_args);
		exit;
	}
}

sub GUI_Entry($$$)
{
	my $q = shift;
	my $user = shift;
	my $dbh = shift;

	my $refresh = GUI_NextRefresh($q);

	my %template_args = (
		USER => $user,
		TITLE => 'Entry',
		PAGE => 'entry',
	);

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header(\%template_args);

	$template_args{ELEMENT}='tables_list_header',
	print Template(\%template_args);

	my $t;
	$template_args{ELEMENT}='entrytable';
	foreach $t (@{$g{db_editable_tables_list}}) {
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$template_args{TABLE_DESC}=$desc;
		$template_args{TABLE_URL}= MakeURL(MyURL($q), {
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
	foreach $t (@{$g{db_report_views}}) {
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$template_args{TABLE_DESC}=$desc;
		$template_args{TABLE_URL}= MakeURL(MyURL($q), {
					action => 'listrep',
					table  => $t,
					refresh => $refresh,
				});
		$template_args{REPORT}=1;
		print Template(\%template_args);
	}

	GUI_Footer(\%template_args);
}

sub GUI_FilterFirst($$$$)
{
	my $dbh = shift;
	my $q = shift;
	my $view = shift;
	my $template_args = shift;
	my $myurl = MyURL($q);
	my $filterfirst_field = $g{db_tables}{$view}{filterfirst};
	my $filterfirst_value = $q->url_param('filterfirst') || $q->url_param('combo_filterfirst') || '';

	# filterfirst
	if(defined $filterfirst_field)
	{
		if(not defined $g{db_fields}{$view}{$filterfirst_field}{ref_combo}) {
			GUI_DB_Error("combo not found for $filterfirst_field.", $myurl);
		}
		else {
			my $filterfirst_combo = GUI_MakeCombo($dbh, $view, $filterfirst_field, "combo_filterfirst", $filterfirst_value);
			my $filterfirst_hidden = '';
			foreach($q->url_param) {
				next if /^filterfirst/;
				next if /button$/;
				$filterfirst_hidden .= "<INPUT TYPE=\"hidden\" NAME=\"$_\" VALUE=\"".$q->url_param($_)."\">\n";
			}
			$template_args->{ELEMENT}='filterfirst';
			$template_args->{FILTERFIRST_FIELD}=$filterfirst_field;
			$template_args->{FILTERFIRST_FIELD_DESC}=$g{db_fields}{$view}{$filterfirst_field}{desc};
			$template_args->{FILTERFIRST_COMBO}=$filterfirst_combo;
			$template_args->{FILTERFIRST_HIDDEN}=$filterfirst_hidden;
			$template_args->{FILTERFIRST_ACTION}=$g{conf}{app_url};
			print Template($template_args);
			delete $template_args->{ELEMENT};
			delete $template_args->{FILTERFIRST_FIELD};
			delete $template_args->{FILTERFIRST_FIELD_DESC};
			delete $template_args->{FILTERFIRST_COMBO};
			delete $template_args->{FILTERFIRST_HIDDEN};
			delete $template_args->{FILTERFIRST_ACTION};
		}
		if($filterfirst_value eq '') { $filterfirst_value = undef; }
	}

	return ($filterfirst_field, $filterfirst_value);
}

sub GUI_Search($$$)
{
	my $q = shift;
	my $view = shift;
	my $template_args = shift;
	my $search_field = $q->url_param('search_field') || '';
	my $search_value = $q->url_param('search_value') || '';

	$search_field =~ s/^\s*//; $search_field =~ s/\s*$//;
	$search_value =~ s/^\s*//; $search_value =~ s/\s*$//;
	my $fields = $g{db_fields}{$view};
	my $search_combo = "<SELECT name=\"search_field\" SIZE=\"1\">\n";
	foreach(@{$g{db_fields_list}{$view}}) {
		next if /${view}_id/;
		if(/^$search_field$/) {
			$search_combo .= "<OPTION SELECTED VALUE=\"$_\">$fields->{$_}{desc}</OPTION>\n";
		}
		else {
			$search_combo .= "<OPTION VALUE=\"$_\">$fields->{$_}{desc}</OPTION>\n";
		}
	}
	$search_combo .= "</SELECT>\n";
	my $search_hidden = '';
	foreach($q->url_param) {
		next if /^search/;
		next if /^button/;
		next if /^offset$/;
		$search_hidden .= "<INPUT TYPE=\"hidden\" NAME=\"$_\" VALUE=\"".$q->url_param($_)."\">\n";
	}
	$template_args->{ELEMENT} = 'search';
	$template_args->{SEARCH_ACTION} = $g{conf}{app_url};
	$template_args->{SEARCH_COMBO} = $search_combo;
	$template_args->{SEARCH_HIDDEN} = $search_hidden;
	$template_args->{SEARCH_VALUE} = $search_value;
	$template_args->{SEARCH_SHOWALL} = MakeURL(MyURL($q), { search_value=>'', search_button=>'', search_field=>'' });
	print Template($template_args);
	delete $template_args->{ELEMENT};
	delete $template_args->{SEARCH_ACTION};
	delete $template_args->{SEARCH_COMBO};
	delete $template_args->{SEARCH_HIDDEN};
	delete $template_args->{SEARCH_VALUE};
	delete $template_args->{SEARCH_SHOWALL};

	# search date = TODAY
	if($search_field ne '') {
		if($g{db_fields}{$view}{$search_field}{type} eq 'date') {
			if($search_value =~ /^today$/i) {
				$search_value = POSIX::strftime("%Y-%m-%d", localtime);
			}
			elsif($search_value =~ /^yesterday$/i) {
				my $time = time;
				$time -= 3600 * 24;
				$search_value = POSIX::strftime("%Y-%m-%d", localtime($time));
			}
		}
	}

	return ($search_field, $search_value);
}

sub GUI_List($$$)
{
	my $q = shift;
	my $user = shift;
	my $dbh = shift;
	my $myurl = MyURL($q);
	my $table = $q->url_param('table');
	my $orderby = $q->url_param('orderby') || '';
	my $descending = $q->url_param('descending') || '';
	my $can_add = ($g{db_tables}{$table}{acls}{$user} =~ /a/);
	my $can_edit = ($g{db_tables}{$table}{acls}{$user} =~ /w/);
	my $can_delete = ($g{db_tables}{$table}{acls}{$user} =~ /w/);

	my $next_refresh = GUI_NextRefresh($q);

	my %template_args = (
		USER => $user,
		PAGE => 'list',
		URL => $myurl,
		TABLE => $table,
		TITLE => "$g{db_tables}{$table}{desc}",
	);
	
	# select view / table
	my $view;
	if(exists $g{db_tables}{"${table}_list"}) {
		$view = "${table}_list";
	}
	else {
		$view = $table;
	}
	if(not defined $g{db_fields_list}{$view}) {
		GUI_InitTemplateArgs($q, \%template_args);
		GUI_Header(\%template_args);
		print "<P>Can't find table $view\n";
		GUI_Footer(\%template_args);
		return;
	}
	my @fields_list = @{$g{db_fields_list}{$view}};
	my $fields = $g{db_fields}{$view};

	# header
	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header(\%template_args);

	# filterfirst
	my ($filterfirst_field, $filterfirst_value) =  GUI_FilterFirst($dbh, $q, $table, \%template_args);

	# search
	my ($search_field, $search_value) = GUI_Search($q, $view, \%template_args);

	# TABLE
	$template_args{ELEMENT}='table';
	print Template(\%template_args);

	my $f;
	my $skip_id = 0;
	# if hid, then do not show id.
	if(grep /^${table}_hid$/, @fields_list) {
		$skip_id = 1;
	}
	# orderby
	if($orderby eq '') {
		if(not defined $g{db_tables}{$view}{meta_sort}) {
			$orderby = $skip_id ? $fields_list[1] : $fields_list[0];
		}
	}
	$template_args{ORDERBY}=$orderby;

	# HEADER
	$template_args{ELEMENT}='tr';
	$template_args{HEADER}=1;
	print Template(\%template_args);

	foreach $f (@fields_list) {
		if($skip_id and $f eq "${table}_id") { next; }

		my $sort_url;
		if($orderby eq $f) {
			if($descending) {
				$sort_url = MakeURL($myurl, { descending=>'' });
			}
			else {
				$sort_url = MakeURL($myurl, { descending=>1 });
			}
		}
		else {
			$sort_url = MakeURL($myurl, { orderby=>"$f", descending=>'' });
		}

		$template_args{ELEMENT}='th';
		$template_args{DATA}=$fields->{$f}{desc};
		$template_args{FIELD}=$f;
		$template_args{SORT_URL}=$sort_url;
		print Template(\%template_args);
		delete $template_args{DATA};
		delete $template_args{SORT_URL};
	}
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
	delete $template_args{HEADER};

	# data
	my $offset = $q->url_param('offset') || 0;
	my $fetch_state=0;
	my $data;
	my $fetched = 0;
	my $fetchamount = $q->url_param('list_rows') || $g{conf}{list_rows};
	my $error=undef;
	while(defined ($data = DB_FetchList(\$fetch_state,$dbh,$view,\$error,
		-descending => $descending,
		-orderby => $orderby,
		-limit => $fetchamount+1,
		-offset => $offset,
		-fields => \@fields_list,
		-search_field => $search_field,
		-search_value => $search_value,
		-filter_field => $filterfirst_field,
		-filter_value => $filterfirst_value)))
	{
		$fetched++;
		if($fetched>$fetchamount) { next; }
		my $id = $data->[0];

		if($fetched%2) { $template_args{EVENROW}=1; }
		else           { $template_args{ODDROW}=1; }

		$template_args{ELEMENT}='tr';
		$template_args{ID}=$id;
		print Template(\%template_args);

		my $i=0;
		$template_args{ELEMENT}='td';
		my $skip_first = $skip_id;
		my $d;
		foreach $d (@$data) {
			if($skip_first) {
				$skip_first=0;
			}
			else {
				my $field_name = $g{db_fields_list}{$view}[$i];
				$template_args{FIELDNAME}=$field_name;
				my $field_type = $g{db_fields}{$view}{$field_name}{type};
				$template_args{FIELDTYPE}=$field_type;
				$template_args{DATA}=GUI_DB2HTML($d, $field_type);
				print Template(\%template_args);
				delete $template_args{DATA};
			}
			$i++;
		}
		delete $template_args{FIELDTYPE};

		# edit button
		if($can_edit) {
			my $edit_url;
			if(defined $id and $id ne '') {
				$edit_url = MakeURL($myurl, {
					action=>'edit',
					id=>$id,
					refresh=>$next_refresh,
				}); 
			}
			else {
				# not a real entry (virtual row, outer join): fill in fields
				my %fields_hash;
				@fields_hash{@fields_list} = (@$data);
				# in the _list, normally the hid of the referenced
				# record is shown...
				# it is then called ref_hid instead of table_ref
				foreach(@fields_list) {
					/^(.+)_hid$/ or next;
					my $ref = $1;
					my $f = "${table}_$ref";
					$fields_hash{$f}=$fields_hash{$_};
					delete $fields_hash{$_};
				}
				my $fields_str = GUI_Hash2Str(\%fields_hash);

				$edit_url = MakeURL($myurl, {
						action=>'reedit',
						reedit_action=>'add',
						reedit_data=>$fields_str,
						refresh => $next_refresh,
					});
			}
			$template_args{ELEMENT}='td_edit';
			$template_args{EDIT_URL}=$edit_url;
			print Template(\%template_args);
			delete $template_args{EDIT_URL};
		}

		# delete button
		if($can_delete) {
			my $delete_url;
			if(defined $id) {
				$delete_url =  MakeURL($myurl, {
					action=>'delete',
					id=>$id,
					refresh=>$next_refresh,
					});
			}
			$template_args{ELEMENT}='td_delete';
			$template_args{DELETE_URL}=$delete_url;
			print Template(\%template_args);
			delete $template_args{DELETE_URL};
		}

		$template_args{ELEMENT}='xtr';
		print Template(\%template_args);

		delete $template_args{ID};
		if($fetched%2) { delete $template_args{EVENROW}; }
		else           { delete $template_args{ODDROW}; }
	}

	$template_args{ELEMENT}='xtable';
	print Template(\%template_args);

	if(defined $error) {
		GUI_DB_Error($error,$myurl);
	}

	# buttons
	my $nextoffset = $fetched == $fetchamount+1 ? $offset+$fetchamount : $offset;
	my $prevoffset = $offset-$fetchamount; if($prevoffset<=0) { $prevoffset=''; }
	my $add_url  = $can_add ? MakeURL($myurl, {
			action => 'add',
			refresh => $next_refresh,
		}) : undef;
	my $prev_url = $offset != 0 ? MakeURL($myurl, { offset => $prevoffset }) : undef;
	my $next_url = $fetched == $fetchamount+1 ? MakeURL($myurl, { offset => $nextoffset }) : undef;

	$template_args{ELEMENT}='buttons';
	$template_args{ADD_URL}=$add_url;
	$template_args{PREV_URL}=$prev_url;
	$template_args{NEXT_URL}=$next_url;
	print Template(\%template_args);

	# footer
	GUI_Footer(\%template_args);
}

sub GUI_ListRep($$$)
{
	my $q = shift;
	my $user = shift;
	my $dbh = shift;
	my $myurl = MyURL($q);
	my $view = $q->url_param('table');
	my $orderby = $q->url_param('orderby') || '';
	my $descending = $q->url_param('descending') || '';
	
	my %template_args = (
		USER => $user,
		PAGE => 'listrep',
		TITLE => $g{db_tables}{$view}{desc},
		URL => $myurl,
		TABLE => $view,
	);
	
	if(not defined $g{db_fields_list}{$view}) {
		GUI_InitTemplateArgs($q, \%template_args);
		GUI_Header(\%template_args);
		print "<P>Can't find table $view\n";
		GUI_Footer(\%template_args);
		return;
	}
	my @fields_list = @{$g{db_fields_list}{$view}};
	my $fields = $g{db_fields}{$view};

	# header
	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header(\%template_args);

	# filterfirst
	my ($filterfirst_field, $filterfirst_value) =  GUI_FilterFirst($dbh, $q, $view, \%template_args);

	# search
	my ($search_field, $search_value) = GUI_Search($q, $view, \%template_args);

	# orderby
	if($orderby eq '') {
		if(not defined $g{db_tables}{$view}{meta_sort}) {
			$orderby = $fields_list[0];
		}
	}
	$template_args{ORDERBY}=$orderby;

	# header / column names
	$template_args{ELEMENT}='table';
	print Template(\%template_args);
	$template_args{ELEMENT}='tr';
	$template_args{HEADER}=1;
	print Template(\%template_args);
	my $f;
	foreach $f (@fields_list) {
		my $sort_url;
		if($orderby eq $f) {
			if($descending) {
				$sort_url = MakeURL($myurl, { descending=>'' });
			}
			else {
				$sort_url = MakeURL($myurl, { descending=>1 });
			}
		}
		else {
			$sort_url = MakeURL($myurl, { orderby=>"$f", descending=>'' });
		}
		$template_args{ELEMENT}='th';
		$template_args{DATA}=$fields->{$f}{desc};
		$template_args{FIELD}=$f;
		$template_args{SORT_URL}=$sort_url;
		print Template(\%template_args);
		delete $template_args{SORT_URL};
		delete $template_args{DATA};
	}
	delete $template_args{HEADER};

	# data
	my $offset = $q->url_param('offset') || 0;
	my $fetch_state=0;
	my $data;
	my $fetched = 0;
	my $fetchamount = $q->url_param('listrep_rows') || $q->url_param('list_rows') || $g{conf}{list_rows};
	my $error=undef;
	while(defined ($data = DB_FetchList(\$fetch_state,$dbh,$view,\$error,
		-descending => $descending,
		-orderby => $orderby,
		-limit => $fetchamount+1,
		-offset => $offset,
		-search_field => $search_field,
		-search_value => $search_value,
		-filter_field => $filterfirst_field,
		-filter_value => $filterfirst_value)))
	{
		$fetched++;
		if($fetched>$fetchamount) { next; }

		if($fetched%2) { $template_args{EVENROW}=1; }
		else           { $template_args{ODDROW}=1; }

		my @data = @{$data};
		$template_args{ELEMENT}='tr';
		print Template(\%template_args);

		my $i=0;
		$template_args{ELEMENT}='td';
		my $d;
		foreach $d (@data) {
			my $field_name = $g{db_fields_list}{$view}[$i];
			$template_args{FIELDNAME}=$field_name;
			my $field_type = $g{db_fields}{$view}{$field_name}{type};
			$template_args{FIELDTYPE}=$field_type;
			$template_args{DATA}=GUI_DB2HTML($d, $field_type);
			print Template(\%template_args);
			delete $template_args{DATA};
			$i++;
		}
		delete $template_args{FIELDTYPE};

		$template_args{ELEMENT}='xtr';
		print Template(\%template_args);

		if($fetched%2) { delete $template_args{EVENROW}; }
		else           { delete $template_args{ODDROW}; }
	}

	$template_args{ELEMENT}='xtable';
	print Template(\%template_args);

	if(defined $error) {
		GUI_DB_Error($error,$myurl);
	}

	# buttons
	my $nextoffset = $fetched == $fetchamount+1 ? $offset+$fetchamount : $offset;
	my $prevoffset = $offset-$fetchamount; if($prevoffset<=0) { $prevoffset=''; }
	my $prev_url = $offset != 0 ? MakeURL($myurl, { offset => $prevoffset }) : undef;
	my $next_url = $fetched == $fetchamount+1 ? MakeURL($myurl, { offset => $nextoffset }) : undef;

	$template_args{ELEMENT}='buttons';
	$template_args{PREV_URL}=$prev_url;
	$template_args{NEXT_URL}=$next_url;
	print Template(\%template_args);

	# footer
	GUI_Footer(\%template_args);
}

sub GUI_URL_Encode($)
{
	my @encode_chars = ('&', '+', '>', '<', ' ', '%', '/', '?', ';', "\n", "\r", ':', ',');
	my $str = shift;
	my $enc = '';
	my $c;
	foreach $c (split //, $str) {
		if(grep { $c eq $_ } @encode_chars) {
			$enc .= '%'.sprintf('%2X',ord($c));
		}
		else {
			$enc .= $c;
		}
	}
	return $enc;
}

sub GUI_URL_Decode($)
{
	$_ = shift;
	s/%(\d\d)/chr(hex($1))/ge;
	return $_;
}

sub GUI_Hash2Str($)
{
	my $record = shift;
	my @data = ();

	foreach(keys %$record) {
		my $d = GUI_URL_Encode($record->{$_});
		push @data, "$_:$d";
	}
	return join(',',@data);
}

sub GUI_Str2Hash($$)
{
	my $str = shift;
	my $hash = shift;

	foreach(split(/,/, $str)) {
		if(/^(.*?):(.*)$/) {
			$hash->{$1} = GUI_URL_Decode($2);
		}
	}
}

sub GUI_PostEdit($$$)
{
	my $q = shift;
	my $user = shift;
	my $dbh = shift;

	my $action = $q->param('post_action');
	if(not defined $action) { return; }

	if(defined $q->param('button_cancel')) { return; }

	my $table = $q->url_param('table');

	## delete
	if($action eq 'delete') {
		if(!DB_DeleteRecord($dbh,$table,$q->param('id'))) {
			my %template_args = (
				PAGE => 'dberror',
				USER => $user,
				TITLE => 'Database Error'
			);
			GUI_InitTemplateArgs($q, \%template_args);
			GUI_Header(\%template_args);

			GUI_DB_Error($dbh->errstr, MyURL($q));

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
		my $err;
		if(!DB_AddRecord($dbh,$table,\%record,\$err)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($q, $user, $err, $q->param('form_url'), $data, $action);
		}
	}
	elsif($action eq 'edit') {
		$record{id} = $q->param('id');
		my $err;
		if(!DB_UpdateRecord($dbh,$table,\%record,\$err)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($q, $user, $err, $q->param('form_url'), $data, $action);
		}
	}
}

sub GUI_Edit($$$)
{
	my $q = shift;
	my $user = shift;
	my $dbh = shift;
	my $action = $q->url_param('action');
	my $table = $q->url_param('table');
	my $id = $q->url_param('id');

	my $reedit = undef;
	if($action eq 'reedit') {
		$reedit = 1;
		$action = $q->url_param('reedit_action');
	}

	if(not exists $g{db_tables}{$table}) {
		print "<p>Error: no such table ($table).\n";
		exit;
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
	
	my $form_url = MakeURL(MyURL($q), { refresh => GUI_NextRefresh($q) });
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
	GUI_Header(\%template_args);

	# FORM
	GUI_Form($next_url);
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
		my $ff_field = $g{db_tables}{$table}{filterfirst};
		my $ff_value = $q->url_param('filterfirst') || $q->url_param('combo_filterfirst') || '';
		if(defined $ff_value and defined $ff_field) {
			$values{$ff_field} = DB_ID2HID($dbh, $table, $g{db_tables}{$table}{filterfirst}, $ff_value);
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
		my $inputelem = GUI_EditField($dbh,$table,$field,$value);
		if(not defined $inputelem) {
			GUI_xForm($form_url, $next_url);
			GUI_DB_Error($dbh->errstr, $form_url);
			return;
		}

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

	GUI_xForm($form_url, $next_url);
	GUI_Footer(\%template_args);
}

sub GUI_MakeCombo($$$$$)
{
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $name = shift;
	my $value = shift;

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
	my $dbh = shift;
	my $table = shift;
	my $field = shift;
	my $value = shift;

	my $meta = $g{db_fields}{$table}{$field};
	my $type = $meta->{type};
	my $widget = $meta->{widget} || '';

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
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=10 VALUE=".$value.">";
	}
	if($type eq 'time') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=10 VALUE=".$value.">";
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
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=10 VALUE=\"$value\">";
	}
	if($type eq 'bpchar') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=30 VALUE=\"$value\">";
	}
	if($type eq 'text') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=40 VALUE=\"$value\">";
	}
	if($type eq 'name') {
		return "<INPUT TYPE=\"text\" NAME=\"field_$field\" SIZE=20 VALUE=\"$value\">";
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
	my $q = shift;
	my $user = shift;
	my $dbh = shift;
	my $table = $q->url_param('table');
	my $id = $q->url_param('id');
	my $next_url = MakeURL(MyURL($q), { action=>'list', id=>'' });

	my %template_args = (
		PAGE => 'delete',
		USER => $user,
		TITLE => "Delete Record",
		TABLE => $table,
		ID => $id,
		NEXT_URL => $next_url,
	);

	GUI_InitTemplateArgs($q, \%template_args);
	GUI_Header(\%template_args);
	GUI_Form($next_url);

	$template_args{ELEMENT}='delete';
	print Template(\%template_args);

	print "<INPUT TYPE=\"hidden\" NAME=\"post_action\" VALUE=\"delete\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"id\" VALUE=\"$id\">\n";
	GUI_xForm($next_url, $next_url);
	GUI_Footer(\%template_args);
}

1;

# vi: tw=0

# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2002 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::GUI;

use strict;
use Data::Dumper;

use Gedafe::Global qw(%g);
use Gedafe::DB qw(
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
	DB_RawField
	DB_DumpTable
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
	GUI_Export
	GUI_DumpTable
);

# setup for GUI_Export
my ($csv, @exp_fmt_choices, %exp_fmt_choices);
BEGIN {
    eval {
       # load modules necessary for formatting exported data:
       # if they don't load (aren't installed), no biggie- will fallback
       require Text::CSV_XS;
       $csv = Text::CSV_XS->new({binary => 1});
       push(@exp_fmt_choices, 'csv');
       $exp_fmt_choices{'csv'} = "Comma-separated (CSV)";
    };
    # add default (built-in) export format: tab-separated
    push(@exp_fmt_choices, 'tsv');
    $exp_fmt_choices{'tsv'} = "Tab-separated (TSV)";
}

sub GUI_HTMLMarkup($)
{
	my $str = shift;

	# e-mail addresses
	my $emaddrchars = '\w.:/~-';
	$str =~ s,([^\@$emaddrchars]|\A)([$emaddrchars]+\@(?:[\w-]+\.)+[\w-]+)([^\@$emaddrchars]|\Z),$1<A HREF="mailto:$2">$2</A>$3,gi;

	my $urlchars = '\w.:/?~%&=\@\#-';

	# http addresses with explicit "http://" or "https://"
	$str =~ s,([^$urlchars]|\A)(https?://[$urlchars]+)([^$urlchars]|\Z),$1<A HREF="$2" TARGET="refwindow">$2</A>$3,gi;

	# http addresses beginning with "www."
	$str =~ s,([^$urlchars]|\A)(www\.[\w.:/?~%&=\#-]+)([^$urlchars]|\Z),$1<A HREF="http://$2" TARGET="refwindow">$2</A>$3,gi;

	# http addresses ending in a common top-level domain
	$str =~ s,([^$urlchars]|\A)([\w.-]+\.)(com|org|net|edu|gov|mil|au|ca|ch|de|uk|us)(:\d+)?(/[\w./?~%&=\#-]*)?([^$urlchars]|\Z),$1<A HREF="http://$2$3$4$5" TARGET="refwindow">$2$3$4$5</A>$6,gi;

	return $str;
}

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
		GUI_InitTemplateArgs($s, \%template_args);
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

	GUI_InitTemplateArgs($s, \%template_args);
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

sub GUI_FilterFirst($$$$)
{
	my $s = shift;
	my $q = $s->{cgi};
	my $dbh = shift;
	my $view = shift;
	my $template_args = shift;
	my $myurl = MyURL($q);
	my $filterfirst_field = $g{db_tables}{$view}{meta}{filterfirst};
	my $filterfirst_value = $q->url_param('filterfirst') || $q->url_param('combo_filterfirst') || '';

	# filterfirst
	if(defined $filterfirst_field)
	{
		if(not defined $g{db_fields}{$view}{$filterfirst_field}{ref_combo}) {
			die "combo not found for $filterfirst_field";
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
			$template_args->{FILTERFIRST_ACTION}=$s->{url};
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
	my $s = shift;
	my $q = $s->{cgi};
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
	$template_args->{SEARCH_ACTION} = $s->{url};
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

sub GUI_EditLink($$$$)
{
	my ($s, $template_args, $list, $row) = @_;
	my $edit_url;
	$edit_url = MakeURL($s->{url}, {
		action=>'edit',
		id=>$row->[0],
		refresh=>NextRefresh,
	});
	$template_args->{ELEMENT}='td_edit';
	$template_args->{EDIT_URL}=$edit_url;
	print Template($template_args);
	delete $template_args->{EDIT_URL};
}

sub GUI_DeleteLink($$$$)
{
	my ($s, $template_args, $list, $row) = @_;
	my $delete_url;
	$delete_url =  MakeURL($s->{url}, {
		action=>'delete',
		id=>$row->[0],
		refresh=>NextRefresh,
	});
	$template_args->{ELEMENT}='td_delete';
	$template_args->{DELETE_URL}=$delete_url;
	print Template($template_args);
	delete $template_args->{DELETE_URL};
}

sub GUI_ListTable($$$)
{
	my ($s, $list, $page) = @_;

	# user can edit only if they have sql UPDATE privilege, and
	# this table is a real table, not a report (view)
	my $can_edit = ($list->{acl} =~ /w/ and
			!$g{db_tables}{$list->{spec}->{table}}{report});
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

	# total number of records in result set
	$template_args{NUM_RECORDS} = $list->{totalrecords}
	  if $g{conf}{show_row_count};

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
	


	my @typelist = map { $list->{type}->{$_} } @{$list->{fields}};

	# data
	$list->{displayed_recs} = 0;
	for my $row (@{$list->{data}}) {
		$list->{displayed_recs}++;
		if($list->{displayed_recs}%2) { $template_args{EVENROW}=1; }
		else                          { $template_args{ODDROW}=1; }

		$template_args{ELEMENT}='tr';
		print Template(\%template_args);
		my $column_number = 0;
		for my $d (@{$row->[1]}) {
			my $type = $typelist[$column_number];
			my $name = $list->{fields}->[$column_number];
			if($type eq 'bytea' && $d ne '&nbsp;'){
			    my $bloburl = MakeURL($s->{url}, {
						action => 'dumpblob',
						id => $row->[0],
						field => $name,
							     });
			    $d = qq{<A HREF="$bloburl" TARGET="_blank">$d</A>};
			}
			$template_args{ELEMENT}='td';
			$template_args{DATA}=$d;
			$template_args{MARKUP}=GUI_HTMLMarkup($d) if $d and $g{db_fields}{$list->{spec}->{table}}{$name}{markup};
			print Template(\%template_args);
			delete $template_args{DATA};
			delete $template_args{MARKUP};
		        $column_number++;
		}

		$template_args{ID} = $row->[0];
		GUI_EditLink($s, \%template_args, $list, $row) if $can_edit;
		GUI_DeleteLink($s, \%template_args, $list, $row) if $can_delete;
		delete $template_args{ID};

		$template_args{ELEMENT}='xtr';
		print Template(\%template_args);

		if($list->{displayed_recs}%2) {delete $template_args{EVENROW};}
		else                          {delete $template_args{ODDROW};}
	}

	# </TABLE>
	$template_args{ELEMENT}='xtable';
	print Template(\%template_args);
	$s->{in_table}=0;
}

sub GUI_ListButtons($$$$)
{
	my ($s, $list, $page, $position) = @_;

	my %template_args = (
		USER => $s->{user},
		PAGE => $page,
		URL => $s->{url},
		TABLE => $list->{spec}{view},
		TITLE => "$g{db_tables}{$list->{spec}{table}}{desc}",
		TOP => $position eq 'top',
		BOTTOM => $position eq 'bottom',
	);

	my $next_refresh = NextRefresh;

	my $nextoffset = $list->{spec}{offset}+$list->{spec}{limit};
	my $prevoffset = $list->{spec}{offset}-$list->{spec}{limit};
	$prevoffset > 0 or $prevoffset = '';

	my $can_add = ($list->{acl} =~ /a/);
	my $add_url  = $can_add ? MakeURL($s->{url}, {
			action => 'add',
			refresh => $next_refresh,
		}) : undef;

	my $prev_url = $list->{spec}{offset} != 0 ? MakeURL($s->{url},
		{ offset => $prevoffset }) : undef;
	my $next_url = $list->{end} ? undef :
		MakeURL($s->{url}, { offset => $nextoffset });

	$template_args{ELEMENT}='buttons';
	$template_args{ADD_URL}=$add_url;
	$template_args{PREV_URL}=$prev_url;
	$template_args{NEXT_URL}=$next_url;

	# calculate correct offset for last page of results
	if ($g{conf}{show_row_count}) {
		my $totalrecs = $template_args{NUM_RECORDS} = $list->{totalrecords};
		my $lastoffset =
		  ($totalrecs % $list->{spec}{limit} == 0
		   ? $totalrecs - $list->{spec}{limit}
		   : $totalrecs - ($totalrecs % $list->{spec}{limit}));
		my $first_url =
		   ($prev_url && $prevoffset ne ''
		    ? MakeURL($s->{url}, { offset => '' }) : undef);
		my $last_url =
		  ($next_url && $nextoffset != $lastoffset
		   ? MakeURL($s->{url}, { offset => $lastoffset }) : undef);
		$template_args{START_RECNUM}=
		  ($list->{spec}{offset}+1 > $totalrecs
		   ? $totalrecs
		   : $list->{spec}{offset}+1);
		$template_args{END_RECNUM}=
		  ($list->{spec}{offset}+$#{$list->{data}}+1 > $totalrecs
		   ? $totalrecs
		   : $list->{spec}{offset}+$#{$list->{data}}+1);
		$template_args{FIRST_URL}=$first_url;
		$template_args{LAST_URL}=$last_url;
	}

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
		EXPORT_AS_CHOICE => $#exp_fmt_choices > 0,
		EXPORT_CHOICES => "<SELECT NAME=\"export_format\">\n".join("\n", map { "<OPTION VALUE=\"$_\">$exp_fmt_choices{$_}</OPTION>" } @exp_fmt_choices).'</SELECT>',
		EXPORT_URL => MakeURL(MyURL($q), { action => 'export' }),
	);

	# header
	GUI_InitTemplateArgs($s, \%template_args);
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

	# filterfirst
	($spec{filter_field}, $spec{filter_value}) =
	  GUI_FilterFirst($s, $dbh, $table, \%template_args);

	# search
	($spec{search_field}, $spec{search_value}) =
	  GUI_Search($s, $spec{view}, \%template_args);

	# fetch list
	my $list = DB_FetchList($s, \%spec);

	# get total number of records for this search set
	$list->{totalrecords} = DB_GetNumRecords($s, \%spec)
	  if $g{conf}{show_row_count};
	
	my $list_buttons = $g{conf}{list_buttons};
	if(!$list_buttons){
	  $list_buttons = 'both';
	}

	# top buttons
	if($list_buttons eq 'top' || $list_buttons eq 'both'){
	  GUI_ListButtons($s, $list, $g{db_tables}{$table}{report} ? 'listrep' : 'list', 'top');
	}

	# display table
	GUI_ListTable($s, $list, 'list');

	# bottom buttons
	if($list_buttons eq 'bottom' || $list_buttons eq 'both'){

	  GUI_ListButtons($s, $list, $g{db_tables}{$table}{report} ? 'listrep' : 'list', 'bottom');
	}
	delete $list->{displayed_recs};
	delete $list->{totalrecords} if $g{conf}{show_row_count};

	# footer
	GUI_Footer(\%template_args);
}

sub GUI_ExportData($$)
{
	my ($s, $list) = @_;
	my $q = $s->{cgi};

	# decide what export format to use: 'csv' only if Text::CSV_XS loaded
	my $exp_fmt = ref $csv && $q->param('export_format') eq 'csv' ? 'csv' : 'tsv';

	# print HTTP Content-type header
	if ($exp_fmt eq 'csv') {
	    print $q->header(-type=>'text/csv',
			     -attachment=>$list->{spec}{table}.'.csv',
			     -expires=>'-1d');
	} else {
	    print $q->header(-type=>'text/tab-separated-values',
			     -attachment=>$list->{spec}{table}.'.tsv',
			     -expires=>'-1d');
	}

	# fields
	my $fields = $g{db_fields}{$list->{spec}{view}};
	if ($exp_fmt eq 'csv') {
	    my $status = $csv->combine(map {$fields->{$_}{desc}} @{$list->{fields}});
	    print $csv->string(). "\n";
	} else {
	    print join("\t", map {$fields->{$_}{desc}} @{$list->{fields}})."\n";
	}

	# data
	for my $row (@{$list->{data}}) {
		# if correct module is loaded and user selected 'CSV'
		if ($exp_fmt eq 'csv') {
		    my $status = $csv->combine(@{$row->[1]});
		    print $csv->string() . "\n";
		} else {
		    print join("\t", map {
			my $str = defined $_ ? $_ : '';
			$str=~s/\t/        /g;
			$str=~s/\n/\r/g;
			$str;
		    } @{$row->[1]})."\n";
		}
	}
}

sub GUI_Export($$$)
{
	my ($s, $user, $dbh) = @_;
	my $q = $s->{cgi};
	my $table = $q->url_param('table');

	my %template_args = (
		USER => $user,
		PAGE => 'export',
		URL => $s->{url},
		TABLE => $table,
		TITLE => "$g{db_tables}{$table}{desc}",
	);

	# build list-spec
	my %spec = (
		table => $table,
		view => defined $g{db_tables}{"${table}_list"} ?
			"${table}_list" : $table,
		offset => $q->url_param('offset') || 0,
		limit => $q->url_param('list_rows') || $g{conf}{list_rows},
		orderby => $q->url_param('orderby') || '',
		descending => $q->url_param('descending') || 0,
		export => 1,
	);

	# get search params
	$spec{search_field} = $q->url_param('search_field') || '';
	$spec{search_value} = $q->url_param('search_value') || '';
	$spec{search_field} =~ s/^\s*//; $spec{search_field} =~ s/\s*$//;
	$spec{search_value} =~ s/^\s*//; $spec{search_value} =~ s/\s*$//;

	# fetch list
	my $list = DB_FetchList($s, \%spec);

	GUI_ExportData($s, $list);
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

sub GUI_Str2Hash($$)
{
	my ($str, $hash) = @_;
	for my $s (split(/,/, $str)) {
		if($s =~ /^(.*?):(.*)$/) {
			$hash->{$1} = GUI_URL_Decode($2);
		}
	}
}

sub GUI_WidgetRead($$)
{
	my ($s, $f) = @_;
	my $q = $s->{cgi};
	my $dbh = $s->{dbh};
	my $field = $f->{field};

	my ($w, $warg) = DB_ParseWidget($f->{widget});

	my $value = $q->param("field_$field");
	
	if($w eq 'file'){
	    my $file = $value;
	    if($file){
		my $filename = scalar $file;
		$filename =~ /([\w\d\.]+$)/;
		$filename = $1;
		my $mimetype = $q->uploadInfo($file)->{'Content-Type'};
		my $blob=$filename.' '.$mimetype.'#';
		my $buffer; 
		while(read($file,$buffer,1024)){
		    $blob .=$buffer;
	        }
		#note that value is set to a reference to the large blob
		$value=\$blob;
	    }else{
		#when we are here the file field has not been set
		
		if($q->param("post_action") eq 'edit'){
		    #no new file therefor preserve old one.
		    my $table=$q->url_param('table');
		    my $id=$q->param('id');
		    my $oldblob = DB_RawField($dbh,$table,$field,$id);
		    $value = \$oldblob;
		}else{
		    #no new file and we are inserting. send undef
		    $value = undef;
		}
	    }
	}
	if($w eq 'hid' or $w eq 'hidcombo' or $w eq 'hidisearch') {
		if(defined $value and $value !~ /^\s*$/) {
			$value=DB_HID2ID($dbh,$warg->{'ref'},$value);
		}
	}
	# if it's a combo and no value was specified in the text field...
	if($w eq 'idcombo' or $w eq 'hidcombo') {
		if(not defined $value or $value =~ /^\s*$/) {
			$value = $q->param("combo_$field");
			if($w eq 'hidcombo' and $g{conf}{gedafe_compat} eq '1.0')
			{
				# hidcombos in 1.0 had to put the HID as key...
				$value = DB_HID2ID($dbh,$warg->{'ref'},$value);
			}
		}
	}

	return $value;
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
			GUI_InitTemplateArgs($s, \%template_args);
			GUI_Header($s, \%template_args);
			$template_args{ELEMENT}='db_error';
			$template_args{ERROR}=$g{db_error};
			$template_args{NEXT_URL}=MyURL($q);
			print Template(\%template_args);
			GUI_Footer(\%template_args);
			exit;
		}
	}


	## add or edit:
	if($action eq 'add' || $action eq 'edit'){
	    my %record;
	    for my $field (@{$g{db_fields_list}{$table}}) {
		my $f = $g{db_fields}{$table}{$field};
		my $value = GUI_WidgetRead($s, $f);
		if(defined $value) {
			$record{$field} = $value;
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

	GUI_InitTemplateArgs($s, \%template_args);
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
		for my $field (@fields_list) {
			if($g{db_fields}{$table}{$field}{copy}) {
				my $f = $g{db_fields}{$table}{$field};
				my $v = GUI_WidgetRead($s, $f);
				$values{$field} = $v if defined $v;
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
		# get default from DB
		if(not defined $value or $value eq '') {
			$value = DB_GetDefault($dbh,$table,$field);
		}

		my $inputelem = GUI_WidgetWrite($s, $dbh, "field_$field", $fields->{$field}{widget},$value,
					$table, $field);

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
	return $str;
}

sub GUI_MakeISearch($$$$$$)
{
	my $table = shift;
	my $field = shift;
	my $ticket = shift;
	my $myurl = shift;
	my $value = shift;
	my $hidisearch = shift;
	
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;


	my $meta = $g{db_fields}{$table}{$field};


	my $target = $meta->{reference};

	my $targeturl = MakeURL($myurl,{action=>'dumptable',table=>$target,ticket=>$ticket});

	my $html;
	$html .= "<input type=\"button\" onclick=\"";
	$html .= "document.editform.field_$field.value=document.isearch_$field.getID('$value')";
	$html .= ";\" value=\"I-Search\">&nbsp;";
	$html .= "<applet id=\"isearch_$field\" name=\"isearch_$field\"";
	$html .= ' code="ISearch.class" width="70" height="20" archive="java/isearch.jar">'."\n";
	$html .= GUI_AppletParam("url",$targeturl);
	if($hidisearch){
	  $html .= GUI_AppletParam("hid","true");
	}
	$html .= "</applet>\n";
	
	return $html
}

sub GUI_AppletParam($$){
  my $name=shift;
  my $value=shift;
  return "<param name=\"$name\" value=\"$value\">\n";
}



sub GUI_WidgetWrite($$$$$$$)
{
	my $s = shift;
	my $dbh = shift;
	my $input_name = shift;
	my $widget = shift;
	my $value = shift;
	my $table = shift; # this should not be needed, all needed info should be in widget
	my $field = shift; # this should not be needed, all needed info should be in widget 

	my $q = $s->{cgi};
	my $myurl = MyURL($q);

	if(not defined $value) { $value = ''; }

	my ($w, $warg) = DB_ParseWidget($widget);

	my $escval = $value;
	$escval =~ s/\"/&quot;/g;

	if($w eq 'readonly') {
		return $value || '&nbsp;';
	}
	if($w eq 'text') {
		my $size = defined $warg->{size} ? $warg->{size} : '20';
		return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"$size\" VALUE=\"".$escval."\">";
	}
	if($w eq 'area') {
		my $rows = defined $warg->{rows} ? $warg->{rows} : '4';
		my $cols = defined $warg->{cols} ? $warg->{cols} : '60';
		return "<TEXTAREA NAME=\"$input_name\" ROWS=\"$rows\" COLS=\"$cols\" WRAP=\"virtual\">".$value."</TEXTAREA>";
	}
        if($w eq 'varchar') {
		my $size = defined $warg->{size} ? $warg->{size} : '20';
		my $maxlength = defined $warg->{maxlength} ? $warg->{maxlength} : '100';
                return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"$size\" MAXLENGTH=\"$maxlength\" VALUE=\"$escval\">";
        }
	if($w eq 'checkbox') {
		return "<INPUT TYPE=\"checkbox\" NAME=\"$input_name\" VALUE=\"1\"".($value ? 'CHECKED' : '').">";
	}
	if($w eq 'hid') {
		return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"10\" VALUE=\"".$escval."\">";
	}
	if($w eq 'isearch' or $w eq 'hidisearch') {
		my $out;
		my $hidisearch;
		$hidisearch = 0;
		if($w eq 'hidisearch') {
		  # replace value with HID if 'hidcombo'
		  $value = DB_ID2HID($dbh,$warg->{'ref'},$value);
		  $hidisearch=1;
		}
		
		my $combo = GUI_MakeISearch($table,$field,$s->{ticket_value},$myurl,$value,$hidisearch);

		$out.="<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=10";
		$out .= " VALUE=\"$value\"";
		$out .= ">\n$combo";
		return $out;
	}


	if($w eq 'idcombo' or $w eq 'hidcombo') {
		my $out;
		my $combo;
		
		if($g{conf}{gedafe_compat} eq '1.0') {
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value) if $w eq 'hidcombo';
			$combo = GUI_MakeCombo($dbh, $table, $field, "combo_$field", $value);
		}
		else {
			$combo = GUI_MakeCombo($dbh, $table, $field, "combo_$field", $value);
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value) if $w eq 'hidcombo';
		}
		$out.="<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=10";
		if($combo !~ /SELECTED/ and defined $value) {
			$out .= " VALUE=\"$value\"";
		}
		$out .= ">\n$combo";
		return $out;
	}
	if($w eq 'file'){
	        my $out;
		$out = "Current blob: <b>$value</b><br>Enter filename to update.<br><INPUT TYPE=\"file\" NAME=\"$input_name\">";
		return $out;
	}

	if($w eq 'date') {
	  my $y;
	  my $m;
	  my $d;

	  my %monthhash = (1, "Januari", 2, "Februari", 3, "March", 4, "April", 5, "May", 6, "June", 7, "July", 8, "August", 9, "September", 10, "October", 11, "November", 12, "December");

	  my $yearselect;
	  my $dayselect;
	  my $monthselect;

	  if($escval=~/(\d+)-(\d+)-(\d+)/)
          {
	    $y = $1;
	    $m = $2;
	    $d = $3;	  
	  }

	  for (($warg->{from})..($warg->{to}))
	  {
	    if ($_ == $y)
	    {
	      $yearselect .= "<option selected> $_ </option>\n";
	    }
	    else
	    {
	      $yearselect .= "<option> $_ </option>\n";
	    }
	  }

	  for(1..12)
	  {
	    if ($_ == $m)
	    {
	      $monthselect .= "<option selected> $monthhash{$_} </option>\n";
	    }
	    else
	    {
	      $monthselect .= "<option> $monthhash{$_} </option>\n";
	    }
	  }

	  for (1..31)
	  {
	    if ($_ == $d)
	    {
	      $dayselect .= "<option selected> $_ </option>\n";
	    }
	    else
	    {
	      $dayselect .= "<option> $_ </option>\n";
	    }
	  }

	  my $out =
	        "<SCRIPT LANGUAGE=\"JavaScript\">
                <!--
                function validate()
		{
		  var leap = 0;
		  var err = 0;
		  var year = document.editform.${input_name}_1.selectedIndex + ".($warg->{from}).";
		  var month = document.editform.${input_name}_2.selectedIndex + 1;
		  var day = document.editform.${input_name}_3.selectedIndex + 1;

                  if(month < 10)
                  {
                    var date = year + \"-0\" + month + \"-\" + day;
	          }
                  else
                  {
                    var date = year + \"-\" + month + \"-\" + day;
                  }

		  if ((year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))) 
		  {
		    leap = 1;
		  }

		  if ((month == 2) && (leap == 1) && (day > 29)) 
		  {
                    document.editform.${input_name}_3.selectedIndex = 28;
		  }

		  if ((month == 2) && (leap != 1) && (day > 28)) 
		  {
                    document.editform.${input_name}_3.selectedIndex = 27;
		  }

		  if ((day > 30) && ((month == 4) || (month == 6) || (month == 9) || (month == 11)))
		  {
                    document.editform.${input_name}_3.selectedIndex = 29;
		  }

		  if (err == 0)
		  {
                    document.editform.${input_name}.value = date;
                  }
		}
	    //  -->
	    </script>

      <select NAME=\"${input_name}_1\" onChange=\"validate()\">
	".$yearselect."
      </select>

      <select NAME=\"${input_name}_2\" onChange=\"validate()\">
        ".$monthselect."
      </select>

      <select NAME=\"${input_name}_3\" onChange=\"validate()\">
        ".$dayselect."
      </select>

      <input TYPE=\"hidden\" NAME=\"$input_name\" VALUE=\"".$escval."\">";

	return $out;
	}


	return "Unknown widget: $w";
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

	GUI_InitTemplateArgs($s, \%template_args);
	GUI_Header($s, \%template_args);
	UniqueFormStart($s, $next_url);

	$template_args{ELEMENT}='delete';
	print Template(\%template_args);

	print "<INPUT TYPE=\"hidden\" NAME=\"post_action\" VALUE=\"delete\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"id\" VALUE=\"$id\">\n";
	UniqueFormEnd($s, $next_url, $next_url);
	GUI_Footer(\%template_args);
}

sub GUI_DumpTable($$$){
	my $s = shift;
	my $q = $s->{cgi};
	my $user = shift;
	my $dbh = shift;
	my $myurl = MyURL($q);
	my $table = $q->url_param('table');
	
	my %atribs;
	foreach($q->param) {
	  if(/^field_(.*)/) {
	    $atribs{$1} = $q->param($_);
	  }
	}
	my $data;
	my $first = 1;

	my @fields_list = @{$g{db_fields_list}{$table}};
	for (@fields_list){
	  if(not $first){
	    $data.="\t";
	  }
	  $first = 0;
	  $data.=$_;
	}
	$data.="\n";
	        

	$data .= DB_DumpTable($dbh,$table,\%atribs);
	print $data;
}


1;

# vi: tw=0

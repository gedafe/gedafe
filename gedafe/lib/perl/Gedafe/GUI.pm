# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::GUI;

use strict;

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
	DB_DumpJSITable
	DB_FetchReferencedId
);

use Gedafe::Util qw(
	ConnectToTicketsDaemon
	MakeURL
	MyURL
	Template
	DropUnique
	UniqueFormStart
	FormStart
	UniqueFormEnd
	FormEnd
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
	GUI_DumpJSIsearch
	GUI_Pearl
	GUI_WidgetRead
);

sub GUI_AppletParam($$);
sub GUI_CheckFormID($$);
sub GUI_Delete($$$);
sub GUI_DeleteLink($$$$);
sub GUI_DumpTable($$);
sub GUI_Edit($$$);
sub GUI_EditLink($$$$);
sub GUI_Edit_Error($$$$$$);
sub GUI_Entry($$$);
sub GUI_Export($$$);
sub GUI_ExportData($$);
sub GUI_FilterFirst($$$$);
sub GUI_Footer($);
sub GUI_HTMLMarkup($);
sub GUI_Hash2Str($);
sub GUI_Header($$);
sub GUI_InitTemplateArgs($$);
sub GUI_List($$$);
sub GUI_ListButtons($$$$);
sub GUI_ListTable($$$);
sub GUI_MakeCombo($$$$);
sub GUI_MakeISearch($$$$$$);
sub GUI_PostEdit($$$);
sub GUI_Search($$$);
sub GUI_Str2Hash($$);
sub GUI_URL_Decode($);
sub GUI_URL_Encode($);
sub GUI_WidgetRead($$$);
sub GUI_WidgetWrite($$$$);
sub GUI_WidgetWrite_Date($$$);

my %numeric_types = (
	time      => 1,
	timestamp => 1,
	int2      => 1,
	int4      => 1,
	int8      => 1,
	numeric   => 1,
	float8    => 1,
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

	# Adresses beginning with explicit "data: URL"
	# e.g. data:text/plain,hello"
	$str =~ s,([^$urlchars]|\A)(data:.*)([^$urlchars]|\Z),$1<A HREF="$2" TARGET="refwindow">?</A>,gi;
	# http addresses ending in a common top-level domain
	my $tlds = 'ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|fi|fj|fk|fm|fo|fr|ga|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw|aero|biz|com|coop|info|museum|name|org|pro|gov|edu|mil|int';

	$str =~ s,([^$urlchars]|\A)([\w.-]+\.)($tlds)(:\d+)?(/[\w./?~%&=\#-]*)?([^$urlchars]|\Z),$1<A HREF="http://$2$3$4$5" TARGET="refwindow">$2$3$4$5</A>$6,gi;

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
                                copyfromid   => '',
			});
	# Define screen format as list_rows <= $g{conf}{list_rows}
	# and    print  format as list_rows >  $g{conf}{list_rows}

	my $list_rows_urlval = $q->url_param('list_rows');
	$list_rows_urlval    = 0 unless defined $list_rows_urlval;

	my $list_rows_def = $g{conf}{list_rows};
	$list_rows_def = 15 unless defined $list_rows_def;

	my $list_rows_print_flag = $list_rows_urlval>$list_rows_def;
	$list_rows_print_flag = 0 unless ($list_rows_print_flag == 1);

	print STDERR 
	"#$list_rows_urlval#, #$list_rows_def#,#$list_rows_print_flag# \n";

	if ( $list_rows_print_flag ){
		$args->{PRINT_TOGGLE_URL}=MakeURL($s->{url}, {
					  list_rows => $list_rows_def,
					  });
	} else {
		$args->{PRINT_TOGGLE_URL}=MakeURL($s->{url}, {
                                          list_rows =>'99999',
					  });
	}
	$args->{PRINT_TOGGLE_FLAG} = $list_rows_print_flag;

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
				pearl=>'',
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

	$args->{ELEMENT}='header_table';
	my $user = $args->{USER};

	my $save_table = $args->{TABLE};

	foreach my $t (@{$g{db_tables_list}}) {
		next if $g{db_tables}{$t}{hide};
		next if $g{db_tables}{$t}{report};
		if(defined $g{db_tables}{$t}{acls}{$user} and
			$g{db_tables}{$t}{acls}{$user} !~ /r/) { next; }
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$args->{TABLE_TABLE}=$t;
		$args->{TABLE_DESC}=$desc;
		$args->{TABLE_TOOLTIP}=$g{db_tables}{$t}{meta}{longcomment};
		$args->{TABLE_URL}=MakeURL($args->{REFRESH_ENTRY_URL}, {
				action => 'list',
				table  => $t,
				});
		print Template($args);
	}
	delete $args->{TABLE_DESC};
	delete $args->{TABLE_TOOLTIP};
	delete $args->{TABLE_URL};

        my $longcomment= $g{db_tables}{$save_table}{meta}{longcomment};
        $args->{TABLE_LONGCOMMENT} = $longcomment;

	$args->{TABLE} = $save_table;

	$args->{ELEMENT}='header2';
	print Template($args);

	delete $args->{ELEMENT};
	delete $args->{TABLE_LONGCOMMENT};
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

	$template_args{ELEMENT}='entrytable';
	foreach my $t (@{$g{db_tables_list}}) {
		next if $g{db_tables}{$t}{hide};
		next if $g{db_tables}{$t}{report};
		if(defined $g{db_tables}{$t}{acls}{$user} and
			$g{db_tables}{$t}{acls}{$user} !~ /r/) { next; }
		my $longcomment= $g{db_tables}{$t}{meta}{longcomment};
		my $desc = $g{db_tables}{$t}{desc};
		$desc =~ s/ /&nbsp;/g;
		$template_args{TABLE_DESC}=$desc;
		$template_args{TABLE_LONGCOMMENT}=$longcomment;
		$template_args{TABLE_URL}= MakeURL($s->{url}, {
					action => 'list',
					table  => $t,
					refresh => $refresh,
				});
		print Template(\%template_args);
	}
	delete $template_args{TABLE_DESC};
	delete $template_args{TABLE_LONGCOMMENT};
	delete $template_args{TABLE_URL};

	$template_args{ELEMENT}='reports_list_header';
	print Template(\%template_args);

	$template_args{ELEMENT}='entrytable';
	foreach my $t (@{$g{db_tables_list}}) {
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

	if(defined $g{pearls} and scalar %{$g{pearls}}) {
		$template_args{ELEMENT}='pearls_list_header';
		print Template(\%template_args);

		$template_args{ELEMENT}='entrytable';
		foreach my $t (sort {$a cmp $b} keys %{$g{pearls}}) {
			if (ref $g{pearls}{$t}) {
				@template_args{qw(TABLE_DESC TABLE_INFO)}=($g{pearls}{$t}->info);
				$template_args{TABLE_URL}= MakeURL($s->{url}, {
					action => 'configpearl',
					pearl=> $t,
					table  => undef,
					refresh => $refresh,
				});
			} else {
				$template_args{REPORT}=1;
				@template_args{qw(TABLE_DESC TABLE_INFO)}=($t,$g{pearls}{$t});
				$template_args{TABLE_URL}= MakeURL($s->{url}, {
					action => 'entry',
					pearl=> $t,
					table  => undef,
					refresh => $refresh,
				});
				$template_args{REPORT}=1;
			}
			print Template(\%template_args);
		}
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
	my $ff_field = $g{db_tables}{$view}{meta}{filterfirst};
	my $ff_value = $q->url_param('filterfirst') ||
	               $q->url_param('combo_filterfirst') || '';
	
	defined $ff_field or return undef;

	my $ff_ref = $g{db_fields}{$view}{$ff_field}{reference};
	my $ff_combo_name = "${ff_ref}_combo" unless not defined $ff_ref;

	if(!defined $ff_ref or !defined $g{db_tables}{$ff_combo_name}) {
		die "combo not found for $ff_field (reference: ${ff_ref})";
	}

	my $ff_combo = GUI_MakeCombo($dbh, $ff_combo_name, "combo_filterfirst", $ff_value);

	# ID->HID: if referenced table has a hid, assume the hid is shown in
	# this view and search that instead. In Gedafe 1.0 mode, the
	# combo-boxes always referenced the hid, so it is already done
	if($g{conf}{gedafe_compat} ne '1.0') {
		if(defined $g{db_fields}{$ff_ref}{"${ff_ref}_hid"}) {
			$ff_value = DB_ID2HID($dbh,$ff_ref,$ff_value);
		}
	}

	my $ff_hidden = '';
	foreach($q->url_param) {
		next if /^filterfirst/;
		next if /button$/;
		$ff_hidden .= "<INPUT TYPE=\"hidden\" NAME=\"$_\" VALUE=\"".$q->url_param($_)."\">\n";
	}
	$template_args->{ELEMENT}='filterfirst';
	$template_args->{FILTERFIRST_FIELD}=$ff_field;
	$template_args->{FILTERFIRST_FIELD_DESC}=$g{db_fields}{$view}{$ff_field}{desc};
	$template_args->{FILTERFIRST_COMBO}=$ff_combo;
	$template_args->{FILTERFIRST_HIDDEN}=$ff_hidden;
	$template_args->{FILTERFIRST_ACTION}=$q->url;
	print Template($template_args);
	delete $template_args->{ELEMENT};
	delete $template_args->{FILTERFIRST_FIELD};
	delete $template_args->{FILTERFIRST_FIELD_DESC};
	delete $template_args->{FILTERFIRST_COMBO};
	delete $template_args->{FILTERFIRST_HIDDEN};
	delete $template_args->{FILTERFIRST_ACTION};

	if($ff_value eq '') { $ff_value = undef; }

	return ($ff_field, $ff_value);
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
	$template_args->{SEARCH_ACTION} = $q->url;
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

sub GUI_AddFromLink($$$$)
{
        my ($s, $template_args, $list, $row) = @_;
        my $add_url;
        $add_url = MakeURL($s->{url}, {
                action=>'add',
                copyfromid=>$row->[0],
                refresh=>NextRefresh,
        });
        $template_args->{ELEMENT}='td_edit';
        $template_args->{CLONE_URL}=$add_url;
        print Template($template_args);
        delete $template_args->{CLONE_URL};
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
	my $can_add = ($list->{acl} =~ /a/);
	my $can_edit = ($list->{acl} =~ /w/ and !$list->{is_report});
	my $can_delete = $can_edit;

	my %template_args = (
		USER => $s->{user},
		PAGE => $page,
		URL => $s->{url},
		TABLE => $list->{spec}{view},
		TITLE => "$g{db_tables}{$list->{spec}{table}}{desc}",
		ORDERBY => $list->{spec}{orderby},
	);

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

	if  (  $g{conf}{edit_buttons_left} == 1 ){
		if($can_edit) {
			$template_args{ELEMENT}='th_edit';
			print Template(\%template_args);
		}
		if($can_add) {
			$template_args{ELEMENT}='th_clone';
			print Template(\%template_args);

		}
		if($can_delete) {
			$template_args{ELEMENT}='th_delete';
			print Template(\%template_args);
		}
	}

	for my $c (@{$list->{columns}}) {
		next if $c->{hide_list};
		my $sort_url;
		if($list->{spec}{orderby} eq $c->{field}) {
			my $d = $list->{spec}{descending} ? '' : 1;
			$sort_url = MakeURL($s->{url}, { descending => $d });
		}
		else {
			$sort_url = MakeURL($s->{url}, { orderby => "$c->{field}", descending=>'' });
		}

		$template_args{ELEMENT}='th';
		$template_args{DATA}=$c->{desc};
		$template_args{FIELD}=$c->{field};
		$template_args{SORT_URL}=$sort_url;
		print Template(\%template_args);
	}
	delete $template_args{DATA};
	delete $template_args{FIELD};
	delete $template_args{SORT_URL};

	unless (  $g{conf}{edit_buttons_left} == 1 ){
		if($can_edit) {
			$template_args{ELEMENT}='th_edit';
			print Template(\%template_args);
		}
		if($can_add) {
			$template_args{ELEMENT}='th_clone';
			print Template(\%template_args);

		}
		if($can_delete) {
			$template_args{ELEMENT}='th_delete';
			print Template(\%template_args);
		}
	}

	$template_args{ELEMENT}='xtr';
	print Template(\%template_args);
	
	# data
	$list->{displayed_recs} = 0;
	for my $row (@{$list->{data}}) {
		$list->{displayed_recs}++;
		if($list->{displayed_recs}%2) { $template_args{EVENROW}=1; }
		else                          { $template_args{ODDROW}=1; }

		$template_args{ELEMENT}='tr';
		print Template(\%template_args);

	if  (  $g{conf}{edit_buttons_left} == 1 ){
		$template_args{ID} = $row->[0];
		GUI_EditLink($s, \%template_args, $list, $row) if $can_edit;
		GUI_AddFromLink($s, \%template_args, $list, $row) if $can_add;
		GUI_DeleteLink($s, \%template_args, $list, $row) if $can_delete;
		delete $template_args{ID};
	}

		my $column_number = 0;
		for my $d (@{$row->[1]}) {
			delete $template_args{ALIGN};
			delete $template_args{ELEMENT};
			delete $template_args{DATA};

			my $c = $list->{columns}[$column_number];
			$column_number++;
			next if $c->{hide_list};
			if($c->{type} eq 'bytea' && $d ne '&nbsp;'){
				my $bloburl = MakeURL($s->{url}, {
						table => $list->{spec}{view},
						action => 'dumpblob',
						id => $row->[0],
						field => $c->{field},
				});
				$d = qq{<A HREF="$bloburl" TARGET="_blank">$d</A>};
			}
			my $align = $c->{align};

			if((!$list->{spec}{export}) and $c->{reference}){
				my $ref_table = $c->{reference};
				my $ref_id = 
				    DB_FetchReferencedId($s,
							 $list->{spec}{table},
							 $c->{field},
							 $row->[0]);
				my $refurl = MakeURL($s->{url}, {
						table => $ref_table,
						action => 'edit',
						id => $ref_id});
				$align = '"LEFT"';
				$d = qq{<A HREF="$refurl">$d</A>};
			}
			
			if($c->{refcount}){
				my $refurl = MakeURL($s->{url}, {
						table => $c->{desc},
						action => 'list',
						search_field => 'meta_rc_'.$c->{tar_field},
						search_value => $row->[0]});
				$d = qq {<A HREF="$refurl">$d items</a>};
			}
			
			defined $align or $align = $numeric_types{$c->{type}} ?
				'"RIGHT" NOWRAP' : '"LEFT"' unless defined $align;
			$template_args{ALIGN}=$align;
			$template_args{ELEMENT}='td';
			$template_args{DATA}=$d;
			$template_args{DATA}=GUI_HTMLMarkup($d) if $d and $c->{markup};
			print Template(\%template_args);
		}
		
		delete $template_args{DATA};
		delete $template_args{ALIGN};

		unless (  $g{conf}{edit_buttons_left} == 1 ){
			$template_args{ID} = $row->[0];
			GUI_EditLink($s, \%template_args, $list, $row) 
				if $can_edit;
			GUI_AddFromLink($s, \%template_args, $list, $row) 
				if $can_add;
			GUI_DeleteLink($s, \%template_args, $list, $row) 
				if $can_delete;
			delete $template_args{ID};
		}

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
		IS_REPORT => $list->{is_report}
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
		user => $user,
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
		GUI_FilterFirst($s, $dbh, $spec{view}, \%template_args);

	# search
	($spec{search_field}, $spec{search_value}) =
		GUI_Search($s, $spec{view}, \%template_args);

	# fetch list
	my $list = DB_FetchList($s, \%spec);

	# get total number of records for this search set
	$list->{totalrecords} = DB_GetNumRecords($s, \%spec)
		if $g{conf}{show_row_count};
	
	# is it a report (read-only)?
	$list->{is_report} = 1 if $g{db_tables}{$table}{report};
	
	my $list_buttons = $g{conf}{list_buttons} || 'both';

	# top buttons
	if($list_buttons eq 'top' or $list_buttons eq 'both'){
		GUI_ListButtons($s, $list, 'list', 'top');
	}

	# display table
	GUI_ListTable($s, $list, 'list');

	# bottom buttons
	if($list_buttons eq 'bottom' or $list_buttons eq 'both'){
		GUI_ListButtons($s, $list, 'list', 'bottom');
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

sub GUI_WidgetRead($$$)
{
	my ($s, $input_name, $widget) = @_;
	my $q = $s->{cgi};
	my $dbh = $s->{dbh};

	my ($w, $warg) = DB_ParseWidget($widget);

	my $value = $q->param($input_name);
	
	if(grep {/^$w$/} keys %{$g{widgets}}){
		return $g{widgets}{$w}->WidgetRead($s,$input_name,$value,$warg);
	}
	if($w eq 'file'){
		my $file = $value;
		my $deletefile = $q->param("file_delete_$input_name");
		if($deletefile) {
			$value="";
		}
		else {
			if($file) {
				my $filename = scalar $file;
				$filename =~ s/ /_/g;
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
			}
			else {
				#when we are here the file field has not been set
				$value = undef;
			}
		}
	}
	if($w eq 'hid' or $w eq 'hidcombo' or $w eq 'hidisearch' or $w eq 'hjsisearch') {
		if(defined $value and $value !~ /^\s*$/) {
			$value=DB_HID2ID($dbh,$warg->{'ref'},$value);
		}
	}
	# if it's a combo and no value was specified in the text field...
	if($w eq 'idcombo' or $w eq 'hidcombo' or $w eq 'combo') {
		if(not defined $value or $value =~ /^\s*$/) {
			$value = $q->param("${input_name}_combo");
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
	my %record;
	if($action eq 'add' || $action eq 'edit'){
		for my $field (@{$g{db_fields_list}{$table}}) {
			my $value = GUI_WidgetRead($s, "field_$field", $g{db_fields}{$table}{$field}{widget});
			if(defined $value) {
				$record{$field} = $value;
			}
		}
	}
	if($action eq 'add') {
		if(!DB_AddRecord($dbh,$table,\%record)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($s, $user, $g{db_error},
				$q->param('form_url'), $data, $action);
		}
	}
	elsif($action eq 'edit') {
		$record{id} = $q->param('id');
		if(!DB_UpdateRecord($dbh,$table,\%record)) {
			my $data = GUI_Hash2Str(\%record);
			GUI_Edit_Error($s, $user, $g{db_error},
			$q->param('form_url'), $data, $action);
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
	our %template_form_args;

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

	my $form_url = MakeURL($s->{url}, { refresh => NextRefresh(),
					   copyfromid => ''});
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

	our $edit_mask = $g{db_tables}{$table}{meta}{editmask};
	print STDERR "editmask: $edit_mask\n\n";
	GUI_InitTemplateArgs($s, \%template_form_args) if defined $edit_mask;


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
	    if (defined $q->url_param('copyfromid')){
		DB_GetRecord($dbh,$table,$q->url_param('copyfromid'),\%values);
	    } else {
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
				# FIXME: find out how this works with files.
				# I think we don't want to copy a file.
				my $v = GUI_WidgetRead($s, "field_$field", $g{db_fields}{$table}{$field}{widget});
				$values{$field} = $v if defined $v;
			}
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
	my $n=0;
	foreach $field (@fields_list) {
		if($field eq "${table}_id") { next; }

		my $value = exists $values{$field} ? $values{$field} : '';
		# get default from DB
		if(not defined $value or $value eq '') {
			$value = DB_GetDefault($dbh,$table,$field);
		}

		my $inputelem = GUI_WidgetWrite($s, "field_$field", $fields->{$field}{widget},$value);

               if (defined $edit_mask){
                    $template_form_args{ELEMENT} = $edit_mask;

                    $template_form_args{FIELD} = $field;
                    $template_form_args{(uc $field)."_LABEL"}=
                                                   $fields->{$field}{desc};
                    $template_form_args{(uc $field)."_INPUT"}= $inputelem

                } else {

		    $template_args{ELEMENT} = 'editfield';
	    	    $template_args{FIELD} = $field;
		    $template_args{LABEL} = $fields->{$field}{desc};
		    $template_args{INPUT} = $inputelem;
			if ( defined $g{db_tables}{$table}{meta}{twocols} 
			     and  $g{db_tables}{$table}{meta}{twocols}== 1 ){
			   $template_args{TWOCOL} = $n%2 ;
			} else {
			   $template_args{TWOCOL} = 0;
			}
			print Template(\%template_args);
	       }
		$n++;
	}
	delete $template_args{FIELD};
	delete $template_args{LABEL};
	delete $template_args{INPUT};
	
	if (defined $edit_mask){
	        print Template ( \%template_form_args );
	        #undef %template_form_args;
	}

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
	
sub GUI_Pearl($)
{
	my $s = shift;
	my $dbh = $s->{dbh};
	my $user = $s->{user};
	my $q = $s->{cgi};
	my $pearl = $q->url_param('pearl');

	if(not exists $g{pearls}{$pearl}) {
		die "Error: pearl named $pearl is known";
	}
	my $p = $g{pearls}{$pearl};

	my $title = ($p->info())[0];
	my %template_args = (
		USER => $user,
		PAGE => 'edit',
		TABLE => '',
		TITLE => "Configure $title",
		BUTTON_LABEL => 'Run Report',
	);

	my $form_url = MakeURL(MyURL($q),{});
	my $cancel_url = MakeURL($form_url, {
		action => 'entry'});

	my $next_url = 	$form_url;

	GUI_InitTemplateArgs($s, \%template_args);
	GUI_Header($s, \%template_args);

	# FORM
	FormStart($s, $next_url);
	print "<INPUT TYPE=\"hidden\" NAME=\"action\" VALUE=\"runpearl\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"pearl\" VALUE=\"$pearl\">\n";
	# Fields
	$template_args{ELEMENT} = 'editform_header';
	print Template(\%template_args);

	my $field;
	my $n;
	for (@{$g{pearls}{$pearl}->template()}){
		my ($field,$label,$widget,$value,$test) = @$_;
		my $inputelem = GUI_WidgetWrite($s,"field_$field",$widget,$value);

		$template_args{ELEMENT} = 'editfield';
		$template_args{FIELD} = $field;
		$template_args{LABEL} = $label;
		$template_args{INPUT} = $inputelem,
		$template_args{TWOCOL} = $n%2;
		print Template(\%template_args);
		$n++;
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

	FormEnd($s);
	GUI_Footer(\%template_args);
}

sub GUI_MakeCombo($$$$)
{
	my ($dbh, $combo_view, $name, $value) = @_;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	my $str;

	my @combo;
	if(not defined DB_GetCombo($dbh,$combo_view,\@combo)) {
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

sub GUI_MakeRadio($$$$$$)
{
	my ($dbh, $combo_view, $name, $value,$shownull, $nulltext) = @_;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	my $str;

	my @combo;
	#die "GUI_MakeRadio vor DB_GetCombo, $dbh , $combo_view, \@combo)";
	if(not defined DB_GetCombo($dbh,$combo_view,\@combo)) {
		return undef;
	}

	if ( $shownull == 1 ){
	    print STDERR "shownull = $shownull, nulltext = $nulltext\n";
	    #$nulltext = " " unless defined $nulltext;
	    $str .= "<input type=\"radio\" name=\"$name\" value=\"\" ";

	    if( $value eq "" ) {
	                  $str .= " checked=\"checked\" ";
	          }
	      $str .= ">$nulltext &nbsp";
	}

	foreach(@combo) {
		my $id = $_->[0];
		$id=~s/^\s+//; $id=~s/\s+$//;
		my $text = $_->[1];
		$str .= "<input type=\"radio\" name=\"$name\" value=\"$id\" ";;
		if($value eq $id) {
			$str .= " checked=\"checked\" ";
		}
		$str .= ">$text&nbsp\n";
	}
	return $str;
}

sub GUI_MakeISearch($$$$$$)
{
	my $ref_target = shift;
	my $input_name = shift;
	my $ticket = shift;
	my $myurl = shift;
	my $value = shift;
	my $hidisearch = shift;
	
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;


	my $targeturl = MakeURL($myurl,{action=>'dumptable',table=>$ref_target,ticket=>$ticket});

	my $html;
	$html .= "<input type=\"button\" onclick=\"";
	$html .= "document.editform.$input_name.value=document.isearch_$input_name.getID('$value')";
	$html .= ";\" value=\"I-Search\">&nbsp;";
	$html .= "<applet id=\"isearch_$input_name\" name=\"isearch_$input_name\"";
	$html .= ' code="ISearch.class" width="70" height="20" archive="'.$g{conf}{isearch}.'">'."\n";
	$html .= GUI_AppletParam("url",$targeturl);
	if($hidisearch){
		$html .= GUI_AppletParam("hid","true");
	}
	$html .= "</applet>\n";
	
	return $html
}

sub GUI_MakeJSISearch($$$$$$)
{
	my $ref_target = shift;
	my $input_name = shift;
	my $ticket = shift;
	my $myurl = shift;
	my $value = shift;
	my $hidisearch = shift;
	
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;


	my $targeturl = MakeURL($myurl,{action=>'jsisearch',
					table=>$ref_target,
					hid=>$hidisearch,
					input_name=>$input_name});

	my $html;
	$html .= qq{<input type="button" onclick="};
	$html .= qq{var tmp=window.open('','INTERACTIVE_SEARCH',};
	$html .= qq{'width=500,height=500};	
	$html .= qq{location=no,directories=no,screenX=50,screenY=50};
	$html .= qq{,toolbar=no,status=no');tmp.document.location.href='$targeturl';" };
	$html .= qq{value="I-Search">};
	return $html;
}

sub GUI_DumpJSIsearch($$$){
	my $s = shift;
	my $q = $s->{cgi};
	my $dbh = shift;
	my $hid = shift;
	my $myurl = MyURL($q);
	my $table = $q->url_param('table');
	my $input_name = $q->url_param('input_name');

	#filter the table on these variables.
	my %atribs;
	foreach($q->param) {
		if(/^field_(.*)/) {
			$atribs{$1} = $q->param($_);
		}
	}
	my $data;

	#perhaps there is a view for this table
	my $view = defined $g{db_tables}{"${table}_list"} ?
			"${table}_list" : $table;

	my $jsheader = "<script language=\"javascript\">\n<!--\n";
	my $jsfooter = "//-->\n</script>\n";
       

	my @fields_list = @{$g{db_fields_list}{$view}};	

	#will hold the number of the id of hid
	#column from which to return values.
	my $retcolumn = 0; 

	if($hid){
		my $tmp = 0;
		for my $fieldname (@fields_list){
			if($fieldname =~ /_hid/){
				$retcolumn = $tmp;
			}
			$tmp++;
		}

	}

	my $fieldsrows="";
	for my $fieldname (@fields_list){
		my $field_data = $q->param("field_".$fieldname);
		$fieldsrows .= Template({FIELDNAME=>$fieldname,
					 DATA=>$field_data,
					 PAGE=>'jsisearch',
					 ELEMENT=>'field'});
	}
	my %template_args = (PAGE => 'jsisearch',
			     ELEMENT=>'head',
			     RETCOLUMN=>$retcolumn,
			     INPUTNAME=>$input_name,
			     TABLE=>$table,
			     MYURL=>$myurl,
			     HID=>$hid,
			     FIELDS=>$fieldsrows);
	
	#I'm using prints here to stream the data to the client.
	print Template(\%template_args);
	DB_DumpJSITable($dbh,$table,\%atribs);
	
	#this is the javascript function that will make all
	# the magick happen.
	print $jsheader."display();\n".$jsfooter;
	
	print Template({PAGE=>'jsisearch',ELEMENT=>'foot'});
}


sub GUI_AppletParam($$){
	my $name=shift;
	my $value=shift;
	return "<param name=\"$name\" value=\"$value\">\n";
}



sub GUI_WidgetWrite($$$$)
{
	my ($s, $input_name, $widget, $value) = @_;

	my $q = $s->{cgi};
	my $dbh = $s->{dbh};
	my $myurl = MyURL($q);

	if(not defined $value) { $value = ''; }

	my ($w, $warg) = DB_ParseWidget($widget);

	my $escval = $value;
	$escval =~ s/\"/&quot;/g;

	if(grep {/^$w$/} keys %{$g{widgets}}){
		return $g{widgets}{$w}->WidgetWrite($s,$input_name,$value,$warg);
	}
	elsif($w eq 'readonly') {
		return $value || '&nbsp;';
	}
	elsif($w eq 'text') {
		my $size = defined $warg->{size} ? $warg->{size} : '20';
		return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"$size\" VALUE=\"".$escval."\">";
	}
	elsif($w eq 'area') {
		my $rows = defined $warg->{rows} ? $warg->{rows} : '4';
		my $cols = defined $warg->{cols} ? $warg->{cols} : '60';
		return "<TEXTAREA NAME=\"$input_name\" ROWS=\"$rows\" COLS=\"$cols\" WRAP=\"virtual\">".$value."</TEXTAREA>";
	}
	elsif($w eq 'varchar') {
		my $size = defined $warg->{size} ? $warg->{size} : '20';
		my $maxlength = defined $warg->{maxlength} ? $warg->{maxlength} : '100';
		return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"$size\" MAXLENGTH=\"$maxlength\" VALUE=\"$escval\">";
	}
	elsif($w eq 'checkbox') {
		return "<INPUT TYPE=\"checkbox\" NAME=\"$input_name\" VALUE=\"1\"".($value ? 'CHECKED' : '').">";
	}
	elsif($w eq 'hid') {
		return "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=\"10\" VALUE=\"".$escval."\">";
	}
	elsif($w eq 'isearch' or $w eq 'hidisearch') {
		my $out;
		my $hidisearch;
		$hidisearch = 0;
		if($w eq 'hidisearch') {
			# replace value with HID if 'hidcombo'
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value);
			$hidisearch=1;
		}
		
		my $combo = GUI_MakeISearch($warg->{'ref'}, $input_name,
			$s->{ticket_value}, $myurl, $value, $hidisearch);

		$out.="<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=10";
		$out .= " VALUE=\"$value\"";
		$out .= ">\n$combo";
		return $out;
	}
	elsif($w eq 'jsisearch' or $w eq 'hjsisearch') {
		my $out;
		my $hidisearch;
		$hidisearch = 0;
		if($w eq 'hjsisearch') {
			# replace value with HID if 'hidcombo'
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value);
			$hidisearch=1;
		}
		
		my $combo = GUI_MakeJSISearch($warg->{'ref'}, $input_name,
			$s->{ticket_value}, $myurl, $value, $hidisearch);

		$out.="<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=10";
		$out .= " VALUE=\"$value\"";
		$out .= ">\n$combo";
		return $out;
	}
	elsif($w eq 'idcombo' or $w eq 'hidcombo') {
		my $out;
		my $combo;
		
		if($g{conf}{gedafe_compat} eq '1.0') {
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value) if $w eq 'hidcombo';
			$combo = GUI_MakeCombo($dbh, $warg->{'combo'}, "${input_name}_combo", $value);
		}
		else {
			$combo = GUI_MakeCombo($dbh, $warg->{'combo'}, "${input_name}_combo", $value);
			$value = DB_ID2HID($dbh,$warg->{'ref'},$value) if $w eq 'hidcombo';
		}
		$out .= "<INPUT TYPE=\"text\" NAME=\"$input_name\" SIZE=10";
		if($combo !~ /SELECTED/ and defined $value) {
			$out .= " VALUE=\"$value\"";
		}
		$out .= ">\n$combo";
		return $out;
	}
	elsif($w eq 'combo') {
		return GUI_MakeCombo($dbh, $warg->{'combo'}, "${input_name}_combo", $value);
	}
	elsif($w eq 'radio' ) {
		# Do NOT support old HID Behaviour
		my ($radio);
		$radio = GUI_MakeRadio($dbh, $warg->{'combo'}, 
			"${input_name}",
			$value,$warg->{'shownull'},$warg->{'nulltext'});

		return $radio;



	}
	elsif($w eq 'file'){
		my $filename = $value ne ''  ? $value : "(none)";
		my $out = "Current file: <b>$filename</b>";
		if($value ne ''){
			$out .= "<br>Delete file?: <INPUT TYPE=\"checkbox\" NAME=\"file_delete_$input_name\">";
		}
		$out .= "<br>Enter filename to update.<br><INPUT TYPE=\"file\" NAME=\"$input_name\">";
		return $out;
	}
	elsif($w eq 'date') {
		return GUI_WidgetWrite_Date($input_name, $warg, $value);
	}

	return "Unknown widget: $w";
}

sub GUI_WidgetWrite_Date($$$)
{
	my ($input_name, $warg, $value) = @_;
	my ($value_y, $value_m, $value_d) = (0, 0, 0);
	my $escval = $value; $escval =~ s/\"/&quot;/g;
		
	my @months;
	if($warg->{short}) {
		@months = ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
			"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	}
	else {
		@months = ("January", "February", "March", "April",
			"May", "June", "July", "August", "September",
			"October", "November", "December");
	}

	my $yearselect = "<option>(year)</option>\n";
	my $dayselect = "<option>(day)</option>\n";
	my $monthselect = "<option>(month)</option>\n";
	
	if($value =~ /(\d+)-(\d+)-(\d+)/) {
		($value_y, $value_m, $value_d) = ($1, $2, $3);
	}
	
	for my $y (($warg->{from})..($warg->{to})) {
		if ($y == $value_y) {
			$yearselect .= "<option selected>$y</option>\n";
		}
		else {
			$yearselect .= "<option>$y</option>\n";
		}
	}
	for my $m (0..11) {
		if ($m+1 == $value_m) {
			$monthselect .= "<option selected>$months[$m]</option>\n";
		}
		else {
			$monthselect .= "<option>$months[$m]</option>\n";
		}
	}
	for my $d (1..31) {
		if ($d == $value_d) {
			$dayselect .= "<option selected>$d</option>\n";
		}
		else {
			$dayselect .= "<option>$d</option>\n";
		}
	}
	
	my $yearinput = $input_name.'_1';
	my $monthinput = $input_name.'_2';
	my $dayinput = $input_name.'_3';
	my $functionname = $input_name.'_validate';
	my $out =<<end;
<SCRIPT LANGUAGE="JavaScript">
<!--
  function $functionname(){
    var leap = 0;
    
    //get variables from form
    var year = document.editform.$yearinput.selectedIndex;
    var month = document.editform.$monthinput.selectedIndex;
    var day = document.editform.$dayinput.selectedIndex;

    // if year month or date are on the (first) empty field
    // then the date is invalid. Clear the field to reflect that. 
    if(year == 0 || month == 0 || day == 0){
      document.editform.$input_name.value = "";
      return;
    }

    year = $warg->{from} + year - 1;

    // is this a leap year?
    if ((year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0))){ 
      leap = 1;
    }
    

    //update form to reflect corretions on date
    if ((month == 2) && (leap == 1) && (day > 29)){ 
      document.editform.$dayinput.selectedIndex = 29;
      day = 29;
    }
    
    if ((month == 2) && (leap != 1) && (day > 28)){
      document.editform.$dayinput.selectedIndex = 28;
      day = 28;
    }

    if ((day > 30) && ((month == 4) || (month == 6) || (month == 9) || (month == 11))){
      document.editform.$dayinput.selectedIndex = 30;
      day = 30;
    }


    var date = year + "-" + month + "-" + day;

    
    document.editform.$input_name.value = date;
  }
//  -->
</script>

<select NAME="$yearinput" onChange="$functionname()">
  $yearselect</select>

<select NAME="$monthinput" onChange="$functionname()">
  $monthselect</select>

<select NAME="$dayinput" onChange="$functionname()">
  $dayselect</select>



<input TYPE="hidden" NAME="$input_name" VALUE="$escval">
end
	return $out;
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

sub GUI_DumpTable($$){
	my $s = shift;
	my $q = $s->{cgi};
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

	my $view = defined $g{db_tables}{"${table}_list"} ?
			"${table}_list" : $table;

	my @fields_list = @{$g{db_fields_list}{$view}};
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
# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "BSD")
# cperl-indent-level: 8
# mode: flyspell
# mode: flyspell-prog
# End:
#

# vi: tw=0 sw=8

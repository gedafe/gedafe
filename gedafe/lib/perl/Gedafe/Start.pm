# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::Start;
use strict;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(Start);

use CGI 2.00 qw(-compile :cgi);

use Gedafe::Auth qw(AuthConnect);
use Gedafe::Global qw(%g);
use Gedafe::GUI qw(
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
	GUI_Oyster
);
use Gedafe::DB qw(
	DB_GetBlobType
	DB_GetBlobName
	DB_DumpBlob
	DB_ReadDatabase
);

use Gedafe::Util qw(
        Die
        MakeURL
        MyURL
	InitTemplate
	Template
	NextRefresh
	InitPearls
	InitWidgets
	InitOysters
);

sub Start(%)
{
	my %conf = @_;

	my $q = new CGI;
	my $user = '';
	my $cookie;

	# %s is the session global state, so that we don't have
	# to pass everything as single arguments to each sub
	my %s = ( cgi => $q);

	# store the session state in the global state for the Die handler
	# \%s should be passed normally as argument...
	$g{s}=\%s;

	# install Gedafe's die handler
	$SIG{__DIE__}=\&Die; #}}

	# init global state if 'reload' in the url
	if(defined $q->url_param('reload')) {
	  %g = ();
	}

	# configuration
	if(not exists $g{conf}) {
		# defaults
		$g{conf} = {
			list_rows  => 10,
			tickets_socket => '/tmp/.gedafed.sock',
			gedafe_compat => '1.2',
		};

		# init config
		while(my ($k, $v) = each %conf) {
			$g{conf}{$k}=$v;
		}

		# test mandatory arguments
		my @mandatory = ('templates', 'db_datasource');
		for my $m (@mandatory) {
			defined $g{conf}{$m} or
				die "ERROR: '$m' named argument must be defined in Start.\n";
		}
	}

	# schema
	my $url_schema = $q->url_param('schema');
	$s{schema} = defined $url_schema ? $url_schema : $g{conf}{schema};
	
	$s{url} = MyURL($q);
	$q->url(-absolute=>1) =~ /(.*)\/([^\/]*)/;
	$s{path} = $1; $s{script} = $2;
	$s{ticket_name} = "Ticket_$2"; $s{ticket_name} =~ s/\./_/g;

	my $expires = defined $q->url_param('refresh') ? '+5m' : '-1d';

	InitTemplate("$g{conf}{templates}",".html");

	InitPearls($g{conf}{pearl_dir}) if defined $g{conf}{pearl_dir};

	InitOysters($g{conf}{oyster_dir}) if defined $g{conf}{oyster_dir};

	InitWidgets($g{conf}{widget_dir}) if defined $g{conf}{widget_dir};

	if(defined $q->url_param('reload')) {
		my $next_refresh=NextRefresh();
		print $q->header(-expires=>'-1d');
		print Template({
			PAGE => 'reload',
			ELEMENT => 'reload',
			THISURL => MyURL($q),
			NEXTURL => MakeURL(MyURL($q), { reload=>'', refresh=>$next_refresh }),
		});
		exit;
	}

	GUI_CheckFormID(\%s, $user);

	my $ticket_value;
	my $dbh = AuthConnect(\%s, \$user, \$cookie,\$ticket_value) or do {
		die "Couldn't connect to database or database error";
	};
	
	$s{dbh}=$dbh;
	$s{user}=$user;
	$s{ticket_value}=$ticket_value;
	# print STDERR "TicketValue: $ticket_value\n";
    
 	my $action = $q->url_param('action') || '';
	if($action eq 'edit' or $action eq 'add' or $action eq 'delete') {
		# cache forms...
		$expires = '+1d';
	}
	if($q->request_method() eq 'POST') {
		# do not cache POST requests, so that for "Duplicate Form" is
		# shown if needed...
		$expires = '-1d';
	}

	if($action eq 'export') {
		my $table = $q->url_param('table');
		GUI_Export(\%s, $user, $dbh);
		exit;
	}

	my %headers =(-expires=>$expires);

	if($cookie) {
		$headers{-cookie} = $cookie;
	}

	if($action =~ /((view)|(download)|(dump))blob/){
		my $table = $q->param('table');
		my $id = $q->param('id');
		my $field = $q->param('field');
		my $type = DB_GetBlobType($dbh,$table,$field,$id);
		my $name = DB_GetBlobName($dbh,$table,$field,$id);
		$headers{-type}=$type;
		if($action =~ /download/){
			$headers{-attachment}=$name;
		}elsif($action =~ /dump/){
			my @browsertypes = ('text/plain',
					    'text/html',
					    'image/jpeg',
					    'image/png',
					    'image/gif');
			$headers{-attachment}=$name
			    unless(grep $_ eq lc($type), @browsertypes); 
		}else{
			#nothing to do for view...
		}
	}

	if($action eq 'dumptable') {
		$headers{-type}='text/plain';
	}

	if ($action eq 'runpearl')  {
		my $pearl = $q->url_param('pearl');
		Die "No Pearl named $pearl available" unless
		    defined $g{pearls}{$pearl} and ref $g{pearls}{$pearl};
		my($h,$b) =$g{pearls}{$pearl}->run(\%s);
		die "Sorry. The Pearl '$pearl' did not return any data.".
		    "<br>You can use the BACK button!\n"
		    if  $b =~ /^\s*$/;
		print $q->header(-type=>$h,-Content_Length=>(length $b));
		print $b;
		$dbh->disconnect;
		return;
	}


	print $q->header(%headers);
	$s{http_header_sent}=1;
	
	GUI_PostEdit(\%s, $user, $dbh);

	if($action eq 'list' or $action eq 'listrep') {
		GUI_List(\%s, $user, $dbh);
	}
	elsif($action eq 'edit' or $action eq 'add' or $action eq 'reedit') {
		GUI_Edit(\%s, $user, $dbh);
	}
	elsif($action eq 'configpearl') {
		GUI_Pearl(\%s);
	}
	elsif($action eq 'oyster') {
		GUI_Oyster(\%s);
	}
	elsif($action eq 'delete') {
		GUI_Delete(\%s, $user, $dbh);
	}
	elsif($action =~ /((view)|(download)|(dump))blob/){
		my $table = $q->param('table');
		my $id = $q->param('id');
		my $field = $q->param('field');
		DB_DumpBlob($dbh,$table,$field,$id);
	}
	elsif($action eq 'dumptable'){
		my $table = $q->url_param('table');
		GUI_DumpTable(\%s, $dbh);
	}
	elsif($action eq 'jsisearch'){
		my $table = $q->url_param('table');
		my $hid = $q->url_param('hid');
		GUI_DumpJSIsearch(\%s, $dbh,$hid);
	}
	else {
		GUI_Entry(\%s, $user, $dbh);
	}

	$dbh->disconnect;
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


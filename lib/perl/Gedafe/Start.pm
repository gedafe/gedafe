# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2002 ETH Zurich
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
);
use Gedafe::DB qw(
	DB_GetBlobType
	DB_GetBlobName
	DB_DumpBlob
);

use Gedafe::Util qw(Die MakeURL MyURL InitTemplate Template NextRefresh);

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
	$SIG{__DIE__}=\&Die;

	if(defined $q->url_param('reload')) {
		%g = ();
	}

	# configuration
	if(not exists $g{conf}) {
		# defaults
		$g{conf} = {
			list_rows  => 10,
			tickets_socket => '/tmp/.gedafed.sock',
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

	
	$s{url} = MyURL($q);
	$q->url(-absolute=>1) =~ /(.*)\/([^\/]*)/;
	$s{path} = $1; $s{script} = $2;
	$s{ticket_name} = "Ticket_$2"; $s{ticket_name} =~ s/\./_/g;

	my $expires = defined $q->url_param('refresh') ? '+5m' : '-1d';

	InitTemplate("$g{conf}{templates}",".html");

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

	my $dbh = AuthConnect(\%s, \$user, \$cookie) or do {
		die "Couldn't connect to database or database error";
	};
	$s{dbh}=$dbh;
	$s{user}=$user;

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

	if($action eq 'dumpblob'){
	    my $table = $q->param('table');
	    my $id = $q->param('id');
	    my $field = $q->param('field');
	    my $type = DB_GetBlobType($dbh,$table,$field,$id);
	    my $name = DB_GetBlobName($dbh,$table,$field,$id);
	    print $q->header(-expires=>$expires,
			     -type=>$type,
			     -attachment=>$name);
	}else{
	    # header
	    if(! $cookie) {
		print $q->header(-expires=>$expires);
	    } else {
		print $q->header(-expires=>$expires,-cookie=>$cookie);
	    }
	}
	$s{http_header_sent}=1;
	GUI_PostEdit(\%s, $user, $dbh);

	if($action eq 'list') {
		GUI_List(\%s, $user, $dbh);
	}
	elsif($action eq 'edit' or $action eq 'add' or $action eq 'reedit') {
		GUI_Edit(\%s, $user, $dbh);
	}
	elsif($action eq 'delete') {
		GUI_Delete(\%s, $user, $dbh);
	}elsif($action eq 'dumpblob'){
	    my $table = $q->param('table');
	    my $id = $q->param('id');
	    my $field = $q->param('field');
	    DB_DumpBlob($dbh,$table,$field,$id);
	}
	else {
		GUI_Entry(\%s, $user, $dbh);
	}

	$dbh->disconnect;
}

1;

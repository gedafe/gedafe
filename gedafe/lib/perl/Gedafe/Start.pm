# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::Start;
use strict;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(Start);

use CGI 2.00 qw(-compile :cgi);

use Gedafe::Auth;
use Gedafe::Global qw(%g %s *u Global_InitSession Global_InitUser);
use Gedafe::GUI;
use Gedafe::Util;


sub Start(%)
{
	my %conf = @_;

	Global_InitSession();

	my $q = new CGI;
	my $user = '';
	my $cookie;

	if(defined $q->url_param('reload')) {
		%g = ();
	}

	# configuration
	if(not exists $g{conf}) {
		# defaults
		$g{conf} = {
			list_rows  => 10,
			admin_user => 'admin',
			tickets_socket => '/tmp/.gedafed.sock',
		};

		# init config
		while(my ($k, $v) = each %conf) {
			$g{conf}{$k}=$v;
		}

		# test mandatory arguments
		my @mandatory = ('templates', 'app_site','app_path');
		for my $m (@mandatory) {
			defined $g{conf}{$m} or
				die "ERROR: '$m' named argument must be defined in Start.\n";
		}

		# app_url
		$g{conf}{app_url} = "http://$g{conf}{app_site}$g{conf}{app_path}";
	}

	my $expires = defined $q->url_param('refresh') ? '+5m' : '-1d';

	InitTemplate("$g{conf}{templates}",".html");

	if(defined $q->url_param('reload')) {
		my $next_refresh=GUI_NextRefresh();
		print $q->header(-expires=>'-1d');
		print Template({
			PAGE => 'reload',
			ELEMENT => 'reload',
			THISURL => MyURL($q),
			NEXTURL => MakeURL(MyURL($q), { reload=>'', refresh=>$next_refresh }),
		});
		exit;
	}

	if($q->url() !~ "^$g{conf}{app_url}") {
		print $q->header(-expires=>$expires);
		print Template({
			PAGE => 'wrong_url',
			ELEMENT => 'wrong_url',
			CORRECTURL => "$g{conf}{app_url}",
		});
		exit;
	}

	GUI_CheckFormID($user, $q);

	my $dbh = AuthConnect($q, \$user, \$cookie) or do {
		print "\nCouldn't connect to database or database error.\n";
		exit;
	};

	Global_InitUser($user);
	
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

	# header
	if(! $cookie) {
		print $q->header(-expires=>$expires);
	} else {
		print $q->header(-expires=>$expires,-cookie=>$cookie);
	}

	GUI_PostEdit($q, $user, $dbh);

	if($action eq 'list') {
		GUI_List($q, $user, $dbh);
	}
	elsif($action eq 'listrep') {
		GUI_ListRep($q, $user, $dbh);
	}
	elsif($action eq 'edit' or $action eq 'add' or $action eq 'reedit') {
		GUI_Edit($q, $user, $dbh);
	}
	elsif($action eq 'delete') {
		GUI_Delete($q, $user, $dbh);
	}
	else {
		GUI_Entry($q, $user, $dbh);
	}


	$dbh->disconnect;
}

1;

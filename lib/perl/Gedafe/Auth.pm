# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::Auth;
use strict;
use Gedafe::Util;
use Gedafe::Global qw(%g);
use Gedafe::DB;
use Gedafe::GUI;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(AuthConnect);

# authentication

sub Auth_GetTicket($$$) {
	my $ticket = shift;
	my $user = shift;
	my $pass = shift;
	my $socket = ConnectToTicketsDaemon();
	print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
	<$socket>;
	print $socket "GET $ticket\n";
	$_ = <$socket>;
	close($socket);
	chomp;
	if(! /^OK ([^ ]+) (.+)$/) {
		return 0;
	}
	$$user = $1;
	$$pass = $2;
	return 1;
}

sub Auth_ClearTicket($) {
	my $ticket = shift;
	my $socket = ConnectToTicketsDaemon();
	print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
	<$socket>;
	print $socket "CLEAR $ticket\n";
	<$socket>;
	close($socket);
}

sub Auth_SetTicket($$) {
	my $user = shift;
	my $pass = shift;
	my $socket = ConnectToTicketsDaemon();
	print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
	<$socket>;
	print $socket "SET $user $pass\n";
	my $ticket = <$socket>;
	close($socket);
	chomp $ticket;
	return $ticket;
}

sub Auth_Login($)
{
	my $q = shift;

	print $q->header;
	print Template({ PAGE => 'login', ELEMENT => 'header' });
	my $form_url = $q->param('form_url') || MyURL($q);
	my $next_url = $q->param('next_url') ||
		MakeURL(MyURL($q), {
			logout=>'',
			refresh=>GUI_NextRefresh($q),
		});
	GUI_Form($next_url);

	print Template({ PAGE => 'login', ELEMENT => 'login' });

	foreach($q->param) {
		if(/^(next_url|form_id|form_url|login_.*)$/ ) { next; }
		if(defined ($q->url_param($_))) { next; }
		print "<INPUT TYPE=\"hidden\" NAME=\"$_\" VALUE=\"" .
			$q->param($_) . "\">\n";
	}

	GUI_xForm($form_url, $next_url);

	print Template({ PAGE => 'login', ELEMENT => 'footer' });

	exit;
}

sub AuthConnect($$$) {
	my $q = shift;
	my $user = shift;
	my $cookie = shift;

	my $pass;
	my $dbh;

	# logout
	if($q->url_param('logout')) {
		my $ticket = $q->cookie(-name=>'Ticket');
		Auth_ClearTicket($ticket) if $ticket;
		Auth_Login($q);
	}

	# check Ticket
	my $c = $q->cookie(-name=>'Ticket');
	if(defined $c and Auth_GetTicket($c, $user, \$pass)) {
		# ticket authentication successfull
		return DB_Connect($$user, $pass);
	}

	# login response
	if(defined $q->param('login_user') or defined $q->url_param('user')) {
		$$user = $q->param('login_user');
		$$user = $q->url_param('user') unless defined $$user;
		$pass = $q->param('login_pass');
		$pass = 'anonymous' unless defined $pass;

		if(defined ($dbh = DB_Connect($$user, $pass))) {
			# user/pass authentication successfull
			my $ticket=Auth_SetTicket($$user, $pass);
			my $domain="$g{conf}{app_site}"; $domain =~ s/:.*$//;
			$$cookie=$q->cookie(-name=>'Ticket', -value=>$ticket);
			return $dbh;
		}
		else {
			# login failed
			print $q->header;
			print Template({ PAGE => 'auth_error', TITLE => 'Authentication Error', ELEMENT => 'header' });
			print Template({ PAGE => 'auth_error', TITLE => 'Authentication Error', ELEMENT => 'header2' });
			print Template({ PAGE => 'auth_error', URL=>MyURL($q), ELEMENT => 'auth_error' });
			print Template({ PAGE => 'auth_error', ELEMENT => 'footer' });
			exit;
		}
	}

	# no login, no ticket -> login
	Auth_Login($q);
}

1;

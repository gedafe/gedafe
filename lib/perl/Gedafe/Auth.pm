# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2002 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::Auth;
use strict;
use Gedafe::Util qw(
	ConnectToTicketsDaemon
	MakeURL
	MyURL
	Template
	UniqueFormStart
	UniqueFormEnd
	NextRefresh
);
use Gedafe::Global qw(%g);
use Gedafe::DB qw(DB_Connect);

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(AuthConnect);

sub Auth_GetTicket($$$$) {
	my $s = shift;
	my $ticket = shift;
	my $user = shift;
	my $pass = shift;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $s->{path}/$s->{script}\n";
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

sub Auth_ClearTicket($$) {
	my $s = shift;
	my $ticket = shift;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $s->{path}/$s->{script}\n";
	<$socket>;
	print $socket "CLEAR $ticket\n";
	<$socket>;
	close($socket);
}

sub Auth_SetTicket($$$) {
	my $s = shift;
	my $user = shift;
	my $pass = shift;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $s->{path}/$s->{script}\n";
	<$socket>;
	print $socket "SET $user $pass\n";
	my $ticket = <$socket>;
	close($socket);
	chomp $ticket;
	return $ticket;
}

sub Auth_Login($)
{
	my $s = shift;
	my $q = $s->{cgi};

	print $q->header;
	$s->{http_header_sent}=1;
	print Template({ PAGE => 'login', ELEMENT => 'header' });
	my $form_url = $q->param('form_url') || MyURL($q);
	my $next_url = $q->param('next_url') ||
		MakeURL(MyURL($q), {
			logout=>'',
			refresh=>NextRefresh(),
		});
	$s->{header_sent}=1;

	UniqueFormStart($s, $next_url);

	print Template({ PAGE => 'login', ELEMENT => 'login' });

	foreach($q->param) {
		if(/^(next_url|form_id|form_url|login_.*)$/ ) { next; }
		if(defined ($q->url_param($_))) { next; }
		print "<INPUT TYPE=\"hidden\" NAME=\"$_\" VALUE=\"" .
			$q->param($_) . "\">\n";
	}

	UniqueFormEnd($s, $form_url, $next_url);

	print Template({ PAGE => 'login', ELEMENT => 'footer' });

	exit;
}

sub AuthConnect($$$) {
	my $s = shift;
	my $q = $s->{cgi};
	my $user = shift;
	my $cookie = shift;

	my $pass;
	my $dbh;

	# logout
	if($q->url_param('logout')) {
		my $ticket = $q->cookie(-name=>$s->{ticket_name});
		Auth_ClearTicket($s, $ticket) if $ticket;
		Auth_Login($s);
	}

	# check Ticket
	my $c = $q->cookie(-name=>$s->{ticket_name});
	if(defined $c and Auth_GetTicket($s, $c, $user, \$pass)) {
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
			my $ticket=Auth_SetTicket($s, $$user, $pass);
			$$cookie=$q->cookie(-name=>$s->{ticket_name},
				-value=>$ticket, -path=>$s->{path});
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
	Auth_Login($s);
}

1;

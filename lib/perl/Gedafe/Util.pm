# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::Util;
use strict;

use Gedafe::Global qw(%g);
use Text::CPPTemplate;

use IO::Socket;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(
	ConnectToTicketsDaemon
	MakeURL
	MyURL
	InitTemplate
	Template
	Error
	DropUnique
	UniqueFormStart
	UniqueFormEnd
	NextRefresh
);
use Data::Dumper;

sub Error($$) {
	my $s = shift;
	my $error_text = shift;

	my %t = (
		PAGE => 'error',
		TITLE => 'Internal Error',
	);

	die "GEDAFE INTERNAL ERROR: $error_text\n" unless (defined $s and defined $s->{cgi});

	if(not $s->{http_header_sent}) {
		print $s->{cgi}->header(-expires=>'-1d');
	}

	if(not $s->{header_sent}) {
		$t{ELEMENT}='header';
		print Template(\%t);

		$t{ELEMENT}='header2';
		print Template(\%t);
	}
#	else {
#		$t{ELEMENT}='errorseparator';
#		print Template(\%t);
#	}

	$t{ELEMENT}  ='error';
	$t{ERROR}    = $error_text;
	print Template(\%t);
	delete $t{ERROR};

	$t{ELEMENT}='footer';
	print Template(\%t);

	exit;
}

sub ConnectToTicketsDaemon($) {
	my $s = shift;
	my $file = $g{conf}{tickets_socket};
	my $socket = IO::Socket::UNIX->new(Peer => $file)
		or Error($s, "Couldn't connect to gedafed daemon: $!");
	return $socket;
}

sub MakeURL($$)
{
	my $prev = shift;
	my $new_params = shift;
	my %params = ();
	my $url;

	# parse old url ($prev)
	if($prev =~ /^(.*?)\?(.*)$/) {
		$url = $1;
		foreach(split(/[;&]/,$2)) {
			if(/^(.*?)=(.*)$/) {
				$params{$1} = $2;
			}
		}
	}
	else {
		$url = $prev;
	}

	# merge
	foreach(keys %$new_params) {
		$params{$_} = $new_params->{$_};
	}

	# delete empty values
	foreach(keys %params) {
		if($params{$_} eq '') { delete $params{$_}; }
	}

	# prepare key=value pairs
	my @params_list = ();
	foreach(sort keys %params) {
		push @params_list, "$_=$params{$_}";
	}

	# make url
	if(scalar @params_list != 0) {
		$url .= '?';
		# make url
		$url .= join('&', @params_list);
	}

	return $url;
}

sub MyURL($)
{
	my $q = shift;
	my $qs = $ENV{QUERY_STRING} || '';
	if($qs =~ /^\s*$/) {
		return $q->url();
	}
	else {
		return $q->url().'?'.$qs;
	}
}

sub GetUnique($)
{
	my $s = shift;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $g{conf}{app_site} $g{conf}{app_path}\n";
	<$socket>;
	print $socket "GETUNIQUE\n";
	$_ = <$socket>;
	close($socket);
	if(! /^([\w-]+)$/) {
		Error($s, "Couldn't understand ticket daemon reply: $_");
	}
	return $1;
}

sub DropUnique($$)
{
	my $s = shift;
	my $unique_id = shift;
	if(defined $unique_id) {
		my $socket = ConnectToTicketsDaemon($s);
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

sub UniqueFormStart($)
{
	my $action = shift;
	print "<FORM ACTION=\"$action\" METHOD=\"POST\">\n";
}

sub UniqueFormEnd($$;$)
{
	my $s = shift;
	my $form_url = shift;
	my $next_url = shift || $form_url;

	my $form_id = GetUnique($s);

	print "\n<INPUT TYPE=\"hidden\" NAME=\"form_id\" VALUE=\"$form_id\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"form_url\" VALUE=\"$form_url\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"next_url\" VALUE=\"$next_url\">\n";
	print "</FORM>\n";
}

sub rand_ascii_32
{
	return sprintf "%04x%04x", rand()*(1<<16), rand()*(1<<16);
}

sub NextRefresh()
{
	return rand_ascii_32;
}

sub InitTemplate($$)
{
	return if defined $g{tmpl};
	$g{tmpl} = new Text::CPPTemplate(shift,shift);
}

sub Template($)
{
	return $g{tmpl}->template(shift);
}

1;

# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::Util;
use strict;

use Gedafe::Global qw(%g);
use Text::CPPTemplate;

use IO::Socket;

use vars qw(@ISA @EXPORT);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(
	ConnectToTicketsDaemon
	MakeURL
	MyURL
	InitTemplate
	Template
);

sub ConnectToTicketsDaemon() {
	my $file = $g{conf}{tickets_socket};
	my $socket = IO::Socket::UNIX->new(Peer => $file)
		or die "Couldn't connect to gpw3f_tickets daemon: $!\n";
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

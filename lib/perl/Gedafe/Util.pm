# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2003 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

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
	InitPearls
	InitOysters
	InitWidgets
	Template
	Die
	DropUnique
	FormStart
	UniqueFormStart
	FormEnd
	UniqueFormEnd
	NextRefresh
	StoreFile
	GetFile
	DataTree
	DataUnTree
	Gedafe_URL_Decode
	Gedafe_URL_Encode
	StripJavascript
	SplitCommaQuoted
);

sub DataTree($);
sub DataUnTree($);

# Gedafe's die handler
sub Die($) {
	my $error_text = shift;
	my $s = $g{s};

	# no recursion here please
	$SIG{__DIE__} = 'DEFAULT';

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

	if($s->{in_form}) {
		print "\n</FORM>\n";
	}

	if($s->{in_table}) {
		print Template({ ELEMENT => 'xtable' });
	}

	$t{ELEMENT}  ='error';
	$t{ERROR}    = $error_text ? $error_text : '(unknown)';
	print Template(\%t);
	delete $t{ERROR};

	$t{ELEMENT}='footer';
	print Template(\%t);

#	die "GEDAFE ERROR: $error_text";
	exit 1;
}

sub ConnectToTicketsDaemon($) {
	my $s = shift;
	my $file = $g{conf}{tickets_socket};
	my $socket = IO::Socket::UNIX->new(Peer => $file)
		or Die("Couldn't connect to gedafed daemon: $!");
	return $socket;
}

sub MakeURL($$;$)
{
	my $prev = shift;
	my $new_params = shift;
	my $deletekeys = shift;
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


	# delete entries that match deletekeys
	foreach(keys %params) {
		if(defined $params{$_} and $params{$_} ne ''){
			if($deletekeys){
				foreach my $del (@$deletekeys){
					if ($_ =~ /$del/){
						delete $params{$_};
					}
				}
			}
		}
	}

	# merge
	foreach(keys %$new_params) {
		$params{$_} = $new_params->{$_};
	}


	foreach(keys %params) {
		delete $params{$_} unless (defined $params{$_} and $params{$_} ne '');

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

# get full URL, including parameters
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
	print $socket "SITE $s->{path}/$s->{script}\n";
	<$socket>;
	print $socket "GETUNIQUE\n";
	$_ = <$socket>;
	close($socket);
	if(! /^([\w-]+)$/) {
		Die("Couldn't understand ticket daemon reply: $_");
	}
	return $1;
}

sub DropUnique($$)
{
	my $s = shift;
	my $unique_id = shift;
	if(defined $unique_id) {
		my $socket = ConnectToTicketsDaemon($s);
		print $socket "SITE $s->{path}/$s->{script}\n";
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

sub UniqueFormStart($$)
{
	my $s = shift;
	my $action = shift;
	print qq{<FORM ACTION="$action" METHOD="POST" NAME="editform" ENCTYPE="multipart/form-data">\n};

	$s->{in_form}=1;
}
sub FormStart($$)
{
	my $s = shift;
	my $action = shift;
	print qq{<FORM ACTION="$action" METHOD="GET">\n};
	$s->{in_form}=1;
}

# end form without double form protection
sub FormEnd($)
{
	my $s = shift;

	print "</FORM>\n";

	delete $s->{in_form};
}

sub UniqueFormEnd($$;$)
{
	my $s = shift;
	my $form_url = shift;
	my $next_url = shift || $form_url;

	my $form_id = GetUnique($s);
	print "\n<INPUT TYPE=\"hidden\" NAME=\"form_url\" VALUE=\"$form_url\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"next_url\" VALUE=\"$next_url\">\n";
	print "<INPUT TYPE=\"hidden\" NAME=\"form_id\" VALUE=\"$form_id\">\n";
	FormEnd $s;
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

sub InitPearls($){
	return if defined $g{pearls};
	my $path = shift;
	my %pearls;
	chdir $path || 	Die "switching to 'pearl_dir ($path)': $!\n";
	my @modules = <*.pm>;
	foreach my $module (@modules) {
		$module =~ s/\.pm$//;
		$pearls{$module} = eval "local \$SIG{__DIE__} = 'IGNORE';
		                         require $module;
		                         $module->new()";
		if ($@) {
			$pearls{$module} =
				"<pre>Unable to load Pearl $module.pm from $path<br><br>$@</pre>"
		}
	}
	$g{pearls} = \%pearls;
}

sub InitWidgets($){
	return if defined $g{widgets};
	my $path = shift;
	my %widgets;
	chdir $path || 	Die "switching to 'widget_dir ($path)': $!\n";
	my @modules = <*.pm>;
	foreach my $module (@modules) {
		$module =~ s/\.pm$//;
		$widgets{$module} = eval "local \$SIG{__DIE__} = 'IGNORE';
		                         require $module;
		                         $module->new()";
		if ($@) {
			Die "Unable to load widget $module: $@";
		}
	}
	$g{widgets} = \%widgets;
}

sub InitOysters($){
	return if defined $g{oysters};
	my $path = shift;
	my %oysters;
	chdir $path || 	Die "switching to 'oyster_dir ($path)': $!\n";
	my @modules = <*.pm>;
	foreach my $module (@modules) {
		$module =~ s/\.pm$//;
		$oysters{$module} = eval "local \$SIG{__DIE__} = 'IGNORE';
		                         require $module;
		                         $module->new()";
		if ($@) {
			Die "Unable to load oyster $module: $@";
		}
	}
	$g{oysters} = \%oysters;
}

sub StoreFile($$$$)
{
	my $s = shift;
	my $blob = shift;
	my $name = shift;
	my $type = shift;
	my $length = length $blob;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $s->{path}/$s->{script}\n";
	<$socket>;
	print $socket "FILE $s->{ticket_value} $name $type $length\n";
	$_ = <$socket>;
	if(! /OK/){
		Die("Ticket deamon does not want your file $name: $_");
		close($socket);
	}
	print $socket $blob;
	$_ = <$socket>;
	if(! /FILE OK/){
		Die("Ticket deamon does not like the taste of your file $name: $_");
	}
}

sub GetFile($$)
{
	my $s = shift;
	my $name = shift;
	my $socket = ConnectToTicketsDaemon($s);
	print $socket "SITE $s->{path}/$s->{script}\n";
	<$socket>;
	print $socket "GETFILE $s->{ticket_value} $name\n";
	$_ = <$socket>;
	if(! /^OK ([\w\/-]+) (\d+)$/) {
		Die("Couldn't understand ticket daemon reply: $_");
		close($socket);
	}
	my $type = $1;
	my $length = $2;
	my $blob;
	read($socket,$blob,$length);
	return [$blob,$name,$type];
}

# CGI.pm already encodes/decodes parameters, but we want to do it ourselves
# since we need to differentiate for example in reedit_data between a comma
# as value and a comma as separator. Therefore we use the escape '!' instead
# of '%'.
sub Gedafe_URL_Encode($)
{
	my ($str) = @_;
	defined $str or $str = '';
	$str =~ s/!/gedafe_PROTECTED_eXclamatiOn/g;
	$str =~ s/\W/'!'.sprintf('%02X',ord($&))/eg;
	$str =~ s/gedafe_PROTECTED_eXclamatiOn/'!'.sprintf('%2X',ord('!'))/eg;
	return $str;
}

sub Gedafe_URL_Decode($)
{
	my ($str) = @_;
	$str =~ s/!([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
	return $str;
}



sub DataTree($){
    my $input = shift;
    my ($tmp,$s,$ret,$count,$data,$ds,$name,$value);
    if($input =~ /^s(.*)/){
	$ret =  Gedafe_URL_Decode($1);
    }elsif($input =~/^l(.*)/){
	$tmp = $1;
	$ret = [];
	$count = 0;
	while($tmp ne ''){
	    die("encoded string $tmp does not parse as a list")
		unless($tmp=~/(\d+)-/);
	    my $ds = index($tmp,'-')+1;
	    $data = substr($tmp,$ds,$1);
	    $tmp = substr($tmp,$ds+$1);
	    $ret->[$count++] = DataTree($data);
	}
    }elsif($input =~/^h(.*)/){
	$tmp = $1;
	$ret = {};
	while($tmp ne ''){
	    die("encoded string $tmp does not parse as a list")
		unless($tmp=~/(\d+)_(\d+)-/);
	    my $ds = index($tmp,'-')+1;
	    $name = Gedafe_URL_Decode(substr($tmp,$ds,$1));
	    $value = substr($tmp,$ds+$1,$2);
	    $tmp = substr($tmp,$ds+$1+$2);
	    $ret->{$name} = DataTree($value);
	}
    }else{
	die "String $input does not parse to a value.";
    }
    return $ret;
}


sub DataUnTree($){
    my $var = shift;
    my $type = ref($var);
    return 's'.Gedafe_URL_Encode($var) if(!$type);
    my $retstr;
    my $tmp;
    my $name;
    if($type eq 'ARRAY'){
	$retstr = 'l';
	for(@$var){
	    $tmp = DataUnTree($_);
	    $retstr.=length($tmp).'-'.$tmp;
	}
	return $retstr;
    }
    if($type eq 'HASH'){
	$retstr = 'h';
	for(keys(%$var)){
	    $name = Gedafe_URL_Encode($_);
	    $tmp = DataUnTree($var->{$_});
	    $retstr.=length($name).'_'.length($tmp).'-'.$name.$tmp;
	}
	return $retstr;
    }
    die("data of type: $type cannot be untree-ed yet. post something to the gedafe mailing list");
}

sub StripJavascript($){
	if ($g{conf}{allow_javascript}) { # no stripping
            return shift;
        }
	my $suspicious = shift;
	$suspicious = '' if not defined $suspicious;
	#remove all data-url things except images
	$suspicious =~ s/data:image/gedafeProtected_DATAURL_IMG/gsi;
	$suspicious =~ s/data:/d\@ta:/gsi;
	$suspicious =~ s/gedafeProtected_DATAURL_IMG/data:image/gsi;

	#scripts, javascript urls and iframes are way to
	#dangerous to leave around.
	#Same goes for stylesheets and <link tags

	$suspicious =~ s/<script/<scr\|pt/gsi;
	$suspicious =~ s/javascript/javascr\|pt/gsi;
	$suspicious =~ s/<iframe/<\|frame/gsi;
	$suspicious =~ s/<link/<l\|nk/gsi;
	$suspicious =~ s/<style/<sty\|e/gsi;

	#some eventhandlers that shouldnt be touched.
	$suspicious =~ s/onAbort/on_Abort/gsi;
	$suspicious =~ s/onBlur/on_Blur/gsi;
	$suspicious =~ s/onChange/on_Change/gsi;
	$suspicious =~ s/onClick/on_Click/gsi;
	$suspicious =~ s/onDblClick/on_DblClick/gsi;
	$suspicious =~ s/onError/on_Error/gsi;
	$suspicious =~ s/onFocus/on_Focus/gsi;
	$suspicious =~ s/onKeydown/on_KeyDown/gsi;
	$suspicious =~ s/onKeyup/on_Keyup/gsi;
	$suspicious =~ s/onLoad/on_Load/gsi;
	$suspicious =~ s/onMousedown/on_Mousedown/gsi;
	$suspicious =~ s/onMousemove/on_Mousemove/gsi;
	$suspicious =~ s/onMouseout/on_Mouseout/gsi;
	$suspicious =~ s/onMouseover/on_Mouseover/gsi;
	$suspicious =~ s/onMouseup/on_Mouseup/gsi;
	$suspicious =~ s/onReset/on_Reset/gsi;
	$suspicious =~ s/onSelect/on_Select/gsi;
	$suspicious =~ s/onSubmit/on_Submit/gsi;
	$suspicious =~ s/onUnload/on_Unload/gsi;
	my $mostly_harmless = $suspicious;
	return $mostly_harmless;
}

# like split(/\s*,\s*/, $_), but also respect quoting with '', "", and \
sub SplitCommaQuoted($)
{
	my ($str) = @_;

	# quote % since we will use it for internal purproses
	$str =~ s/%/sprintf("%%%02x", ord('%'))/ge;

	# parse the string as single characters
	my @str = split(//, $str);
	my @list;
	my $element;
	my @state;
	my $pos;
	for my $c (@str) {
		if(defined $state[0] and $state[0] eq '\\') {
			$element .= $c;
			shift @state;
		}
		elsif($c eq '\'') {
			if(defined $state[0] and $state[0] eq '\'') {
				shift @state;
			}
			elsif(defined $state[0]) {
				$element .= $c;
			}
			else {
				unshift @state, $c;
			}
		}
		elsif($c eq '\\') {
			unshift @state, $c;
		}
		elsif($c eq '"') {
			if(defined $state[0] and $state[0] eq '"') {
				shift @state;
			}
			elsif(defined $state[0]) {
				$element .= $c;
			}
			else {
				unshift @state, $c;
			}
		}
		elsif($c eq ',') {
			if(not defined $state[0]) {
				defined $element or $element = '';
				push @list, $element;
				$element = undef;
			}
			else {
				$element .= $c;
			}
		}
		elsif($c eq ' ' or $c eq "\t") {
			if(defined $state[0]) {
				# preserve whitespace, but only if quoted
				$element .= '%'.sprintf("%02x", ord($c));
			}
		}
		else {
			$element .= $c;
		}
		$pos++;
	}
	if(defined $state[0]) {
		die "ERROR: unterminated string: $_[0] at position $pos\n";
	}
	push @list, $element if defined $element;

	# strip space at beginning/end
	map { s/^\s+//; s/\s+$// } @list;
	# decode internal quoting (so that we can have spaces in quotes)
	map { s/(?:%(\d\d))/chr(hex($1))/ge } @list;
	
	return @list;
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

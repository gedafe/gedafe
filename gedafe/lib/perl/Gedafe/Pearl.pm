package Gedafe::Pearl;

use strict;
use Carp;
use Exporter;
use Text::Wrap;
use Gedafe::GUI qw(GUI_WidgetRead);
use POSIX qw(mktime strftime);
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw(format_desc date_print );

# at the moment the class we create is empty

sub new($;@){
    my $proto   = shift;
    my %params = @_;
    my $class   = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
}

# get them to overwrite the base methods
sub info($){
    croak "ERROR: info method must be overwritten\n";
}
sub template ($){
    croak "ERROR: template method  must be overwritten\n";
}

sub run ($$){
    my $self = shift;
    # $s is the gedafe state
    my $s = shift;

    # import first get the ones from the form, and then add the ones
    # defined in the url if there are any.
    $self->{param}={};
    for (@{$self->template()}) {
	my ($field,$lable,$widget,$value,$test) = @$_;
	$self->{param}{$field} = GUI_WidgetRead($s, "field_$field",$widget);
	die "Pearl paramter $field='$self->{param}{$field}' does not match /^$test\$/".
	    "<BR>You can use the back button to get back at your form\n"
	    unless $self->{param}{$field} =~ /^$test$/;
    }
    # the rest is up to you :-)
    # you can access accessing parameters $self->{param}{$name}
}


# utility helpers
sub date_print ($) {
    my $time = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime($time);
    #  mktime(sec, min, hour, mday, mon, year, wday = 0, yday = 0, isdst = 0)
    
    for (shift){
	/month_first/ && do { $time = mktime 0,0,0,1,$mon,$year;
			      next; };
	/month_last/ && do { $time = mktime  0,0,0,0,$mon+1,$year;
			      next; };
    };
    
    return strftime('%Y-%m-%d',localtime($time));
}

sub format_desc {
    my $desc = shift;
    my $indent = shift;
    my $cols = shift;
    return "" unless $desc;
    $Text::Wrap::columns = $cols;
    $desc =~ s/^\s+//g; $desc =~ s/\s+$//g;
    $desc =~ s/\s+/ /g;
    
    $desc = wrap('','',$desc);
    my $indent_str = ' 'x$indent;
    $desc =~ s/\n/\n$indent_str/g;
    return $desc;
}

1;
# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#

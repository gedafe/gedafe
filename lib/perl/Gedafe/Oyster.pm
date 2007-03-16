package Gedafe::Oyster;

use Gedafe::Global qw{%g};
use strict;
use Carp;

# constructor
# please note that you get the gedafe state as 
# $self->{'s'}
sub new($;@){
    my $proto   = shift;
    my %params = @_;
    my $s = $g{'s'};
    my $sessiondata = {};
    my $class   = ref($proto) || $proto;
    my $self = {'s' => $s,'data'=>$sessiondata};
    bless $self, $class;
}

# get them to overwrite the base methods
sub info($){
    croak "ERROR: info method must be overwritten\n";
}

sub access($$){
    # second argument is the username. return true or false.
    # true means that user is allowed to use this oyster.
    croak "ERROR: access method must be overwritten\n";
    return 0;
}

sub validate ($$){
    #second argument is the state number for which we want to validate
    #you should return a hashreference that has keys for every
    #parameter that you don't agree with, and values with
    #helpfull messages
    croak "ERROR: validate method  must be overwritten\n";
}

sub template ($$){
    #second argument is the state number for which we want the template.
    #these templates are mostly the same as for the pearls.
    croak "ERROR: template method  must be overwritten\n";
}

sub run ($$){
    #second arg is the state number, this method should return html
    # for states with output and undef for others.
    croak "ERROR: run method must be overwritten\n";
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

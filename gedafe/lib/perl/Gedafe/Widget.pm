package Gedafe::Widget;

use strict;
use Carp;
use Exporter;
use Text::Wrap;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = qw();

# at the moment the class we create is empty

sub new($;@){
    my $proto   = shift;
    my %params = @_;
    my $class   = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
}

sub WidgetWrite($$$$){
    croak "ERROR: WriteWidget must be overwritten. \n";
}

sub WidgetRead ($$$$){
    croak "ERROR: ReadWidget method  must be overwritten\n";
}


1;

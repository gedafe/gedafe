package password;

use strict;
use Gedafe::Global qw(%g);
use Gedafe::Widget;
use vars qw(@ISA);
@ISA = qw(Gedafe::Widget);


sub WidgetWrite($$$$){
    my $self = shift;
    my ($s, $input_name, $value,$warg) = @_;
    my $html;
    my $dbh = $s->{dbh};
    my $q = $s->{cgi};
    $html = "<input type=\"password\" name=\"$input_name\" value=\"$value\">";
    return $html;
}


sub WidgetRead($$$$){
    my $self = shift;
    my ($s, $input_name, $value,$warg) = @_;
    my $dbh = $s->{dbh};
    my $q = $s->{cgi};
    return $value;
}

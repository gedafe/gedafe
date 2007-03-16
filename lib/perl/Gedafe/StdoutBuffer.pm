# (c) Freek Zindel 2004
# released under the GNU General Public License
# 
# StdoutBuffer, a simple object to tie to streams.
#
# Usage:
# my $output;
# tie *STDOUT,"Gedafe::StdoutBuffer",\$output;
# (... do some printing here ...)
# untie *STDOUT;
# 
# all the stuff you printed has been appended to $output.


package Gedafe::StdoutBuffer;


sub TIEHANDLE($){
	my $class = shift;
	my $target = shift;
	bless {target=>$target}, $class;
}

sub PRINT {
    my $self = shift;
    ${$self->{target}}.= join '',@_;
}

sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    ${$self->{target}}.= sprintf($fmt, @_);
}

sub CLOSE {
    my $self = shift;
    return close $self;
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

# vi: tw=0 sw=8

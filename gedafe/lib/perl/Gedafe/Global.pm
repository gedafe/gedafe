# Gedafe, the Generic Database Frontend
# copyright (c) 2000, ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe

# released under the GNU General Public License

package Gedafe::Global;

use strict;

use vars qw(@ISA @EXPORT_OK %g %s);

# %g  -> global data
# %u  -> user data

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(%g *u Global_InitUser);


sub Global_InitUser($)
{
	my $user = shift;
	defined $user or $user = '_default';
	defined $g{user_data}{$user} or $g{user_data}{$user}={};
	*u = $g{user_data}{$user};
}

1;

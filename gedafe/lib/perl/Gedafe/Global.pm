# Gedafe, the Generic Database Frontend
# copyright (c) 2000-2002 ETH Zurich
# see http://isg.ee.ethz.ch/tools/gedafe/

# released under the GNU General Public License

package Gedafe::Global;

use strict;

use vars qw(@ISA @EXPORT_OK %g);

# %g  -> global data

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(%g);

1;

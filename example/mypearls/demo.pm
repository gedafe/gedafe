#
# Sample Gedafe Pearl
# Pearls are normally created as decendants of
# the Gedafe::Pearl Module
#
#
package demo;

use strict;
use Gedafe::Pearl qw(format_desc date_print);
use POSIX qw(strftime);
use vars qw(@ISA);
@ISA = qw(Gedafe::Pearl);

use DBIx::PearlReports;

# ok this is just to show how it is done
# if your new needs anything else
#sub new($;@){
#    my $proto = shift;
#    my $class = ref($proto) || $proto;
#    my $self = $class->SUPER::new(@_);
#    return $self;
#}

# Information about what this pearl will do
sub info($){
    #my $self = shift;
    return "Customers Orders","List all Orders of a particular customer";
}

# what information do I need to go into action
sub template ($){
    #my $self = shift;
    # return a list of lists with the following elements
    #    name        desc        widget
    return [['start', 'Start Date (YYYY-MM-DD)', 'text',
	      date_print('month_first'),'\d+-\d+-\d+'],
	    ['end', 'End Date (YYYY-MM-DD)', 'text',
	      date_print('month_last'),'\d+-\d+-\d+' ],
	    ['customer', 'Customer', 'idcombo(combo=customer_combo)','','\d+' ], 
	   ];
}

# check the PearlReports Documentation for details

sub run ($$){
    my $self = shift;
    my $s = shift;
    $self->SUPER::run($s);
    # run the parent ( this will set the params)
    my $p = $self->{param};
    my $rep = DBIx::PearlReports::new
       (
	-handle => $s->{dbh},
	-query => <<SQL,

SELECT customer_id,customer_name,
       orders_id,orders_date,orders_qty,
       product_hid,product_description
FROM customer,orders,product
WHERE orders_product=product_id
      AND customer_id = ?
      AND orders_customer = customer_id
      AND orders_date >= ?
      AND orders_date <= ?
ORDER BY customer_id,orders_date,orders_id

SQL
	-param => [ $p->{customer},$p->{start},$p->{end}]

       );

$rep->group
  ( -trigger => sub { $field{customer_id} },
    -head => sub { "Report for $field{customer_id} - $field{customer_name}\n".
                   "Date: $p->{start} - $p->{end}\n".
                   "-------------------------------------------------------------\n"},
    -foot => sub { "Total Items Shipped :".rpcnt($field{product_id})."\n" }
  );

$rep->group
  ( -trigger => sub { $field{orders_date} },
     -head => sub { "Orders for $field{orders_date}\n"}
  );

$rep->body
    ( -contents => sub {
         sprintf "  %10d %7d %8s  %s\n", 
	    $field{orders_id},
            $field{orders_qty},
	    $field{product_hid},
            $field{product_desc} } );

   return 'text/plain',
       join '', (map { defined $_ ? $_ : '' } $rep->makereport);
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

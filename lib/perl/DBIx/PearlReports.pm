=pod

=head1 NAME

DBIx::PearlReports -- A Versatile Report Generator

=head1 SYNOPSIS

Using the SIMPLE mode

 use DBIx::PearlReports qw(:Simple);
 create (
    -datasource => 'dbi:Pg:dbname=database;host=hostname',
    -query => 'SELECT * FROM customers ORDER BY state, city;'
 );

or

 create (
    -datasource => 'dbi:Pg:dbname=database;host=hostname',
    -query => 'SELECT * FROM customers ORDER BY state, city WHERE name = ? AND age = ?',
    -param => ['Tobi',34],
 );

 group (
    -trigger => sub { $filed{state} },
    -head => sub { "State: $field{state}\n" },
    -foot => sub { "Average Age for $field{state}".rpavg($field{age}) }
 );

 group (
    -trigger => sub { $field{city} },
    -head => sub { "City: $field{city} (".rpcnt($field{name}.")\n" },
    -foot => sub { "Total Customers in Customers in ".
                   "$field{city}: ".rpcnt($field{name})."\n" }
 );

 body (
     -contents => sub { "$field{firstname} $field{lastname} $field{age}\n" }
 );

 print makereport;

PearlReports can also be used in an Object Oriented Context:

 #!/usr/sepp/bin/perl-5.8.0
 use lib qw( /usr/pack/postgresql-7.3.2-ds/lib/site_perl /usr/isgtc/lib/perl);
 use DBIx::PearlReports;
 $r = DBIx::PearlReports::create ( ... );
 $r->group( ... );
 $r->body( ... )
 print $r->makereport;


=head1 DESCRIPTION

B<PearlReports> is a system for pulling information from an SQL database and
produce Reports from this information. B<PearlReports> provides a very
flexible system for creating reports based on SQL queries

While it is sufficient to use the simple statements provided by
PearlReports to create your reports, the full power of perl is only a
keystroke away.

Creating a Report using the PearlReports involves writing a short perl
script which first loads the PearlReports module:

 #!/usr/bin/perl
 use DBIx::PearlReports qw(:SIMPLE);

Then you call the B<create> function to create a new report:

 create (
     -username  => 'myname',
     -datasource => 'dbi:Pg:dbname=customers',
     -query => 'SELECT * from customers ORDER by state,city'
 );

When creating a report you have to define username and password for
the database you want to access. Because different people may use the
report. If you do not mention either the B<-username> or B<-password>
arguments, the module will ask you to supply one at run time.

The B<-datasource> argument defines which
database this report is going to use. Check the DBI/DBD documentation
for the syntax apropriate for your Database. In the example above we
are accessing a PostgreSQL database called I<customers> which runs on
the local host.  The B<-query> argument of the create function defines
the data we want to use in our report.

A central element of PearlReports is the ability to work with groups of
records. In this example the report contains two nested groups. Note that
the data

must arive from the database in an order which is comatible with the
required groups. (Check the ORDER BY cause above).

 group
  ( -trigger => sub { $field{state} },
    -head => sub { "Customers from $field{state}\n" },
    -foot => sub { "Avg Age for $field{state} Customer:".
                    rpavg($field{age})."\n\n"  } );

 group
  ( -trigger => sub { $field{zip} },
    -head => sub { "Customers from $field{town}\n" },
    -foot => sub { "Min Age in $field{town}:".
                   rpmin($field{age})."\n" } );


Each group definition requires a trigger and either a header or a
footer or both. Each argument of the group definition is a little perl
function definition. The Trigger function gets called for each record
in the query. Whenever the value returned from the
function changes the group iterates. Each iteration of a group is
enclosed by the apropriate header and footer.

The B<$field{xxx}> variables refer to the columns of the query.
The footer and the header (!) can contain agregation functions
(rpmin, rpmax, rpbig, rpsmall, rpsum, rpavg). See the section below

Finally the actual data can get printed.

 body
  ( -contents => sub { "$field{firstname} $field{lastname} $field{age}\n" } );

The body function will get called for each row in the database and its
return value will be printed into the report.

When groups and body are set up you can create the actual report by
executing:

 print makereport;

When you want to make a new report using the existion database connection
for another report, you can reset it with the command

 reset;

=head2 METHODS

All functions provided by PearlReports expect named arguments.

=head3 create or new

Defines the data the report should be based on. This involves
configuring the parameters for accessing the database server as well
as defining the query string.

If you are working with the OO interface you can use b<new> instead
of create to be more in line with established naming conventions.

=over

=item -username

the username for the database. If this option is not set, PearlReports will
prompt for a username.

=item -password

the password. If this option is not supplied PearlReports will prompt for a
password.

=item -datasource

the DBI connect string. Check the DBI/DBD manpage for the syntax apropriate
for your database.

=item -handle

instead of the previous 3 arguments you can also give PearlReports an
existing database handle to use.

=item -query

A SELECT query

=item -param

If you use '?' placeholders in the query, you can supply contents for them
using the reference to an arry holding the relevant data.

=back


=head2 group

The 'salt' of most reports is that some grouping structure exists. The
records in the report get collected into groups of records which bear
some common feature. Each group can have a header and a footer.

=over

=item -trigger

Is a pointer to a anonymous function. The function gets called for
each row in the result of the query. Whenever the return value from
this function changes the group goes into its next iteration.  There
are other events which can cause a new iteration: A higher order group
goes into another iteration or the last record from the query has been
consumed.

=item -head and -foot

After each iteration, the anonymouse functions pointed to by the head
and foot options get executed. The return values from the functions
are used as header and footer for the material inside the group.

=back

=head3 body

The inner most 'group' of the report does have neither foot nor head,
it has just a body which gets printed for every row in the query result.

=over

=item -contents

Stores a pointer to an anonymous function which gets executed for each
record returned by the query.

=back

=head3 makereport

returns an array containing the report ...

=head3 reset

clears the group and body data from the report. This can be used to run a
second report of the same database connection without reconnecting.

=head2 AGGREGATE FUNCTIONS

=head3 rpsum

Builds the sum of all the values its argument takes during the
traversal of the records in the current group iteration.

=head3 rpmin, rpmax

Finds the min and max values in a group iteration.

=head3 rpsmall, rpbig

Finds the first and last value when sorting alphabetically.

=head3 rpcnt

Count the rows in the current group iteration.

=head3 rpavg

The same as above only that the average gets calculated.

=head2 HOW TO WRITE NEW AGGREGATE FUNCTIONS

If you want to write your own aggregat functions. Follow the examples
below. Note that the first two lines of each function are
mandatory. The structure you store in the $arr is up to you.

 use PearlReports qw(:MyAgg);

 sub mycnt ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr++
    return $$arr;
 }

 sub myavg ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr->{sum} += $_[0];
    $$arr->{cnt}++;
    return $$arr->{sum} / $$arr->{cnt};
 }

If you create cool aggregate functions please drop me a line.

=head1 HISTORY

 2002-06-12 to Initial ISGTC release
 2003-07-16 to Added -handle option
 2003-07-29 to Added -param option

=head1 AUTHOR

S<Tobias Oetiker E<lt>oetiker@ee.ethz.chE<gt>>

=head1 COPYRIGHT

(C) 2000 by ETH Zurich

=head1 LICENSE

This code is made available under the GNU General Public License
Version 2.0 or later (see www.gnu.org)

=cut

package DBIx::PearlReports;

use Carp;
use strict;
use DBI;
use vars qw(%field $VERSION @EXPORT %EXPORT_TAGS @ISA);  # it's a package global
require Exporter;
$VERSION=1.0;

@ISA = qw(Exporter);
@EXPORT = qw(%field rpmin rpmax rpsum rpcnt rpavg rpsmall rpbig);
%EXPORT_TAGS = ('Simple' => [qw(create group body makereport reset)],
	        'MyAgg' => [qw($aggmem)]);

#prototypes
sub argcheck ($$$$);
sub autoself (@);
sub ask ($;$);

my $DefaultSelf;
#implementation

sub create {
    my %args = @_;
    my $self = {};
    bless $self;
    $DefaultSelf = $self; # set default for SIMPLE use
    if (not exists $args{-handle}){
            argcheck "create", \%args, [qw(-datasource -query)],[qw(-username -password -param)];
            $args{-username} = ask('Username:') unless defined $args{-username};
            $args{-password} = ask('password:',1) unless defined $args{-password};
    } else {
            argcheck "create", \%args, [qw(-handle -query)],[(-param)];
            $self->{dbh} = $args{-handle};
    }
    $self->{NEW} = \%args;
    return $self;
}

sub new {
    return create @_;
}

sub group {
    my ($self, %args) = autoself @_;
    argcheck "group", \%args, [qw(-trigger)],[qw(-head -foot)];
    $args{aggmem} = {}; # this will hold info from the groups aggmem calls
    push @{$self->{GROUPS}}, \%args;
}

sub body {
    my ($self, %args) = autoself @_;
    argcheck "body", \%args, [qw(-contents)],[];
    croak "there can be only one body in a report"
      if exists $self->{BODY}->{-contents};
    $self->{BODY}->{-contents} = $args{-contents};
}

# Global variable providing static, group local memmory 
# for all agregat functions.
my $aggmem;

# reset GROUPS and BODY asignement of report;

sub reset {
   my ($self, %args) = autoself @_;
   $self->{GROUPS} = [];
   $self->{BODY} = undef;
}

sub makereport {
    my ($self, %args) = autoself @_;
    # open the database and get the data
    if ( not defined $self->{dbh} ) {
            $self->{dbh} = DBI->connect( $self->{NEW}->{-datasource},
	        			 $self->{NEW}->{-username},
		        		 $self->{NEW}->{-password}
			               ) or croak $DBI::errstr;
    }

    $self->{sth} = $self->{dbh}->prepare_cached($self->{NEW}->{-query})
      or croak $self->{dbh}->errstr;

    if ($self->{NEW}->{-param}){
      my @param = @{$self->{NEW}->{-param}};
      for(1..scalar(@param)){
	#count from 1 to number_of_parameters including.
	#sql parameters start at 1. 
	$self->{sth}->bind_param($_,shift @param);
      }
    }

    $self->{sth}->execute() or croak $self->{dbh}->errstr."\n\nQuery: $self->{NEW}->{-query}";

    my @report; #this array holds the report

    # loop through query response
    while (my $row = $self->{sth}->fetchrow_hashref) {
	%field = %$row;
	my $cascade;
        my @headstack;
        my @footstack;
	foreach my $group (@{$self->{GROUPS}}) {
	    # $aggmem is the temporery storage are for all aggmem functions
	    # called within the current group

	    $aggmem = $group->{aggmem}; # asign aggmem pointer

	    #evaluate current value of the trigger functions
	    my $trigval = &{$group->{-trigger}};
	    if (defined $cascade or not defined $group->{trigval}
		or $trigval ne $group->{trigval}){
		$group->{trigval} = $trigval;

		# if the trigger fired, fall through all the lower groups
		# they have to rotate too
		$cascade = 1;

		$aggmem->{array} = []; # clear aggmem storage

		unshift @footstack, $group->{footsave} 
                        if defined $group->{-foot};
		# OK, this is a bit of voodo. Because I want that you can use agregate
                # functions in the head section we store a pointer to a string
		# and push it into the report. For each record in the group this
                # string gets updated (through the pointer)
		my $string = "";		
		push @headstack, \$string;
		$group->{headref} = \$string;
	    }
	    $aggmem->{counter} = 0; # reset aggmem storage pointer
   	    ${$group->{headref}} = &{$group->{-head}} if exists $group->{-head};
	    $group->{footsave} = &{$group->{-foot}} if exists $group->{-foot};
	}
	push @report, @footstack;
	push @report, @headstack;
	push @report, &{$self->{BODY}->{-contents}} if defined $self->{BODY};

    }
    my @footstack;
    foreach my $group (@{$self->{GROUPS}}) {
	unshift @footstack , $group->{footsave} 
                if defined $group->{-foot};
    } 
    push @report, @footstack;
    $self->{sth}->finish;
    # $self->{dbh}->disconnect;  
    # now we resolve all the -head pointers left in the report stack    
    # and we only ship values back which evaluated to a defined value
    return grep {defined $_} map {ref $_ eq 'SCALAR' ? ${$_} : $_ } @report;
}

##### Agregat functions ##############
# agregat functions can be used within the -foot and -head
# funtions. Before each call to either of these functions
# a persistent @stor and a to 0 initialized $count variable
# is made available with local

sub rpsum ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr += $_[0];
    return $$arr;
}

sub rpmin ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
   $$arr= $_[0]
      if not defined $$arr
	or $$arr > $_[0];
    return $$arr;
}

sub rpmax ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr= $_[0]
      if not defined $$arr
	or $$arr < $_[0];
    return $$arr;
}

sub rpsmall ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr= $_[0]
      if not defined $$arr
	or $$arr gt $_[0];
    return $$arr;
}

sub rpbig ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr= $_[0]
      if not defined $$arr
	or $$arr lt $_[0];
    return $$arr;
}

sub rpcnt ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr++;
    return $$arr;
}

sub rpavg ($) {
    my $cnt = $aggmem->{counter}++;
    my $arr = \$aggmem->{array}->[$cnt];
    $$arr->{sum} += $_[0];
    $$arr->{cnt}++;
    return $$arr->{sum} / $$arr->{cnt};
}

##### Internal Helpers #################

sub ask ($;$) {
    print STDERR $_[0]," ";
    system "stty -echo"
      if defined $_[1];
    chomp(my $answer = <>);
    if (defined $_[1]){
	system "stty echo";
	print "\n";
    }
    return $answer;
}

sub argcheck ($$$$) {
    my $func = shift;
    my $hash = shift;
    my $required = shift;
    my $optional = shift;
    foreach my $arg (@{$required}) {
	croak "$func expected $arg argument" 
	  unless exists $hash->{$arg};
    }
    foreach my $arg (keys %{$hash}) {
	croak "$func does not support $arg arguments"
	  unless grep /^$arg$/, @{$required}, @{$optional};
    }
}

sub autoself (@){
    return @_ if
      ref($_[0]) eq 'DBIx::PearlReports';
    return \$DefaultSelf, @_;
}

1;

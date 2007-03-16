package demoyster;
use Gedafe::Oyster;

use vars qw(@ISA);
@ISA = qw(Gedafe::Oyster);


# Information about what this oyster will do
sub info($){
    #my $self = shift;
    return "Lingo Derivative","Example game to show the power of plugins";
}

# the access method allows people to use this plugin.
sub access($$){
    my $self = shift;
    my $username = shift;
    #I trust all users with this plugin: so return 1;
    #otherwise make your own judgement based on the 
    #username. 0 means: no access
    return 1;
}

# example constructor
#
# The global information from your plugin can go in here.
# please note that this can/will be called for every
# page you generate. This means that global
# values are not a communication mechanism between states.
# for that purpose there is the {data} hash. This
# gets saved between states.
# 
sub new($;@){
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new(@_);

    #perhaps your super game should fetch a word from
    #a database.
    $self->{data}{secret} = 'clamfish';
    $self->{data}{known} = $self->match(undef);
    return $self;
}

# what information do I need to go into action
#
# templates are the basis of the gui for a state.
# you get a reference to yourself and the number
# of the current state and it is up to you to
# make a sensible gui for the user based on that.
# the gui work mostly like the one used for pearls.
#
sub template ($$){
    my $self = shift;
    my $state = shift;

    
    # return a list of lists with the following elements
    #    name        desc        widget      value
    return [['play',
	     'Would you like to play a game of Lingo Derivative?','checkbox','1'],
	    ] if($state==1);
    return undef if($state==2 and !$self->{param}{play});
    return undef if($state>2 and $self->{param}{guess} eq $self->{data}{secret});
    return [['guess','what is your guess?','text',''],
	    ];
    
}

#
# The run method can be used to do stuff.
# You are garantied  to get validated input in $self->{param}
# and the state for which that is valid.
#
# The output from your run method will be buffered and saved
# this way we can show it again when users make a mistake.
# You can be sure that run will only be called once.
#

sub run ($$){
    my $self = shift;
    my $state = shift;
    if($state==2){
	if($self->{param}{play}){
	    print "<center><h2>Ok, let's go!</h2></center>\n";
	}else{
	    print "<center><h2>Hmm, ok that's fine with me.</h2></center>\n";
	    return;
	}
    }
    if($state>=2){
	my $guess = $self->{param}{guess} ||'';
	if($guess eq $self->{data}{secret}){
	    print "<center><h1>$guess, You won!</h1></center>\n";
	}else{
	    my $times = $state-1;
	    my $newmatch = $self->match($guess);
	    print "<center>Your guess was: $guess</center>\n";
	    print "<center><h2>$newmatch</h2></center>\n";
	    print "<center>please try (again) for the $times-th time.</center>\n";
	}
    }
}

#
# The validate method allows you to correct the data
# from the user. For a given state you have to
# report errors in the $self->{param} hash.
# If you find something you can put a helpfull
# message in the $errors hash at the 
# key of the offending parameter.
#
#

sub validate($$){
    my $self = shift;
    my $state = shift;
    my $errors = {};
    if($state>1){
	$errors->{guess} = 
	    "You know that word doesn't fit $self->{data}{known}!"
	    if($self->{param}{guess} !~ /$self->{data}{known}/);
    }
    return $errors;
}

# 
# this is just a utility function that 
# finds the match for two words in the lingo example.
#
sub match($$){
    my $self = shift;
    my $guessword = shift;
    if(!$guessword){
	$guessword = $self->{data}{secret};
	$guessword =~ s/\w/ /g;
    }
    my @secret = split(//,$self->{data}{secret});
    my @guess = split(//,$guessword);
    my $retval='';
    for(0..length($self->{data}{secret})-1){
	$retval .=( $guess[$_] and ($secret[$_] eq $guess[$_])) 
	    ? $secret[$_] : '.';
    }
    $self->{data}{known} = $retval;
    return $retval;
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

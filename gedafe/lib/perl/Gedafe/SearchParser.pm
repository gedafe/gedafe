package Gedafe::SearchParser;
use Parse::RecDescent;

{ my $ERRORS;


package Parse::RecDescent::Gedafe::SearchParser;
use strict;
use vars qw($skip $AUTOLOAD  );
$skip = '\s*';
 
  my $debug = 0;
  my $comment = <<'end';


	This file was automaticaly created by Parse::RecDescent 
	from the grammar file 'SearchGrammar' in the gedafe/src directory.
	Any modifications to the parser should be made in there.
	To compile a new parser from that grammar use this statement:
	
	perl -MParse::RecDescent - SearchGrammar Gedafe::SearchParser
	
	and then move te created SearchParser.pm to the apropriate 
	gedafe lib/perl/Gedafe directory.

	For further querstions try freek@zindel.nl 
	or gedafe-dev@list.ee.ethz.ch


end
;


{
local $SIG{__WARN__} = sub {0};
# PRETEND TO BE IN Parse::RecDescent NAMESPACE
*Parse::RecDescent::Gedafe::SearchParser::AUTOLOAD	= sub
{
	no strict 'refs';
	$AUTOLOAD =~ s/^Parse::RecDescent::Gedafe::SearchParser/Parse::RecDescent/;
	goto &{$AUTOLOAD};
}
}

push @Parse::RecDescent::Gedafe::SearchParser::ISA, 'Parse::RecDescent';
# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::searchquery
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"searchquery"};
	
	Parse::RecDescent::_trace(q{Trying rule: [searchquery]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [expression]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{searchquery});
		%item = (__RULE__ => q{searchquery});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [expression]},
				  Parse::RecDescent::_tracefirst($text),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::expression($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [expression]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{searchquery},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [expression]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{expression}} = $_tok;
		push @item, $_tok;
		
		}


		Parse::RecDescent::_trace(q{>>Matched production: [expression]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [rvalue etail eofile]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{searchquery});
		%item = (__RULE__ => q{searchquery});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [rvalue]},
				  Parse::RecDescent::_tracefirst($text),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rvalue($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rvalue]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{searchquery},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rvalue]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rvalue}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [etail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{etail})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Gedafe::SearchParser::etail, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [etail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{searchquery},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [etail]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{etail(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [eofile]},
				  Parse::RecDescent::_tracefirst($text),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{eofile})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::eofile($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [eofile]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{searchquery},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [eofile]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{eofile}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do { 
	$return = {type=>"expression",op=>'like',left=>'##ALL COLUMNS##',right=>$item[1]};
	my $right;
	for(@{$item[2]}){
	    $right = {type=>"expression",op=>$_->{op},left=>$_->{left},right=>$_->{right}};
	    $return = {type=>"exbinary",op=>$_->{binop},left=>$return,right=>$right};
	}
    };
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [rvalue etail eofile]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [where /.*/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{searchquery});
		%item = (__RULE__ => q{searchquery});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [where]},
				  Parse::RecDescent::_tracefirst($text),
				  q{searchquery},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::where($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [where]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{searchquery},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [where]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{where}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying terminal: [/.*/]}, Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{/.*/})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:.*)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    $return = {type=>'where',clause=>$item[2]};
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [where /.*/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{searchquery},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{searchquery},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{searchquery},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{searchquery},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::rstring
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"rstring"};
	
	Parse::RecDescent::_trace(q{Trying rule: [rstring]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{rstring},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[a-zA-Z0-9_@]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{rstring});
		%item = (__RULE__ => q{rstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[a-zA-Z0-9_@]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[a-zA-Z0-9_@]+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[a-zA-Z0-9_@]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/"([^"]+)"/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{rstring});
		%item = (__RULE__ => q{rstring});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/"([^"]+)"/]}, Parse::RecDescent::_tracefirst($text),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:"([^"]+)")//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = $1;};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/"([^"]+)"/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{rstring},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{rstring},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{rstring},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{rstring},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::not
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"not"};
	
	Parse::RecDescent::_trace(q{Trying rule: [not]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{not},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['NOT']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{not});
		%item = (__RULE__ => q{not});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['NOT']},
					  Parse::RecDescent::_tracefirst($text),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\ANOT//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['NOT']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['not']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{not});
		%item = (__RULE__ => q{not});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['not']},
					  Parse::RecDescent::_tracefirst($text),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Anot//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['not']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{not},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{not},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{not},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{not},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::binop
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"binop"};
	
	Parse::RecDescent::_trace(q{Trying rule: [binop]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{binop},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['and']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{binop});
		%item = (__RULE__ => q{binop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['and']},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aand//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['and']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['AND']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{binop});
		%item = (__RULE__ => q{binop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['AND']},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\AAND//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['AND']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['or']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{binop});
		%item = (__RULE__ => q{binop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['or']},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Aor//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['or']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['OR']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{binop});
		%item = (__RULE__ => q{binop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['OR']},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\AOR//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
     print "binop $item[1]\n" if($debug);
    $return =  $item[1];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['OR']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{binop},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{binop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{binop},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{binop},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::where
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"where"};
	
	Parse::RecDescent::_trace(q{Trying rule: [where]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{where},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['where']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{where});
		%item = (__RULE__ => q{where});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['where']},
					  Parse::RecDescent::_tracefirst($text),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Awhere//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['where']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['WHERE']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{where});
		%item = (__RULE__ => q{where});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['WHERE']},
					  Parse::RecDescent::_tracefirst($text),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\AWHERE//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['WHERE']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{where},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{where},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{where},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{where},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::eop
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"eop"};
	
	Parse::RecDescent::_trace(q{Trying rule: [eop]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{eop},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['==']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['==']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '=';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['==']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['>=']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['>=']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\>\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '>=';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['>=']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['<=']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[2];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['<=']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\<\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '<=';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['<=']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['~*']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[3];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['~*']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\~\*//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '~*';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['~*']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['=~']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[4];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['=~']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=\~//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '=~';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['=~']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['>']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[5];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['>']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\>//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '>';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['>']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['<']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[6];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['<']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\<//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = '<';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['<']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['=']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[7];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['=']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A\=//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = 'like';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['=']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: ['like']},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[8];
		$text = $_[1];
		my $_savetext;
		@item = (q{eop});
		%item = (__RULE__ => q{eop});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: ['like']},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\Alike//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(qq{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
							if defined $::RD_TRACE;
		push @item, $item{__STRING1__}=$&;
		

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {$return = 'like';};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: ['like']<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{eop},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{eop},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{eop},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{eop},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::rform
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"rform"};
	
	Parse::RecDescent::_trace(q{Trying rule: [rform]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{rform},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [not rstring]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{rform});
		%item = (__RULE__ => q{rform});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [not]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rform},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Gedafe::SearchParser::not, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [not]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rform},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [not]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{not(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [rstring]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rform},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{rstring})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rstring($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rstring]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rform},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rstring]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rstring}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    my $not = 0;
    if($item[1][0]){
	$not = 1;
    }
    $return = {not=>$not,value=>$item[2]};
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [not rstring]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{rform},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{rform},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{rform},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{rform},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::expression
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"expression"};
	
	Parse::RecDescent::_trace(q{Trying rule: [expression]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{expression},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [indicator eop rvalue etail]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{expression});
		%item = (__RULE__ => q{expression});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [indicator]},
				  Parse::RecDescent::_tracefirst($text),
				  q{expression},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::indicator($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [indicator]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{expression},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [indicator]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{indicator}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [eop]},
				  Parse::RecDescent::_tracefirst($text),
				  q{expression},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{eop})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::eop($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [eop]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{expression},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [eop]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{eop}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [rvalue]},
				  Parse::RecDescent::_tracefirst($text),
				  q{expression},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{rvalue})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rvalue($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rvalue]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{expression},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rvalue]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rvalue}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [etail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{expression},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{etail})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Gedafe::SearchParser::etail, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [etail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{expression},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [etail]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{etail(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    print "Expression $item[1] ,$item[2]\n" if($debug);
    $return = {type=>'expression',op=>$item[2],left=>$item[1],right=>$item[3]};
    my $right;
    for(@{$item[4]}){
	$right = {type=>"expression",op=>$_->{op},left=>$_->{left},right=>$_->{right}};
	$return = {type=>"exbinary",op=>$_->{binop},left=>$return,right=>$right};
    }
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [indicator eop rvalue etail]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{expression},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{expression},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{expression},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{expression},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::rvalue
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"rvalue"};
	
	Parse::RecDescent::_trace(q{Trying rule: [rvalue]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{rvalue},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [rform rtail]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{rvalue});
		%item = (__RULE__ => q{rvalue});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [rform]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rvalue},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rform($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rform]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rvalue},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rform]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rform}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying repeated subrule: [rtail]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rvalue},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{rtail})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Gedafe::SearchParser::rtail, 0, 100000000, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [rtail]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rvalue},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [rtail]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rtail(s?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    print "$item[0]\n" if($debug);
    $return =  {type=>"rvalue",form=>$item[1]};
    my $right;
    for(@{$item[2]}){
	    $right = {type=>'rvalue', form=>$_->{form}};
	    $return = {type=>"binary",op=>$_->{op},left=>$return,right=>$right};
    }
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [rform rtail]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{rvalue},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{rvalue},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{rvalue},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{rvalue},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::rtail
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"rtail"};
	
	Parse::RecDescent::_trace(q{Trying rule: [rtail]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{rtail},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [binop rform eop]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{rtail});
		%item = (__RULE__ => q{rtail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying repeated subrule: [binop]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rtail},
				  $tracelevel)
					if defined $::RD_TRACE;
		$expectation->is(q{})->at($text);
		
		unless (defined ($_tok = $thisparser->_parserepeat($text, \&Parse::RecDescent::Gedafe::SearchParser::binop, 0, 1, $_noactions,$expectation,undef))) 
		{
			Parse::RecDescent::_trace(q{<<Didn't match repeated subrule: [binop]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rtail},
						  $tracelevel)
							if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched repeated subrule: [binop]<< (}
					. @$_tok . q{ times)},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{binop(?)}} = $_tok;
		push @item, $_tok;
		


		Parse::RecDescent::_trace(q{Trying subrule: [rform]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rtail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{rform})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rform($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rform]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rtail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rform]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rform}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [eop]},
				  Parse::RecDescent::_tracefirst($text),
				  q{rtail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{eop})->at($text);
		$_savetext = $text;if (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::eop($thisparser,$text,$repeating,1,sub { \@arg })))
		{
			$text = $_savetext;
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [eop]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{rtail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [eop]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{eop}} = $_tok;
		push @item, $_tok;
		$text = $_savetext;
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    print "$item[0]\n" if($debug);

    #print "rtail $item[1] $item[2]\n";
    my $operator = "or";
    if($item[1][0]){
	$operator = $item[1][0];
    }
    $return = {type=>'rtail',op=>$operator,form=>$item[2]};
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [binop rform eop]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{rtail},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{rtail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{rtail},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{rtail},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::indicator
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"indicator"};
	
	Parse::RecDescent::_trace(q{Trying rule: [indicator]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{indicator},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[0-9]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{indicator});
		%item = (__RULE__ => q{indicator});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[0-9]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[0-9]+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[0-9]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/[a-zA-Z0-9_]+/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[1];
		$text = $_[1];
		my $_savetext;
		@item = (q{indicator});
		%item = (__RULE__ => q{indicator});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/[a-zA-Z0-9_]+/]}, Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:[a-zA-Z0-9_]+)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/[a-zA-Z0-9_]+/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{indicator},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{indicator},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{indicator},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{indicator},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::eofile
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"eofile"};
	
	Parse::RecDescent::_trace(q{Trying rule: [eofile]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{eofile},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [/^\\z/]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{eofile},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{eofile});
		%item = (__RULE__ => q{eofile});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying terminal: [/^\\z/]}, Parse::RecDescent::_tracefirst($text),
					  q{eofile},
					  $tracelevel)
						if defined $::RD_TRACE;
		$lastsep = "";
		$expectation->is(q{})->at($text);
		

		unless ($text =~ s/\A($skip)/$lastsep=$1 and ""/e and   $text =~ s/\A(?:^\z)//)
		{
			
			$expectation->failed();
			Parse::RecDescent::_trace(q{<<Didn't match terminal>>},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;

			last;
		}
		Parse::RecDescent::_trace(q{>>Matched terminal<< (return value: [}
						. $& . q{])},
						  Parse::RecDescent::_tracefirst($text))
					if defined $::RD_TRACE;
		push @item, $item{__PATTERN1__}=$&;
		


		Parse::RecDescent::_trace(q{>>Matched production: [/^\\z/]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{eofile},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{eofile},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{eofile},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{eofile},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{eofile},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::etail
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"etail"};
	
	Parse::RecDescent::_trace(q{Trying rule: [etail]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{etail},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [binop indicator eop rvalue]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{etail});
		%item = (__RULE__ => q{etail});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [binop]},
				  Parse::RecDescent::_tracefirst($text),
				  q{etail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::binop($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [binop]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{etail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [binop]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{binop}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [indicator]},
				  Parse::RecDescent::_tracefirst($text),
				  q{etail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{indicator})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::indicator($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [indicator]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{etail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [indicator]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{indicator}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [eop]},
				  Parse::RecDescent::_tracefirst($text),
				  q{etail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{eop})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::eop($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [eop]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{etail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [eop]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{eop}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying subrule: [rvalue]},
				  Parse::RecDescent::_tracefirst($text),
				  q{etail},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{rvalue})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::rvalue($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [rvalue]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{etail},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [rvalue]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{rvalue}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
    print "E-tail $item[1] ,$item[2], $item[3]\n" if($debug);
    $return = {type=>'etail',binop=>$item[1],op=>$item[3],left=>$item[2],right=>$item[4]}; 
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [binop indicator eop rvalue]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{etail},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{etail},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{etail},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{etail},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}

# ARGS ARE: ($parser, $text; $repeating, $_noactions, \@args)
sub Parse::RecDescent::Gedafe::SearchParser::startnode
{
	my $thisparser = $_[0];
	use vars q{$tracelevel};
	local $tracelevel = ($tracelevel||0)+1;
	$ERRORS = 0;
	my $thisrule = $thisparser->{"rules"}{"startnode"};
	
	Parse::RecDescent::_trace(q{Trying rule: [startnode]},
				  Parse::RecDescent::_tracefirst($_[1]),
				  q{startnode},
				  $tracelevel)
					if defined $::RD_TRACE;

	
	my $err_at = @{$thisparser->{errors}};

	my $score;
	my $score_return;
	my $_tok;
	my $return = undef;
	my $_matched=0;
	my $commit=0;
	my @item = ();
	my %item = ();
	my $repeating =  defined($_[2]) && $_[2];
	my $_noactions = defined($_[3]) && $_[3];
 	my @arg =        defined $_[4] ? @{ &{$_[4]} } : ();
	my %arg =        ($#arg & 01) ? @arg : (@arg, undef);
	my $text;
	my $lastsep="";
	my $expectation = new Parse::RecDescent::Expectation($thisrule->expected());
	$expectation->at($_[1]);
	
	my $thisline;
	tie $thisline, q{Parse::RecDescent::LineCounter}, \$text, $thisparser;

	

	while (!$_matched && !$commit)
	{
		
		Parse::RecDescent::_trace(q{Trying production: [searchquery]},
					  Parse::RecDescent::_tracefirst($_[1]),
					  q{startnode},
					  $tracelevel)
						if defined $::RD_TRACE;
		my $thisprod = $thisrule->{"prods"}[0];
		$text = $_[1];
		my $_savetext;
		@item = (q{startnode});
		%item = (__RULE__ => q{startnode});
		my $repcount = 0;


		Parse::RecDescent::_trace(q{Trying subrule: [searchquery]},
				  Parse::RecDescent::_tracefirst($text),
				  q{startnode},
				  $tracelevel)
					if defined $::RD_TRACE;
		if (1) { no strict qw{refs};
		$expectation->is(q{})->at($text);
		unless (defined ($_tok = Parse::RecDescent::Gedafe::SearchParser::searchquery($thisparser,$text,$repeating,$_noactions,sub { \@arg })))
		{
			
			Parse::RecDescent::_trace(q{<<Didn't match subrule: [searchquery]>>},
						  Parse::RecDescent::_tracefirst($text),
						  q{startnode},
						  $tracelevel)
							if defined $::RD_TRACE;
			$expectation->failed();
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched subrule: [searchquery]<< (return value: [}
					. $_tok . q{]},
					  
					  Parse::RecDescent::_tracefirst($text),
					  q{startnode},
					  $tracelevel)
						if defined $::RD_TRACE;
		$item{q{searchquery}} = $_tok;
		push @item, $_tok;
		
		}

		Parse::RecDescent::_trace(q{Trying action},
					  Parse::RecDescent::_tracefirst($text),
					  q{startnode},
					  $tracelevel)
						if defined $::RD_TRACE;
		

		$_tok = ($_noactions) ? 0 : do {
      print "startnode\n" if($debug);
      $return = $item[1];
};
		unless (defined $_tok)
		{
			Parse::RecDescent::_trace(q{<<Didn't match action>> (return value: [undef])})
					if defined $::RD_TRACE;
			last;
		}
		Parse::RecDescent::_trace(q{>>Matched action<< (return value: [}
					  . $_tok . q{])},
					  Parse::RecDescent::_tracefirst($text))
						if defined $::RD_TRACE;
		push @item, $_tok;
		$item{__ACTION1__}=$_tok;
		


		Parse::RecDescent::_trace(q{>>Matched production: [searchquery]<<},
					  Parse::RecDescent::_tracefirst($text),
					  q{startnode},
					  $tracelevel)
						if defined $::RD_TRACE;
		$_matched = 1;
		last;
	}


        unless ( $_matched || defined($return) || defined($score) )
	{
		

		$_[1] = $text;	# NOT SURE THIS IS NEEDED
		Parse::RecDescent::_trace(q{<<Didn't match rule>>},
					 Parse::RecDescent::_tracefirst($_[1]),
					 q{startnode},
					 $tracelevel)
					if defined $::RD_TRACE;
		return undef;
	}
	if (!defined($return) && defined($score))
	{
		Parse::RecDescent::_trace(q{>>Accepted scored production<<}, "",
					  q{startnode},
					  $tracelevel)
						if defined $::RD_TRACE;
		$return = $score_return;
	}
	splice @{$thisparser->{errors}}, $err_at;
	$return = $item[$#item] unless defined $return;
	if (defined $::RD_TRACE)
	{
		Parse::RecDescent::_trace(q{>>Matched rule<< (return value: [} .
					  $return . q{])}, "",
					  q{startnode},
					  $tracelevel);
		Parse::RecDescent::_trace(q{(consumed: [} .
					  Parse::RecDescent::_tracemax(substr($_[1],0,-length($text))) . q{])}, 
					  Parse::RecDescent::_tracefirst($text),
					  , q{startnode},
					  $tracelevel)
	}
	$_[1] = $text;
	return $return;
}
}
package Gedafe::SearchParser; sub new { my $self = bless( {
                 '_AUTOTREE' => undef,
                 'localvars' => '',
                 'startcode' => '',
                 '_check' => {
                               'thisoffset' => '',
                               'itempos' => '',
                               'prevoffset' => '',
                               'prevline' => '',
                               'prevcolumn' => '',
                               'thiscolumn' => ''
                             },
                 'namespace' => 'Parse::RecDescent::Gedafe::SearchParser',
                 '_AUTOACTION' => undef,
                 'rules' => {
                              'searchquery' => bless( {
                                                        'impcount' => '0',
                                                        'calls' => [
                                                                     'expression',
                                                                     'rvalue',
                                                                     'etail',
                                                                     'eofile',
                                                                     'where'
                                                                   ],
                                                        'opcount' => '0',
                                                        'prods' => [
                                                                     bless( {
                                                                              'number' => '0',
                                                                              'strcount' => '0',
                                                                              'dircount' => '0',
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => '0',
                                                                              'actcount' => '0',
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'expression',
                                                                                                    'matchrule' => '0',
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 28
                                                                                                  }, 'Parse::RecDescent::Subrule' )
                                                                                         ],
                                                                              'line' => undef
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => 1,
                                                                              'strcount' => '0',
                                                                              'dircount' => '0',
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => '0',
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'rvalue',
                                                                                                    'matchrule' => '0',
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 29
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'etail',
                                                                                                    'expected' => undef,
                                                                                                    'min' => '0',
                                                                                                    'argcode' => undef,
                                                                                                    'max' => 100000000,
                                                                                                    'matchrule' => '0',
                                                                                                    'repspec' => 's?',
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 29
                                                                                                  }, 'Parse::RecDescent::Repetition' ),
                                                                                           bless( {
                                                                                                    'subrule' => 'eofile',
                                                                                                    'matchrule' => '0',
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 29
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 30,
                                                                                                    'code' => '{ 
	$return = {type=>"expression",op=>\'like\',left=>\'##ALL COLUMNS##\',right=>$item[1]};
	my $right;
	for(@{$item[2]}){
	    $right = {type=>"expression",op=>$_->{op},left=>$_->{left},right=>$_->{right}};
	    $return = {type=>"exbinary",op=>$_->{binop},left=>$return,right=>$right};
	}
    }'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 29
                                                                            }, 'Parse::RecDescent::Production' ),
                                                                     bless( {
                                                                              'number' => 2,
                                                                              'strcount' => '0',
                                                                              'dircount' => '0',
                                                                              'uncommit' => undef,
                                                                              'error' => undef,
                                                                              'patcount' => 1,
                                                                              'actcount' => 1,
                                                                              'items' => [
                                                                                           bless( {
                                                                                                    'subrule' => 'where',
                                                                                                    'matchrule' => '0',
                                                                                                    'implicit' => undef,
                                                                                                    'argcode' => undef,
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 39
                                                                                                  }, 'Parse::RecDescent::Subrule' ),
                                                                                           bless( {
                                                                                                    'description' => '/.*/',
                                                                                                    'rdelim' => '/',
                                                                                                    'pattern' => '.*',
                                                                                                    'hashname' => '__PATTERN1__',
                                                                                                    'lookahead' => '0',
                                                                                                    'ldelim' => '/',
                                                                                                    'mod' => '',
                                                                                                    'line' => 39
                                                                                                  }, 'Parse::RecDescent::Token' ),
                                                                                           bless( {
                                                                                                    'hashname' => '__ACTION1__',
                                                                                                    'lookahead' => '0',
                                                                                                    'line' => 40,
                                                                                                    'code' => '{
    $return = {type=>\'where\',clause=>$item[2]};
}'
                                                                                                  }, 'Parse::RecDescent::Action' )
                                                                                         ],
                                                                              'line' => 39
                                                                            }, 'Parse::RecDescent::Production' )
                                                                   ],
                                                        'name' => 'searchquery',
                                                        'vars' => '',
                                                        'changed' => '0',
                                                        'line' => 28
                                                      }, 'Parse::RecDescent::Rule' ),
                              'rstring' => bless( {
                                                    'impcount' => '0',
                                                    'calls' => [],
                                                    'opcount' => '0',
                                                    'prods' => [
                                                                 bless( {
                                                                          'number' => '0',
                                                                          'strcount' => '0',
                                                                          'dircount' => '0',
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => '0',
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'description' => '/[a-zA-Z0-9_@]+/',
                                                                                                'rdelim' => '/',
                                                                                                'pattern' => '[a-zA-Z0-9_@]+',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'lookahead' => '0',
                                                                                                'ldelim' => '/',
                                                                                                'mod' => '',
                                                                                                'line' => 85
                                                                                              }, 'Parse::RecDescent::Token' )
                                                                                     ],
                                                                          'line' => undef
                                                                        }, 'Parse::RecDescent::Production' ),
                                                                 bless( {
                                                                          'number' => 1,
                                                                          'strcount' => '0',
                                                                          'dircount' => '0',
                                                                          'uncommit' => undef,
                                                                          'error' => undef,
                                                                          'patcount' => 1,
                                                                          'actcount' => 1,
                                                                          'items' => [
                                                                                       bless( {
                                                                                                'description' => '/"([^"]+)"/',
                                                                                                'rdelim' => '/',
                                                                                                'pattern' => '"([^"]+)"',
                                                                                                'hashname' => '__PATTERN1__',
                                                                                                'lookahead' => '0',
                                                                                                'ldelim' => '/',
                                                                                                'mod' => '',
                                                                                                'line' => 85
                                                                                              }, 'Parse::RecDescent::Token' ),
                                                                                       bless( {
                                                                                                'hashname' => '__ACTION1__',
                                                                                                'lookahead' => '0',
                                                                                                'line' => 85,
                                                                                                'code' => '{$return = $1;}'
                                                                                              }, 'Parse::RecDescent::Action' )
                                                                                     ],
                                                                          'line' => 85
                                                                        }, 'Parse::RecDescent::Production' )
                                                               ],
                                                    'name' => 'rstring',
                                                    'vars' => '',
                                                    'changed' => '0',
                                                    'line' => 85
                                                  }, 'Parse::RecDescent::Rule' ),
                              'not' => bless( {
                                                'impcount' => '0',
                                                'calls' => [],
                                                'opcount' => '0',
                                                'prods' => [
                                                             bless( {
                                                                      'number' => '0',
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => '0',
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => 'NOT',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'NOT\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 83
                                                                                          }, 'Parse::RecDescent::Literal' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 1,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => '0',
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => 'not',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'not\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 83
                                                                                          }, 'Parse::RecDescent::Literal' )
                                                                                 ],
                                                                      'line' => 83
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'not',
                                                'vars' => '',
                                                'changed' => '0',
                                                'line' => 83
                                              }, 'Parse::RecDescent::Rule' ),
                              'binop' => bless( {
                                                  'impcount' => '0',
                                                  'calls' => [],
                                                  'opcount' => '0',
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => '0',
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'and',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'and\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 68
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 1,
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => '0',
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'AND',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'AND\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 68
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => 68
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 2,
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => '0',
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'or',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'or\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 68
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => 68
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 3,
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'OR',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'OR\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 68
                                                                                            }, 'Parse::RecDescent::Literal' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 68,
                                                                                              'code' => '{
     print "binop $item[1]\\n" if($debug);
    $return =  $item[1];
}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => 68
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'binop',
                                                  'vars' => '',
                                                  'changed' => '0',
                                                  'line' => 68
                                                }, 'Parse::RecDescent::Rule' ),
                              'where' => bless( {
                                                  'impcount' => '0',
                                                  'calls' => [],
                                                  'opcount' => '0',
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => '0',
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'where',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'where\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 45
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' ),
                                                               bless( {
                                                                        'number' => 1,
                                                                        'strcount' => 1,
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => '0',
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'pattern' => 'WHERE',
                                                                                              'hashname' => '__STRING1__',
                                                                                              'description' => '\'WHERE\'',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 45
                                                                                            }, 'Parse::RecDescent::Literal' )
                                                                                   ],
                                                                        'line' => 45
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'where',
                                                  'vars' => '',
                                                  'changed' => '0',
                                                  'line' => 45
                                                }, 'Parse::RecDescent::Rule' ),
                              'eop' => bless( {
                                                'impcount' => '0',
                                                'calls' => [],
                                                'opcount' => '0',
                                                'prods' => [
                                                             bless( {
                                                                      'number' => '0',
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '==',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'==\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 105
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 105,
                                                                                            'code' => '{$return = \'=\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => undef
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 1,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '>=',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'>=\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 106
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 106,
                                                                                            'code' => '{$return = \'>=\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 106
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 2,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '<=',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'<=\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 107
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 107,
                                                                                            'code' => '{$return = \'<=\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 107
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 3,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '~*',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'~*\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 108
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 108,
                                                                                            'code' => '{$return = \'~*\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 108
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 4,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '=~',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'=~\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 109
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 109,
                                                                                            'code' => '{$return = \'=~\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 109
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 5,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '>',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'>\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 110
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 110,
                                                                                            'code' => '{$return = \'>\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 110
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 6,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '<',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'<\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 111
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 111,
                                                                                            'code' => '{$return = \'<\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 111
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 7,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => '=',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'=\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 112
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 112,
                                                                                            'code' => '{$return = \'like\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 112
                                                                    }, 'Parse::RecDescent::Production' ),
                                                             bless( {
                                                                      'number' => 8,
                                                                      'strcount' => 1,
                                                                      'dircount' => '0',
                                                                      'uncommit' => undef,
                                                                      'error' => undef,
                                                                      'patcount' => '0',
                                                                      'actcount' => 1,
                                                                      'items' => [
                                                                                   bless( {
                                                                                            'pattern' => 'like',
                                                                                            'hashname' => '__STRING1__',
                                                                                            'description' => '\'like\'',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 113
                                                                                          }, 'Parse::RecDescent::Literal' ),
                                                                                   bless( {
                                                                                            'hashname' => '__ACTION1__',
                                                                                            'lookahead' => '0',
                                                                                            'line' => 113,
                                                                                            'code' => '{$return = \'like\';}'
                                                                                          }, 'Parse::RecDescent::Action' )
                                                                                 ],
                                                                      'line' => 113
                                                                    }, 'Parse::RecDescent::Production' )
                                                           ],
                                                'name' => 'eop',
                                                'vars' => '',
                                                'changed' => '0',
                                                'line' => 105
                                              }, 'Parse::RecDescent::Rule' ),
                              'rform' => bless( {
                                                  'impcount' => '0',
                                                  'calls' => [
                                                               'not',
                                                               'rstring'
                                                             ],
                                                  'opcount' => '0',
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => '0',
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'not',
                                                                                              'expected' => undef,
                                                                                              'min' => '0',
                                                                                              'argcode' => undef,
                                                                                              'max' => 1,
                                                                                              'matchrule' => '0',
                                                                                              'repspec' => '?',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 73
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'subrule' => 'rstring',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 73
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 74,
                                                                                              'code' => '{
    my $not = 0;
    if($item[1][0]){
	$not = 1;
    }
    $return = {not=>$not,value=>$item[2]};
}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'rform',
                                                  'vars' => '',
                                                  'changed' => '0',
                                                  'line' => 73
                                                }, 'Parse::RecDescent::Rule' ),
                              'expression' => bless( {
                                                       'impcount' => '0',
                                                       'calls' => [
                                                                    'indicator',
                                                                    'eop',
                                                                    'rvalue',
                                                                    'etail'
                                                                  ],
                                                       'opcount' => '0',
                                                       'prods' => [
                                                                    bless( {
                                                                             'number' => '0',
                                                                             'strcount' => '0',
                                                                             'dircount' => '0',
                                                                             'uncommit' => undef,
                                                                             'error' => undef,
                                                                             'patcount' => '0',
                                                                             'actcount' => 1,
                                                                             'items' => [
                                                                                          bless( {
                                                                                                   'subrule' => 'indicator',
                                                                                                   'matchrule' => '0',
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => '0',
                                                                                                   'line' => 87
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'eop',
                                                                                                   'matchrule' => '0',
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => '0',
                                                                                                   'line' => 87
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'rvalue',
                                                                                                   'matchrule' => '0',
                                                                                                   'implicit' => undef,
                                                                                                   'argcode' => undef,
                                                                                                   'lookahead' => '0',
                                                                                                   'line' => 87
                                                                                                 }, 'Parse::RecDescent::Subrule' ),
                                                                                          bless( {
                                                                                                   'subrule' => 'etail',
                                                                                                   'expected' => undef,
                                                                                                   'min' => '0',
                                                                                                   'argcode' => undef,
                                                                                                   'max' => 100000000,
                                                                                                   'matchrule' => '0',
                                                                                                   'repspec' => 's?',
                                                                                                   'lookahead' => '0',
                                                                                                   'line' => 87
                                                                                                 }, 'Parse::RecDescent::Repetition' ),
                                                                                          bless( {
                                                                                                   'hashname' => '__ACTION1__',
                                                                                                   'lookahead' => '0',
                                                                                                   'line' => 87,
                                                                                                   'code' => '{
    print "Expression $item[1] ,$item[2]\\n" if($debug);
    $return = {type=>\'expression\',op=>$item[2],left=>$item[1],right=>$item[3]};
    my $right;
    for(@{$item[4]}){
	$right = {type=>"expression",op=>$_->{op},left=>$_->{left},right=>$_->{right}};
	$return = {type=>"exbinary",op=>$_->{binop},left=>$return,right=>$right};
    }
}'
                                                                                                 }, 'Parse::RecDescent::Action' )
                                                                                        ],
                                                                             'line' => undef
                                                                           }, 'Parse::RecDescent::Production' )
                                                                  ],
                                                       'name' => 'expression',
                                                       'vars' => '',
                                                       'changed' => '0',
                                                       'line' => 87
                                                     }, 'Parse::RecDescent::Rule' ),
                              'rvalue' => bless( {
                                                   'impcount' => '0',
                                                   'calls' => [
                                                                'rform',
                                                                'rtail'
                                                              ],
                                                   'opcount' => '0',
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => '0',
                                                                         'dircount' => '0',
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => '0',
                                                                         'actcount' => 1,
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'subrule' => 'rform',
                                                                                               'matchrule' => '0',
                                                                                               'implicit' => undef,
                                                                                               'argcode' => undef,
                                                                                               'lookahead' => '0',
                                                                                               'line' => 47
                                                                                             }, 'Parse::RecDescent::Subrule' ),
                                                                                      bless( {
                                                                                               'subrule' => 'rtail',
                                                                                               'expected' => undef,
                                                                                               'min' => '0',
                                                                                               'argcode' => undef,
                                                                                               'max' => 100000000,
                                                                                               'matchrule' => '0',
                                                                                               'repspec' => 's?',
                                                                                               'lookahead' => '0',
                                                                                               'line' => 47
                                                                                             }, 'Parse::RecDescent::Repetition' ),
                                                                                      bless( {
                                                                                               'hashname' => '__ACTION1__',
                                                                                               'lookahead' => '0',
                                                                                               'line' => 47,
                                                                                               'code' => '{
    print "$item[0]\\n" if($debug);
    $return =  {type=>"rvalue",form=>$item[1]};
    my $right;
    for(@{$item[2]}){
	    $right = {type=>\'rvalue\', form=>$_->{form}};
	    $return = {type=>"binary",op=>$_->{op},left=>$return,right=>$right};
    }
}'
                                                                                             }, 'Parse::RecDescent::Action' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'rvalue',
                                                   'vars' => '',
                                                   'changed' => '0',
                                                   'line' => 47
                                                 }, 'Parse::RecDescent::Rule' ),
                              'rtail' => bless( {
                                                  'impcount' => '0',
                                                  'calls' => [
                                                               'binop',
                                                               'rform',
                                                               'eop'
                                                             ],
                                                  'opcount' => '0',
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => '0',
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'binop',
                                                                                              'expected' => undef,
                                                                                              'min' => '0',
                                                                                              'argcode' => undef,
                                                                                              'max' => 1,
                                                                                              'matchrule' => '0',
                                                                                              'repspec' => '?',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 57
                                                                                            }, 'Parse::RecDescent::Repetition' ),
                                                                                     bless( {
                                                                                              'subrule' => 'rform',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 57
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'subrule' => 'eop',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => -1,
                                                                                              'line' => 57
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 57,
                                                                                              'code' => '{
    print "$item[0]\\n" if($debug);

    #print "rtail $item[1] $item[2]\\n";
    my $operator = "or";
    if($item[1][0]){
	$operator = $item[1][0];
    }
    $return = {type=>\'rtail\',op=>$operator,form=>$item[2]};
}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'rtail',
                                                  'vars' => '',
                                                  'changed' => '0',
                                                  'line' => 57
                                                }, 'Parse::RecDescent::Rule' ),
                              'indicator' => bless( {
                                                      'impcount' => '0',
                                                      'calls' => [],
                                                      'opcount' => '0',
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => '0',
                                                                            'dircount' => '0',
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 1,
                                                                            'actcount' => '0',
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/[0-9]+/',
                                                                                                  'rdelim' => '/',
                                                                                                  'pattern' => '[0-9]+',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'lookahead' => '0',
                                                                                                  'ldelim' => '/',
                                                                                                  'mod' => '',
                                                                                                  'line' => 103
                                                                                                }, 'Parse::RecDescent::Token' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' ),
                                                                   bless( {
                                                                            'number' => 1,
                                                                            'strcount' => '0',
                                                                            'dircount' => '0',
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => 1,
                                                                            'actcount' => '0',
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'description' => '/[a-zA-Z0-9_]+/',
                                                                                                  'rdelim' => '/',
                                                                                                  'pattern' => '[a-zA-Z0-9_]+',
                                                                                                  'hashname' => '__PATTERN1__',
                                                                                                  'lookahead' => '0',
                                                                                                  'ldelim' => '/',
                                                                                                  'mod' => '',
                                                                                                  'line' => 103
                                                                                                }, 'Parse::RecDescent::Token' )
                                                                                       ],
                                                                            'line' => 103
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'indicator',
                                                      'vars' => '',
                                                      'changed' => '0',
                                                      'line' => 103
                                                    }, 'Parse::RecDescent::Rule' ),
                              'eofile' => bless( {
                                                   'impcount' => '0',
                                                   'calls' => [],
                                                   'opcount' => '0',
                                                   'prods' => [
                                                                bless( {
                                                                         'number' => '0',
                                                                         'strcount' => '0',
                                                                         'dircount' => '0',
                                                                         'uncommit' => undef,
                                                                         'error' => undef,
                                                                         'patcount' => 1,
                                                                         'actcount' => '0',
                                                                         'items' => [
                                                                                      bless( {
                                                                                               'description' => '/^\\\\z/',
                                                                                               'rdelim' => '/',
                                                                                               'pattern' => '^\\z',
                                                                                               'hashname' => '__PATTERN1__',
                                                                                               'lookahead' => '0',
                                                                                               'ldelim' => '/',
                                                                                               'mod' => '',
                                                                                               'line' => 116
                                                                                             }, 'Parse::RecDescent::Token' )
                                                                                    ],
                                                                         'line' => undef
                                                                       }, 'Parse::RecDescent::Production' )
                                                              ],
                                                   'name' => 'eofile',
                                                   'vars' => '',
                                                   'changed' => '0',
                                                   'line' => 116
                                                 }, 'Parse::RecDescent::Rule' ),
                              'etail' => bless( {
                                                  'impcount' => '0',
                                                  'calls' => [
                                                               'binop',
                                                               'indicator',
                                                               'eop',
                                                               'rvalue'
                                                             ],
                                                  'opcount' => '0',
                                                  'prods' => [
                                                               bless( {
                                                                        'number' => '0',
                                                                        'strcount' => '0',
                                                                        'dircount' => '0',
                                                                        'uncommit' => undef,
                                                                        'error' => undef,
                                                                        'patcount' => '0',
                                                                        'actcount' => 1,
                                                                        'items' => [
                                                                                     bless( {
                                                                                              'subrule' => 'binop',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'subrule' => 'indicator',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'subrule' => 'eop',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'subrule' => 'rvalue',
                                                                                              'matchrule' => '0',
                                                                                              'implicit' => undef,
                                                                                              'argcode' => undef,
                                                                                              'lookahead' => '0',
                                                                                              'line' => 98
                                                                                            }, 'Parse::RecDescent::Subrule' ),
                                                                                     bless( {
                                                                                              'hashname' => '__ACTION1__',
                                                                                              'lookahead' => '0',
                                                                                              'line' => 98,
                                                                                              'code' => '{
    print "E-tail $item[1] ,$item[2], $item[3]\\n" if($debug);
    $return = {type=>\'etail\',binop=>$item[1],op=>$item[3],left=>$item[2],right=>$item[4]}; 
}'
                                                                                            }, 'Parse::RecDescent::Action' )
                                                                                   ],
                                                                        'line' => undef
                                                                      }, 'Parse::RecDescent::Production' )
                                                             ],
                                                  'name' => 'etail',
                                                  'vars' => '',
                                                  'changed' => '0',
                                                  'line' => 98
                                                }, 'Parse::RecDescent::Rule' ),
                              'startnode' => bless( {
                                                      'impcount' => '0',
                                                      'calls' => [
                                                                   'searchquery'
                                                                 ],
                                                      'opcount' => '0',
                                                      'prods' => [
                                                                   bless( {
                                                                            'number' => '0',
                                                                            'strcount' => '0',
                                                                            'dircount' => '0',
                                                                            'uncommit' => undef,
                                                                            'error' => undef,
                                                                            'patcount' => '0',
                                                                            'actcount' => 1,
                                                                            'items' => [
                                                                                         bless( {
                                                                                                  'subrule' => 'searchquery',
                                                                                                  'matchrule' => '0',
                                                                                                  'implicit' => undef,
                                                                                                  'argcode' => undef,
                                                                                                  'lookahead' => '0',
                                                                                                  'line' => 23
                                                                                                }, 'Parse::RecDescent::Subrule' ),
                                                                                         bless( {
                                                                                                  'hashname' => '__ACTION1__',
                                                                                                  'lookahead' => '0',
                                                                                                  'line' => 23,
                                                                                                  'code' => '{
      print "startnode\\n" if($debug);
      $return = $item[1];
}'
                                                                                                }, 'Parse::RecDescent::Action' )
                                                                                       ],
                                                                            'line' => undef
                                                                          }, 'Parse::RecDescent::Production' )
                                                                 ],
                                                      'name' => 'startnode',
                                                      'vars' => '',
                                                      'changed' => '0',
                                                      'line' => 23
                                                    }, 'Parse::RecDescent::Rule' )
                            }
               }, 'Parse::RecDescent' );
}
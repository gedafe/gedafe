package Gedafe::Search;

use Gedafe::Global qw{%g};
use strict;
require Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(Search_available
		Search_parse
);


my $parser_available;

BEGIN {
	eval {
	    # load modules necessary for parsing user input to
	    # the search query builder
	    # if Parse::RecDescent is not available we fall back
	    # to the traditional search mechanism
	    
	    if(require Parse::RecDescent){
		require Gedafe::SearchParser;
		$parser_available = 1;
	    }
	    
	};
}

sub Search_available(){
    return $parser_available;
}

sub Search_parse($$){
    my $view = shift;
    my $question = shift;
    my $coldescs = {};
    my $fieldlist = [];
    my $fields = $g{db_fields}{$view};
    foreach(@{$g{db_fields_list}{$view}}) {
	next if($g{db_fields}{$view}{$_}{type} eq 'bytea');
	$coldescs->{$fields->{$_}{desc}} = $_;
	push @$fieldlist,$_;
    }
    my $parser = Gedafe::SearchParser->new();
    my $helpfull_message = <<'end';
Gedafe couldn't understand your question. Please make sure that it
is a valid search expression. (no loose ends). Perhaps the manual
also has some helpfull tips on searching.
end
    my $tree = $parser->startnode($question) or die($helpfull_message);
    my $query = sqlify($tree,$fieldlist,$coldescs);
    print STDERR ">>> $query\n";
    return $query;
}

sub sqlexpression($$$){
    my $tree = shift;
    my $fields = shift;
    my $coldescs = shift;

    my $left = $tree->{left};
    my $op = $tree->{op};

    # transform left
    if($left eq '##ALL COLUMNS##'){
	$left = join("||' '||",@$fields);
    }elsif($left =~ /^\d+$/){
	#columns in view are counted from 1
	$left = $fields->[$left-1];
    }else{
	for(keys(%$coldescs)){
	    if(uc($_) eq uc($left)){
		$left = $coldescs->{$_};
	    }
	}
    }
    
    # we know right is an rvalue here.
    my $rvalue = $tree->{right};
    my $right = $rvalue->{form}{value};
    if($op eq 'like'){
	$right = '%'.$right.'%';
    }
    $right = "'".$right."'";
    if($rvalue->{form}{not}){
	return "not $left $op $right";
    }else{
	return "$left $op $right ";	
    }
    
}

sub sqlify($$$){
    my $tree = shift;
    my $fields = shift;
    my $coldescs = shift;
    if($tree->{type} eq 'expression'){
	my $right = $tree->{right};
	if($right->{type} eq 'rvalue'){
	    return sqlexpression($tree,$fields,$coldescs);
	}else{
	    #right = binary
	    my $left = $tree->{left};
	    my $op = $tree->{op};
	    #the right operand of a binary is always an rvalue
	    return sqlexpression({type=>"expression",
				  left=>$left,
				  op=>$op,
				  right=>
				  $right->{right}}
				,$fields,$coldescs).
		"$right->{op} ".
		sqlify({type=>"expression",
			left=>$left,
			op=>$op,
			right=>$right->{left}}
		      ,$fields,$coldescs);
	}
    }elsif($tree->{type} eq 'exbinary'){
	return sqlify($tree->{left},$fields,$coldescs).
	    "$tree->{op} ".
	    sqlify($tree->{right},$fields,$coldescs);
    }elsif($tree->{type} eq 'where'){
	return $tree->{clause};
    }
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

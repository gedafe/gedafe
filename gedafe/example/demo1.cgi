#!/usr/bin/speedy -w

# uncomment this when doing maintenance work:
# print "Content-Type: text/html\n\n";
# print "Database temporarily disabled for maintenance.<br>\n";
# exit;

use lib "/usr/local/gedafe/lib/perl";

use Gedafe::Start;

$|=1; # do not buffer output to get a more responsive feeling


Start(
    db_datasource  => 'dbi:Pg:dbname=demo1',
    list_rows      => 15,
    templates      => '/usr/local/gedafe/example/templates',
    schema	   => 'public',
    schema_search_path => " 'public','test' ",     
    pearl_dir      => '/usr/local/gedafe/example/mypearls',
    widget_dir      => '/usr/local/gedafe/example/mywidgets',
    isearch        => 'java/isearch.jar',
    show_row_count => 0,
);

#!/usr/bin/speedy -w

use lib "/usr/local/gedafe/lib/perl";

use Gedafe::Start;

$|=1; # do not buffer output to get a more responsive feeling

Start(
    app_site       => 'localhost',
    app_path       => '/gedafe/demo1.cgi',
    db_datasource  => 'dbi:Pg:dbname=demo1',
    list_rows      => 15,
    admin_user     => 'admin',
    templates      => '/usr/local/gedafe/example/templates',
    documentation_url => 'http://mysite.com/demo-docs',
);

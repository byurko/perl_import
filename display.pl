#!/usr/bin/perl -w
#
# codequiz/display.pl
# 20110729 - BJY
# Web display of data imported by import.pl
#
# usage: install this file under a website
#
# NOTE: I have hard-coded the file name expected in the local directory for this demo
# NOTE (SQLite DB): The file is expected to be 'import.db'
#
# use strict;
use warnings;
use DBI;
use CGI;

# open a connection to the local SQLite DB
# the schema has been defined using an external call to sqlite3 importing schema.sql

# my $dbh = DBI->connect("dbi:SQLite:dbname=import.db","","") or die "$DBI::errstr\n";

my $q = CGI->new; # create new CGI object
print $q->header; # create the HTTP header
print $q->start_html('TV Data'); # start the HTML
print $q->h1('Display TV Data'); # level 1 header

# open a connection to the local SQLite DB
# the schema has been defined using an external call to sqlite3 importing schema.sql
my $dbh = DBI->connect("dbi:SQLite:dbname=import.db","","") or die "$DBI::errstr\n";

my $sth = $dbh->prepare("SELECT s.series_name, e.season, e.episode, e.show_title, n.network_name, e.synopsis, e.pub_date
FROM episodes AS e INNER JOIN series AS s ON e.series_id = s.series_id INNER JOIN networks AS n ON e.network_id = n.network_id;"); # or die "$dbh->errstr\n";
$sth->execute() or die "$sth->errstr\n";
my $series_name;
my $season;
my $episode;
my $show_title;
my $network_name;
my $synopsis;
my $pub_date;
my $rc = $sth->bind_columns(\$series_name, \$season, \$episode, \$show_title, \$network_name, \$synopsis, \$pub_date);
while ($sth->fetch) {
	$pub_date =~ s/(.*)T(.*)/$1 $2/;
	print "<ul><li>Series: $series_name</li><li>Season: $season</li><li>Episode: $episode</li><li>Title: $show_title</li><li>Network: $network_name</li><li>Synopsis: $synopsis</li><li>Posted: $pub_date</li></ul>\n";
}

print $q->end_html; # end the HTML

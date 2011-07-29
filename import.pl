#!/usr/bin/perl -w
#
# codequiz/import.pl
# 20110727 - BJY
# Demonstration of an XML import in perl 5.10.1
#
# usage: perl [-w] import.pl feed.xml
# NOTE: I have hard-coded the file name expected in the local directory for this demo
# NOTE (SQLite DB): The file is expected to be 'import.db'
#
use strict;
use warnings;
use XML::LibXML;
use DBI;

my $debug = 0;	# created this flag to toggle conditional debug printing

check_db();

my $parser = XML::LibXML->new();
my $file = 'feed.xml';	# I removed the command line argument designating the source file.
my $tree = $parser->parse_file($file);
# my $tree = $parser->parse_file( shift @ARGV );
my $doc = $tree->getDocumentElement;

# open a connection to the local SQLite DB
# the schema has been defined using an external call to sqlite3 importing schema.sql
my $dbh = DBI->connect("dbi:SQLite:dbname=import.db","","") or die "$DBI::errstr\n";

# retrieve the file's "title" and "pubDate" for storage in the database.
my @title_node = $doc->getElementsByTagName('title');
my $import_title = $title_node[0]->textContent;
my @pubDate_node = $doc->getElementsByTagName('pubDate');
my $pubDate = $pubDate_node[0]->getFirstChild->getData;
$pubDate =~ s/(.*)Z$/$1/;

if ($debug) {
	printf("File Title: %s\n", $import_title);
	printf "Publication Date: %s\n", $pubDate;
	printf "\n";
}

my @items = $doc->getElementsByTagName('item');

foreach my $item (@items) {
	my @title_node  = $item->getElementsByTagName('title');		# I do realize that I am reusing the same variable here.
	my $title = $title_node[0]->getFirstChild->getData;
	my @series_node  = $item->getElementsByTagName('series');
	my $series = $series_node[0]->getFirstChild->getData;
	my $series_id = $series_node[0]->getAttribute('id'); 
	my @season_node = $item->getElementsByTagName('season');
	my $season = $season_node[0]->getAttribute('num');
	my @episode_node = $item->getElementsByTagName('episode');
	my $episode = $episode_node[0]->getAttribute('num');
	my @network_node  = $item->getElementsByTagName('network');
	my $network = $network_node[0]->getFirstChild->getData;
	my $network_id = $network_node[0]->getAttribute('id');
	
	# Tried to add error handling and conditional evaluation based upon the returned value of @synopsis_node and eval{}
	my $synopsis = "";
	my @synopsis_node  = $item->getElementsByTagName('synopsis');
	if (@synopsis_node) {
		$synopsis = $synopsis_node[0]->getFirstChild->getData;
		# printf "Synopsis: %s\n\n", $synopsis if $debug;
	} else {
		$synopsis = "";	# There was NO synopsis element for this item, record appropriately
	}
	
	# Just some debugging interests
	if ($debug) {
		printf "Title: %s\n", $title;
#		printf "Series: %s\n", $series;
#		printf "Series ID: %s\n", $series_id;
		printf "Season: %s\n", $season;
		printf "Episode: %s\n", $episode;
#		printf "Network: %s\n", $network;
#		printf "Network ID: %s\n", $network_id;	# you cannot use the Network ID as a key
		printf "Synopsis: %s\n", $synopsis;
	}
	#	print $doc->toString();		# This will print out the ENTIRE XML document as the parser has understood it
	
	# Let's record each record into the database one time only.
	# I have decided that rather than adding lots of application programming logic to avoid duplicate inserts, 
	# I would utilize the UNIQUE constraint of the SQLite engine, combined with ON CONFLICT IGNORE.
	
	my $db_series_id;
	my $db_network_id;
	my $sth; # statement handle object
	my $rc;	# result code

	# First, record the Series (and retrieve the resulting ID)
	$dbh->do("INSERT INTO series (series_code, series_name) VALUES ('$series_id', '$series');") or die $dbh->errstr;
	if ($dbh->err()) { die "$DBI::errstr\n"; }

	# $dbh->{RaiseError} = 1; # do this, or check every call for errors

	$sth = $dbh->prepare("SELECT series_id FROM series WHERE series_code = ? AND series_name = ?;") or die $dbh->errstr;
	$sth->execute($series_id, $series) or die $sth->errstr;
	$rc = $sth->bind_col(1, \$db_series_id);
	while ($sth->fetch) {
		print "DB Series ID: $db_series_id,\tSeries ID: $series_id,\tSeries Name: $series\n" if $debug;
	}
	
	# Second, record the Network (and retrieve the resulting ID)
	$dbh->do("INSERT INTO networks (network_name) VALUES ('$network');") or die $dbh->errstr;
	if ($dbh->err()) { die "$DBI::errstr\n"; }
#	$db_network_id = $dbh->last_insert_id("", "", "networks", "");

	$sth = $dbh->prepare("SELECT network_id FROM networks WHERE network_name = ?;") or die $dbh->errstr;
	$sth->execute($network) or die $sth->errstr;
#	$sth->execute;
	$rc = $sth->bind_col(1, \$db_network_id);
	while ($sth->fetch) {
		print "DB Network ID: $db_network_id,\tNetwork ID: $network_id,\tNetwork Name: $network\n" if $debug;
	}

	
	# Third, add the Episode to the database, honoring all three tables' constraints on UNIQUE values.
	if ($debug) {
#		printf "Series ID: %s\n", $db_series_id;
#		printf "Network ID: %s\n", $db_network_id;
		printf "Pub Date: %s\n", $pubDate;
		printf "\n";
	}
	$sth = $dbh->prepare("INSERT INTO episodes (series_id, network_id, show_title, season, episode, synopsis, pub_date) VALUES (?, ?, ?, ?, ?, ?, ?);") or die $dbh->errstr;;
	$sth->execute($db_series_id, $db_network_id, $title, $season, $episode, $synopsis, $pubDate) or die $sth->errstr;
	
}	# end foreach

$dbh->disconnect();

sub check_db {
	# This is a last minute subroutine to check for and possibly create the required database for this project
	# from within this source file. The idea is to individually check for the health of all three tables, and
	# if any of them are not found, we will run a query to create them.

	# open a connection to the local SQLite DB
	# the schema has been defined using an external call to sqlite3 importing schema.sql
	my $dbh = DBI->connect("dbi:SQLite:dbname=import.db","","") or die "$DBI::errstr\n";

	my $table_found;
	my $sth;
	my $rc;

	$sth = $dbh->prepare("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='series';") or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	$rc = $sth->bind_col(1, \$table_found);
	while ($sth->fetch) {
		if (!$table_found) {
			$dbh->do("CREATE TABLE series (
				series_id INTEGER PRIMARY KEY,
				series_code TEXT,
				series_name TEXT,
				CONSTRAINT unique_series UNIQUE (series_code, series_name) ON CONFLICT IGNORE
				);") or die $dbh->errstr;
			if ($dbh->err()) { die "$DBI::errstr\n"; }
		}
	}

	$sth = $dbh->prepare("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='networks';") or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	$rc = $sth->bind_col(1, \$table_found);
	while ($sth->fetch) {
		if (!$table_found) {
			$dbh->do("CREATE TABLE networks (
				network_id INTEGER PRIMARY KEY,
				network_name TEXT UNIQUE ON CONFLICT IGNORE
				);") or die $dbh->errstr;
			if ($dbh->err()) { die "$DBI::errstr\n"; }
		}
	}

	$sth = $dbh->prepare("SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='episodes';") or die $dbh->errstr;
	$sth->execute() or die $sth->errstr;
	$rc = $sth->bind_col(1, \$table_found);
	while ($sth->fetch) {
		if (!$table_found) {
			$dbh->do("CREATE TABLE episodes (
				episode_id INTEGER PRIMARY KEY,
				series_id INTEGER,
				network_id INTEGER,
				show_title TEXT,
				episode INTEGER,
				season INTEGER,
				synopsis TEXT,
				pub_date TEXT,
				CONSTRAINT unique_episodes UNIQUE (series_id, network_id, show_title, episode, season) ON CONFLICT IGNORE
				);") or die $dbh->errstr;
			if ($dbh->err()) { die "$DBI::errstr\n"; }
		}
	}

	$dbh->disconnect();
	return;
}

sub debug_print_node {
	# This subroutine expects one object of type $node to be passed in.
	# I am not sure what we will do if other data is passed in, but I am sure I need to do
	# more work here to check the "type" and contents of this argument.
	if ($debug) {
		my $node = $_[0];
		printf "nodeName: %s\n", $node->nodeName;
		printf "nodeValue: %s\n", $node->nodeValue if ($node->nodeValue);
		printf "textContent: %s\n", $node->textContent;
		printf "nodeType: %s\n", $node->nodeType;
		printf "toString: %s\n", $node->toString;
		printf "localname: %s\n", $node->localname;
		printf "prefix: %s\n", $node->prefix if ($node->prefix);
		printf "\n";
	}
}

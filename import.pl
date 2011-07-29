#!/usr/bin/perl -w
#
# codequiz/import.pl
# 20110727 - BJY
# Demonstration of an XML import in perl 5.10.1
#
# usage: perl [-w] import.pl feed.xml
#
use strict;
use warnings;
use XML::LibXML;

# sub debug_print_node;	# This is a forward prototype of this subroutine which will be defined later in the same source file

my $debug = 1;	# created this flag to toggle conditional debug printing

my $parser = XML::LibXML->new();
my $file = 'feed.xml';	# I removed the command line argument designating the source file.
my $tree = $parser->parse_file($file);
# my $tree = $parser->parse_file( shift @ARGV );
my $doc = $tree->getDocumentElement;

# retrieve the file's "title" and "pubDate" for storage in the database.
my @title_node = $doc->getElementsByTagName('title');
my $import_title = $title_node[0]->textContent;
my @pubDate_node = $doc->getElementsByTagName('pubDate');
my $pubDate = $pubDate_node[0]->getFirstChild->getData;

if ($debug) {
	printf("File Title: %s\n", $import_title);
	printf "Publication Date: %s\n", $pubDate;
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
		printf "Series: %s\n", $series;
		printf "Series ID: %s\n", $series_id;
		printf "Season: %s\n", $season;
		printf "Episode: %s\n", $episode;
		printf "Network: %s\n", $network;
		printf "Network ID: %s\n", $network_id;		# you cannot use the Network ID as a key
		printf "Synopsis: %s\n", $synopsis;
		printf "\n";
	}
	#	print $doc->toString();		# This will print out the ENTIRE XML document as the parser has understood it

}	# end foreach

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

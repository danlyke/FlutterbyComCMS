#!/usr/bin/perl -w
use strict;
use lib '/home/danlyke/websites/flutterby.com/flutterby_cms';
use local::lib;
use utf8::all;
use LWP::Simple;
use DBI;
use XML::Feed;
use Data::Dumper;
use Try::Tiny;
use XML::OPML;

my $dbh = DBI->connect(
			 'DBI:Pg:dbname=flutterbycms;host=localhost',
			 'danlyke', 'danlyke',
			);

my $opml = new XML::OPML(version => "1.1");

$opml->head(
             title => 'IndieWebCamp irc-people',
             ownerName => 'Dan Lyke',
             ownerEmail => 'danlyke@flutterby.com',
           );


my $sql = "SELECT  feedname, webpage_url, syndication_url FROM feed, feed_sources WHERE feed.id = feed_sources.feed_id AND feed_sources.feed_source_id=2";

my $sth = $dbh->prepare($sql);
$sth->execute();

while (my $row = $sth->fetchrow_hashref)
{
    my $title = $row->{feedname}//$row->{webpage_url}//$row->{syndication_url};
    $title =~ s/\&/\&amp;/g;
    $title =~ s/\"/\&quot;/g;
    $title =~ s/\'/\&apos;/g;
    $title =~ s/\>/\&gt;/g;
    $title =~ s/\</\&lt;/g;

    $opml->add_outline(
                       title => $title,
                       htmlUrl => $row->{webpage_url},
                       xmlUrl => $row->{syndication_url},
               );

}

$opml->save('/home/danlyke/websites/flutterby.com/public_html/indieweb/irc-people.opml');



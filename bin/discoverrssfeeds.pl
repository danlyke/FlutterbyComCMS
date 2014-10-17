#!/usr/bin/perl -w
use strict;
use lib '/home/danlyke/websites/flutterby.com/flutterby_cms';
use local::lib;
use utf8::all;
use LWP::Simple;
use DBI;
use XML::Feed;
use Data::Dumper;
use File::Slurp;
use Try::Tiny;
use Flutterby::Tree::Find; 
use Flutterby::Parse::HTML;
use Flutterby::Output::Text;
use File::Path qw(make_path);

sub Filename($$$)
{
    my ($type, $url, $id) = @_;
    my $filename = $url;
    $filename =~ s/[^\w\.\/]/_/g;
    $filename =~ s/\/\//\//g;
    $filename =~ s/\/+$//g;

    my $root = '';
    if ($filename =~ /(.*\/)(.+)/)
    {
        $root = $1;
        $filename = $2;
    }

    my $dir = "$ENV{HOME}/var/rssfeeds/cache/$type/$root";
    make_path($dir);
    return $dir.$filename;
}

sub Mirror($$$)
{
    my ($type, $url, $id) = @_;
    my $filename = Filename($type,$url,$id);
    mirror($url, $filename);
    print "Mirroring $url to $filename\n";
    return $filename;
}


sub DiscoverRSSFeeds()
{
    my ($dbh, @pages) = @_;
    
}


sub ParseRSSFeedFromPage
{
    my ($dbh, $url) = @_;
    my $title = $url;
 
    try
    {
        print "Starting parse\n";
        my $p = Flutterby::Parse::HTML->new(-allowalltags => 1);
        my $t = $p->parsefile(Filename('webpage', $url, 'irc-people'));

        my @feeds;
        
        my @links = Flutterby::Tree::Find::node($t, 'link');
        my @a = Flutterby::Tree::Find::node($t, 'a');

        my @titles = Flutterby::Tree::Find::node($t, 'title');
        if (@titles)
        {
            $title = '';
            my $outputter = Flutterby::Output::Text->new(
                                                        -outputfunc => sub { $title .= $_[1];});
            $outputter->output($titles[0]);
        }
        
        print "About to run through links\n";
        my %links;
        my $rooturl = $url;
        $rooturl =~ s/\/+$//;
        
        for my $key (@links, @a)
        {
            if ( defined($key->[1]->[0]->{rel}))
            {
                if (($key->[1]->[0]->{rel} =~ 'alternate'
                     || $key->[1]->[0]->{rel} =~ 'alternative'
                    ) &&
                    ( $key->[1]->[0]->{type} eq 'application/rss+xml'  ||
                      $key->[1]->[0]->{type} eq 'application/atom+xml' ||
                      $key->[1]->[0]->{type} eq '' ||
                      !defined($key->[1]->[0]->{type})))
                {
                    print Dumper($key);
                    my $link = $key->[1]->[0]->{href};
                    $links{$link} = 1;
                }
            }
            elsif (defined($key->[1]->[0]->{href})
                   && $key->[1]->[0]->{href} =~ /(rss|atom)/)
            {
                my $link = $key->[1]->[0]->{href};
                $links{$link} = 1;
            }
        }
        for my $link (keys %links)
        {
            my $qualifiedlink = $link;

            if ($qualifiedlink !~ /^http/)
            {
                my $prefix = $url;
                $prefix = $1 if ($prefix =~ /^(https?\:\/\/.*\/)/);

                $prefix .= '/' if ($prefix !~ /\/$/);
                $qualifiedlink = $prefix.$qualifiedlink;
            }
            my $sql = "INSERT INTO feed(syndication_url,webpage_url,feedname) VALUES (".$dbh->quote($qualifiedlink).','.$dbh->quote($url).','.$dbh->quote($title).")";
            unless ($dbh->do($sql))
            {
#                warn "Warning: ".$dbh->errstr."\n";
                $sql = 'UPDATE feed SET webpage_url='.$dbh->quote($url)
                    .', feedname='.$dbh->quote($title).' WHERE syndication_url='
                        .$dbh->quote($qualifiedlink);
                $dbh->do($sql)
                    || warn "Warning: ".$dbh->errstr."\n$sql\n";
            }
            $sql = 'INSERT INTO feed_sources(feed_id, feed_source_id) VALUES ((SELECT id FROM feed WHERE syndication_url='
                .$dbh->quote($qualifiedlink).'),2)';
            $dbh->do($sql)
                || warn "Warning: ".$dbh->errstr."\n";
        }
    }
    catch
    {
        warn "Error parsing out file: $_\n";
    };
}

sub GrabIndieWebCampWikiIRCPeople
{
    my ($dbh) = @_;
    my @ircpeoplepage = ('webpage', 'http://indiewebcamp.com/irc-people', 'direct');
    &Mirror(@ircpeoplepage);

    my $page = read_file(&Filename(@ircpeoplepage));
        
    while ($page =~ s/href\=\"\/User\:(.*?)"//xs)
    {
        my $url = "http://$1";
        Mirror('webpage', $url, 'irc-people');
        ParseRSSFeedFromPage($dbh, $url);
    }
}

my $dbh = DBI->connect(
			 'DBI:Pg:dbname=flutterbycms;host=localhost',
			 'danlyke', 'danlyke',
			);

if (@ARGV)
{
    for (@ARGV)
    {
        ParseRSSFeedFromPage($dbh, $_);
    }
}
else
{
    GrabIndieWebCampWikiIRCPeople($dbh);
}

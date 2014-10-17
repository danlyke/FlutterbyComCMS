#!/usr/bin/perl -w
use strict;
use local::lib;
use utf8::all;
use LWP::Simple;
use DBI;
use XML::Feed;
use Data::Dumper;
use File::Slurp;
use Try::Tiny;
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
    return $filename;
}

sub ParseFilenameAsFeed($$$)
{
    my ($dbh, $id, $filename) = @_;
    my $t = read_file($filename);
    $t =~ s/^.*<\?xml/<\?xml/si;
    my $feed;
    
    try
    {
        $feed = XML::Feed->parse(\$t);
    }
    catch
    {
    };

    if (!$feed)
    {
        $t =~ s/[\x80-\x8fffffff]//xsg;
        try
        {
            $feed = XML::Feed->parse(\$t);
        }
        catch
        {
            warn "RSS Parse failed: $_\n";
        };
    }


    if ($feed)
    {
        warn "Checking feeds\n";
        for my $item ($feed->entries)
        {
            my $print;
            if (defined($item->content->body))
            {
                if ($item->content->body =~ m%http://www.flutterby.com/archives/comments/(\d+)\.html%xs
                    || $item->content->body =~ m%http://www.flutterby.com/archives/comments/viewentry.cgi?id=(\d+)%xs)
                {
                    my $entry_id = $1;
                    print $item->title." at ".$item->link." links to entry $entry_id\n";
                    my $sql = 'INSERT INTO feedentrylinks(entry_id, feed_id, title, entry_url) VALUES ('
                        .join(',', map { $dbh->quote($_) } ($entry_id, $id, $item->title, $item->link ))
                            .')';
                    $dbh->do($sql);
                }
#                        if ($item->content->body =~ /Flutterby/)
#                        {
#                            print "$item->{title} at $item->{link} mentions Flutterby:\n".$item->content->body."\n";
#                        }
            }
        }
    }
}

my $dbh = DBI->connect(
			 'DBI:Pg:dbname=flutterbycms;host=localhost',
			 'danlyke', 'danlyke',
			);


#ParseFilenameAsFeed($dbh, 109, 'cache/syndication/109_http___feeds.feedburner.com_eMusings');
#exit(0);


my $sql = 'SELECT id, webpage_url, syndication_url, syndication_type FROM feed';

my $sth = $dbh->prepare($sql)
    || die $dbh->errstr;
$sth->execute
    || die $sth->errstr;

while (my $row = $sth->fetchrow_arrayref)
{
    my ($id, $webpage_url, $syndication_url, $syndication_type) = @$row;

    if ($webpage_url && !$syndication_url)
    {
        my $filename = Mirror('webpage', $webpage_url, $id);
        my ($feed_url, $feed_type);
        my $p = HTML::Parser->new( api_version => 3,
                                start_h =>
                                [sub {
                                     my ($tagname, $attr) = @_;
                                     if ($tagname eq 'link'
                                        && $attr->{rel} eq 'alternate'
                                        && $attr->{href})
                                     {
                                         for my $t ('atom', 'rss')
                                         {
                                             unless ($feed_url)
                                             {
                                                 if ($attr->{type} eq "application/$t+xml")
                                                 {
                                                     $feed_type = $t;
                                                     $feed_url = $attr->{href};
                                                 }
                                             }
                                         }
                                     }
                                 }, "tagname, attr"],
                              );
        $p->parse_file($filename);

        if ($feed_url && $feed_type)
        {
            $sql = 'UPDATE feed SET syndication_url='.$dbh->quote($feed_url).', syndication_type='.$dbh->quote($feed_type);
            $dbh->do($sql)
                || die $dbh->errstr;
            $syndication_url = $feed_url;
            $syndication_type = $feed_type;
        }
        else
        {
            warn "Unable to find feed for $webpage_url\n";
        }
    }
    if ($syndication_url)
    {
        my $filename = Filename('syndication', $syndication_url, $id);
        Mirror('syndication', $syndication_url, $id);
#            unless -f $filename;

        if (-f $filename)
        {
            print "Parsing $filename\n";
            ParseFilenameAsFeed($dbh, $id, $filename);
        }
    }
}

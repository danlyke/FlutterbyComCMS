#!/usr/bin/perl -w
use strict;
use CGI qw/-utf8/;
use DBI;
use lib 'flutterby_cms';
use vars qw($configuration);
use Flutterby::Config;
$configuration ||= Flutterby::Config::load();
use Flutterby::DBUtil;
use Flutterby::Parse::HTML;
use Flutterby::Tree::Find;
use Flutterby::Output::HTML;
use Data::Dumper;

use LWP::Simple;

sub main($)
{
    my ($dbh) = @_;
    my $cgi = CGI->new();

    print $cgi->header('text/plain');

    if ($cgi->param('source')
        && $cgi->param('target')
       && $cgi->param('vouch'))
    {
        my $vouch = $cgi->param('vouch');
        my $link = $cgi->param('target');
        my $entry_id;
        if ($link =~ /comments\/(\d+)\.htm/)
        {
            $entry_id = $1;
        }
        elsif ($link =~ /id\=(\d+)/)
        {
            $entry_id = $1;
        }
        
        if ($entry_id)
        {
            my $remote_url = $cgi->param('source');
            my $text = get($remote_url);
            my $remote_html;

            if ($text =~ /http(s?)\:\/\/www.flutterby.com\/archives\/comments\/$entry_id.htm(l?)/xsi
               || $text =~ /http(s?)\:\/\/www.flutterby.com\/archives\/viewentry.cgi\?[^\"']*id\=$entry_id/xsi)
            {
                my $parser = Flutterby::Parse::HTML->new();
                my $tree = $parser->parse($text);
                my @hentries = Flutterby::Tree::Find::class($tree, 'h-entry');

                for my $hentry (@hentries)
                {
                    my $baseurl = $remote_url;
                    $baseurl =~ s/^(.*?\w)\/.*$/$1/;

                    my @pauthors = Flutterby::Tree::Find::class($hentry, 'p-author');
                    for my $pauthor (@pauthors)
                    {
                        my @pnames = Flutterby::Tree::Find::class($pauthor, 'p-name');
                        for my $pname (@pnames)
                        {
                            $remote_html .= "<p>Posted by: ";
                            my $outputhtml = Flutterby::Output::HTML->new(
                                                                          -suppressEvents => 1,
                                                                      -relNoFollow => 1);
                            $outputhtml->setOutput(\$remote_html);
                            $outputhtml->output($pname);
                            $remote_html .= "</p>";
                        }
                    }

                    my @econtent = Flutterby::Tree::Find::class_not_class($hentry->[1],
                                                                          'e-content',
                                                                          'h-\w+');


                    for (@econtent)
                    {
                        my @links = Flutterby::Tree::Find::node($hentry, 'a');
                        my @imgs = Flutterby::Tree::Find::node($hentry, 'img');
                    
                        for (@links)
                        {
                            $_->[1]->[0]->{href} = $baseurl.$_->[1]->[0]->{href} if ($_->[1]->[0]->{href} =~ /^\//);
                        }
                        for (@imgs)
                        {
                            $_->[1]->[0]->{src} = $baseurl.$_->[1]->[0]->{src} if ($_->[1]->[0] ->{src} =~ /^\//);
                        }
                        my $outputhtml = Flutterby::Output::HTML->new(
                                                                      -suppressEvents => 1,
                                                                      -relNoFollow => 1);
                        $outputhtml->setOutput(\$remote_html);
                        $outputhtml->output($_);
                    }
                }
                

                my $title = $remote_url;
                
                $title = $1 if ($text =~ /\<title\>(.*?)\<\/title\>/xsi);
                    
                my $sql = "INSERT INTO webmentionlinks(entry_id,title,entry_url,entry_html) VALUES ("
                    .join(', ', map { $dbh->quote($_) } ($entry_id, $title, $remote_url, $remote_html)).')';
                if (!$dbh->do($sql))
                {
                    $sql = 'UPDATE webmentionlinks SET title='
                        .$dbh->quote($title)
                            .', entry_html='
                                .$dbh->quote($remote_html)
                                    .' WHERE entry_id='
                                        .$dbh->quote($entry_id)
                                            .' AND entry_url='
                                                .$dbh->quote($remote_url);
                    $dbh->do($sql);
                }

#                print "$sql\n";
                print "Success\n";
            }
            else
            {
                print "Didn't find trackback\n";
            }
        }
        else
        {
            print "Malformed target $link\n";
        }
    }
    else
    {
        print "Bad webmention request\n";
    }
}

my $dbh = DBI->connect($configuration->{-database},
                       $configuration->{-databaseuser},
                       $configuration->{-databasepass})
    or die DBI::errstr;
$dbh->{AutoCommit} = 1;

main($dbh);
$dbh->disconnect;

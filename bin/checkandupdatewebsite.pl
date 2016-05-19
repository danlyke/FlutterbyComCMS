#!/usr/bin/perl -w
use strict;
use utf8::all;
use lib '/home/danlyke/websites/flutterby.com/lib/';

use Flutterby::Util;
use Flutterby::Users;
use Flutterby::Output::SHTMLProcessed;
use Flutterby::Parse::HTML;
use Flutterby::HTML;
use Flutterby::Parse::Text;
use Flutterby::Parse::String;
use Flutterby::Parse::Ordinal;
use Flutterby::Parse::Int;
use Flutterby::Parse::Month;
use Flutterby::Parse::DayOfWeek;

use CGI;
use DBI;
use LockFile::Simple;

my $lockfile = "$ENV{HOME}/var/lockfiles/checkandupdatewebsite";
my $lockmgr = LockFile::Simple->make(-autoclean => 1);

unless ($lockmgr->trylock($lockfile))
{
    warn "Already running\n";
    exit(0);
}



my ($dbh);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
	$dbh->{AutoCommit} = 1;
}
sub END
{
    $dbh->disconnect;
}

my ($destinationfiles) = '/home/danlyke/websites/flutterby.com/public_html/';
my ($templatefiles) = '/home/danlyke/websites/flutterby.com/flutterby_cms/templates/';


sub CheckForUpdates($)
{
    my ($info) = @_;

    my ($targetdate) = (stat($destinationfiles.$info->{-target}))[9];
    my ($templatedate) = (stat($templatefiles.$info->{-template}))[9];
    
    return 1 unless defined($templatedate);
    return 1 unless defined($targetdate);

    return 1 if ($templatedate > $targetdate);

    my ($isodate);
    $isodate = Flutterby::Util::UnixTimeAsISO8601($targetdate);

    my ($sqlchanges);
    $sqlchanges = $info->{-sqlchanges};
    $sqlchanges = [$sqlchanges] unless (ref($sqlchanges) eq 'ARRAY');

    my ($sql);
    foreach $sql (@$sqlchanges)
      {
	my ($updates,$row);
	$updates = $dbh->selectall_arrayref($sql)
	    || die "$sql\n".$dbh->errstr;
	foreach $row (@$updates)
	  {
	    return 1 
		if (defined($#$row) && defined($row->[0]) 
		    && ($row->[0] gt $isodate))
	  }
      }
	
    return undef;
  }

sub UpdateFileClass($)
  {
    my ($info) = @_;
    

    if (open O, ">$destinationfiles$info->{-target}.bak")
    {
	my ($variables);
	if ($info->{-weblogid})
	{
	    $variables = Flutterby::Users::GetWeblogInfo(undef, $dbh, $info->{-weblogid});
	}
	elsif ($info->{-weblogurl})
	{
	    $variables = Flutterby::Users::GetWeblogInfo($info->{-weblogurl}, $dbh);
	}
	else
	{
	    $variables = {};
	}
	

	my ($tree) =
	  Flutterby::HTML::LoadHTMLFileAsTree($templatefiles.$info->{-template});
	my ($out);
	$out = new Flutterby::Output::HTMLProcessed
	  (
	   -variables => $variables,
	   -dbh => $dbh,
	   -textconverters => 
	   { 
	    1 => new Flutterby::Parse::Text,
	    2 => new Flutterby::Parse::HTML,
	    3 => new Flutterby::Parse::Text,
	    'escapehtml' => new Flutterby::Parse::String(-longeststring => 40),
	    'escapeurl' => new Flutterby::Parse::String(),
	    'month' => new Flutterby::Parse::Month,
	    'day' => new Flutterby::Parse::Ordinal,
	    'dayofweek' => new Flutterby::Parse::DayOfWeek,
	   },
	  );
	print O '<!DOCTYPE html>';
	$out->setOutput(\*O);
	$out->output($tree);
	close O;
	chmod 0755, "$destinationfiles$info->{-target}.bak";
	rename "$destinationfiles$info->{-target}.bak", "$destinationfiles$info->{-target}";
      }
	
  }

my ($pageclasses) =
  {
   'short' => 
   {
    -template => 'short.html',
    -weblogid => 1,
    -sqlchanges =>
    [
     'SELECT articles.entered AS entered FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY entered DESC LIMIT 2',
     'SELECT articles.updated AS updated FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY updated DESC LIMIT 2',
     'SELECT DISTINCT latestcomment FROM weblogentries ORDER BY latestcomment DESC LIMIT 2',
    ],
    -target => 'short.html',
   },
   'main' =>
   {
    -template => 'index.html',
    -weblogid => 1,
    -sqlchanges =>
    [
     'SELECT articles.entered AS entered FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY entered DESC LIMIT 2',
     'SELECT articles.updated AS updated FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY updated DESC LIMIT 2',
     'SELECT DISTINCT latestcomment FROM weblogentries ORDER BY latestcomment DESC LIMIT 2',
    ],
    -target => 'index.html',
   },
   'archives' =>
   {
    -template => 'archivesindex.html',
    -weblogid => 1,
    -sqlchanges =>
    [
     'SELECT articles.entered AS entered FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY entered DESC LIMIT 2',
     'SELECT articles.updated AS updated FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY updated DESC LIMIT 2',
     'SELECT DISTINCT latestcomment FROM weblogentries ORDER BY latestcomment DESC LIMIT 2',
    ],
    -target => 'archives/index.html',
    },

   'new' =>
   {
    -template => 'indexnew.html',
    -sqlchanges =>
    [
     'SELECT articles.entered AS entered FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY entered DESC LIMIT 2',
     'SELECT articles.updated AS updated FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY updated DESC LIMIT 2',
     'SELECT DISTINCT latestcomment FROM weblogentries ORDER BY latestcomment DESC LIMIT 2',
    ],
    -target => 'indexnew.html',
   },
   'long' =>
   {
    -template => 'long.html',
    -weblogid => 1,
    -sqlchanges =>
    [
     'SELECT articles.entered AS entered FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY entered DESC LIMIT 2',
     'SELECT articles.updated AS updated FROM articles,weblogentries WHERE weblogentries.article_id = articles.id ORDER BY updated DESC LIMIT 2',
     'SELECT DISTINCT latestcomment FROM weblogentries ORDER BY latestcomment DESC LIMIT 2',
    ],
    -target => 'long.html',
   },
   'sitesdanreads' =>
   {
       -template=> 'sitesdanreads.html',
       -weblogid => 1,
       -sqlchanges => [],
       -target=> 'sitesdanreads.html',
   },
  };

my ($somethingupdated);
foreach (keys %$pageclasses)
  {
#    print "Checking class $_\n";
    if (CheckForUpdates($pageclasses->{$_}))
    {
#        print "Updating class $_\n";
        UpdateFileClass($pageclasses->{$_});
        $somethingupdated = 1
	    if ($_ eq 'main');
    }
  }


use LWP::UserAgent;

if (0 && $somethingupdated)
{
    print "Found updates\n";

    if (-M '/home/danlyke/websites/flutterby.com/var/lastweblogscomping' > (1/12))
    {
	my $ua =  LWP::UserAgent->new('agent' => 'FlutterbyUpdateNotify/1.0',
				      timeout => 30);
	my $response = $ua->get('http://newhome.weblogs.com/pingSiteForm?name=Flutterby%21&url=http%3A%2F%2Fwww.flutterby.com%2F');
#	if ($response->is_success) {
#            print $response->content;
#        } else {
#            print $response->error_as_HTML;
#        }


	system('touch /home/danlyke/websites/flutterby.com/var/lastweblogscomping');
    }
}



$lockmgr->unlock($lockfile);




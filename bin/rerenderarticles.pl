#!/usr/bin/perl -w
use strict;
use lib './flutterby_cms';
use vars qw($configuration);
use Flutterby::Config;
$configuration ||= Flutterby::Config::load();

use Flutterby::Util;
use Flutterby::Output::SHTMLProcessed;
use Flutterby::Parse::HTML;
use Flutterby::HTML;
use Flutterby::Parse::Text;
use Flutterby::Parse::String;
use Flutterby::Parse::Ordinal;
use Flutterby::Parse::Int;
use Flutterby::Parse::Month;
use Flutterby::Parse::DayOfWeek;


use DBI;
my ($dbh);
$dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
		    'danlyke',
		    'danlyke')
    or die $DBI::errstr;

my ($sql, $sth, $row, $lastupdateunixtime,$lastupdatefile, $nowunixtime);

$nowunixtime = time();
$lastupdatefile = "/home/danlyke/var/lastarticlesupdate";
$lastupdateunixtime = (stat($lastupdatefile))[9] - 1
    if -f $lastupdatefile;
$lastupdateunixtime ||= 1;


if (open(O, ">$lastupdatefile"))
{
    print O Flutterby::Util::UnixTimeAsISO8601($nowunixtime);
    close O;
}

my ($lastupdate) =
    $dbh->quote(Flutterby::Util::UnixTimeAsISO8601($lastupdateunixtime));

$sql = 'SELECT articles.id AS article_ids, articlespublished.path AS article_path, articlecategories.templatehtml AS templatehtml FROM articles,articlespublished,articlecategories WHERE articles.id=articlespublished.article_id AND articlespublished.category_id=articlecategories.id AND ('
    .join(' OR ',
	  map {"$_ >= $lastupdate"} ('articles.entered',
				     'articles.updated',
				     'articlespublished.entered',
				     'articlespublished.updated')
	  ).')';
$sth = $dbh->prepare($sql)
    || die $dbh->errstr."\n   $sql\n";
$sth->execute
    || die $sth->errstr."\n   $sql\n";

while ($row = $sth->fetchrow_hashref)
{
    my ($tree, $outputfilename, $publishid, $templatehtml);
    $outputfilename = $row->{'article_path'};
    $publishid = $row->{'article_ids'};
    $templatehtml = $row->{'templatehtml'};

    $tree = Flutterby::HTML::LoadHTMLFileAsTree($configuration->{-htmlpath}.$templatehtml);

    Flutterby::Util::EnsureDirectory("$configuration->{-htmlroot}/$outputfilename.bak");
    if (open(O, ">$configuration->{-htmlroot}/$outputfilename.bak"))
    {
	my ($out);
	$out = new Flutterby::Output::SHTMLProcessed
	    (
	     -classcolortags => $configuration->{-classcolortags},
	     -dbh => $dbh,
	     -variables => 
	     {
		 'article_ids' => $publishid,
	     },
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
	chmod 0775, "$configuration->{-htmlroot}/$outputfilename.bak";
	rename("$configuration->{-htmlroot}/$outputfilename.bak",
	       "$configuration->{-htmlroot}/$outputfilename");
    }
    else
    {
	print STDERR "Unable to open $configuration->{-htmlroot}/$outputfilename.bak\n";
    }
}

$dbh->disconnect;


#!/usr/bin/perl -w
use strict;
use lib '/home/flutterby/flutterby_cms/';
use DBI;
use Flutterby::Parse::Text;
use Flutterby::Parse::HTML;

my ($htmlparser, $textparser);
$htmlparser = new Flutterby::Parse::HTML;
$textparser = new Flutterby::Parse::Text;

sub RecurseTree($$$)
{
    my ($dbh, $article_id, $tree, $level) = @_;

    $level = 0 unless defined($level);

    while ($level < $#$tree)
    {
	if ($tree->[$level] eq '0')
	{
	}
	elsif ($tree->[$level] eq 'a' 
	       && defined($tree->[$level+1]->[0]->{'href'}))
	{
	    my ($sql,$url);

	    $url = $tree->[$level+1]->[0]->{'href'};
	    $url =~ s/^\//http:\/\/www.flutterby.com\//;;

	    $sql = 'INSERT INTO urls(url) VALUES ('
		.$dbh->quote($url).')';
	    $dbh->do($sql);
	    $sql = 'INSERT INTO urlsinarticle(url_id,article_id) VALUES ('
		.'(SELECT id FROM urls WHERE url='
		    .$dbh->quote($url)
			."),$article_id)";
	    $dbh->do($sql);
	}
	else
	{
	    &RecurseTree($dbh,$article_id,$tree->[$level + 1], 1);
	}
	$level += 2;
    }
}


my ($dbh,$sql,$sth,$id, $text, $texttype);
$dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
		    'danlyke',
		    'danlyke')
    or die $DBI::errstr;


$sql = "SELECT id, text, texttype FROM articles WHERE entered > now() - interval '1 day 30 minutes' OR updated > now() - interval '1 day 30 minutes'  ORDER BY id";

$sth = $dbh->prepare($sql)
    || die $dbh->errstr."\n$sql\n";

$sth->execute()
    || die $sth->errstr."\n$sql\n";

while (($id,$text,$texttype) = $sth->fetchrow_array)
{
    print "-- id: $id ".length($text)."\n";
    my ($tree);
    if ($texttype == 2)
    {
	$tree = $htmlparser->parse($text);
    }
    else
    {
	$tree = $textparser->parse($text);
    }
    if (defined($tree))
    {
	RecurseTree($dbh,$id,$tree);
    }
}
$dbh->disconnect();

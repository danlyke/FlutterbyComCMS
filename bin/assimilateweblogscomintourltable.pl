#!/usr/bin/perl -w
use strict;

use XML::Parser;
use HTTP::Date;
use DBI;
my ($dbh);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
}
sub END
{
    $dbh->disconnect;
}

use LWP::Simple;

my ($changesxmlurl);

foreach $changesxmlurl ('http://www.weblogs.com/changes.xml',
			'http://new.blogger.com/projects/fresh/changes.xml')
{
    my ($text);

    $text = get($changesxmlurl);
    die "unable to access url $!\n" unless ($text);

    my ($p, $tree);
    $p = new XML::Parser(Style=>'Tree');
    
    $tree = $p->parse($text);
    die unless $tree;

    if ($tree->[0] eq 'weblogUpdates')
    {
	my ($basetime) = str2time($tree->[1]->[0]->{'updated'});
	
	my ($i, $weblogs);
	$weblogs = $tree->[1];

	for ($i = 1; $i < $#$weblogs; $i += 2)
	{
	    if ($weblogs->[$i] eq 'weblog')
	    {
		my ($weblog,$sql,$url);
		$weblog = $weblogs->[$i + 1]->[0];
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
		    localtime($basetime - $weblog->{'when'});
		$year += 1900;
		$mon++;
		
		$url = $weblog->{'url'};
#		$sql = 'INSERT INTO urls (title,url) VALUES ('
#		    .$dbh->quote($weblog->{'name'})
#			.','.$dbh->quote($weblog->{'url'}).')';
#		$dbh->do($sql);
		$sql = sprintf("UPDATE urls SET lastupdate='%04.4d-%02.2d-%02.2d %02.2d:%02.2d:%02.2d' WHERE lower(url)=",
			       $year, $mon, $mday, $hour, $min, $sec)
		    .$dbh->quote(lc($url));
		$dbh->do($sql);
		
		if (defined($url))
		{
		    unless ($url =~ /\.(htm|html|php|php3|asp)$/i)
		    {
			unless ($url =~ /\/$/)
			{
			    $url .= '/';
			    $sql = sprintf("UPDATE urls SET lastupdate='%04.4d-%02.2d-%02.2d %02.2d:%02.2d:%02.2d' WHERE lower(url)=",
					   $year, $mon, $mday, $hour, $min, $sec)
				.$dbh->quote(lc($url));
			    $dbh->do($sql);
			}
			$url .= 'index.html';
			$sql = sprintf("UPDATE urls SET lastupdate='%04.4d-%02.2d-%02.2d %02.2d:%02.2d:%02.2d' WHERE lower(url)=",
				       $year, $mon, $mday, $hour, $min, $sec)
			    .$dbh->quote(lc($url));
			$dbh->do($sql);
		    }
		    else
		    {
			if ($url =~ s/index\.(html|htm|php|php3|asp)$//i)
			{
			    $sql = sprintf("UPDATE urls SET lastupdate='%04.4d-%02.2d-%02.2d %02.2d:%02.2d:%02.2d' WHERE lower(url)=",
					   $year, $mon, $mday, $hour, $min, $sec)
				.$dbh->quote(lc($url));
			    $dbh->do($sql);
			}
			if ($url =~ s/\/$//)
			{
			    $sql = sprintf("UPDATE urls SET lastupdate='%04.4d-%02.2d-%02.2d %02.2d:%02.2d:%02.2d' WHERE lower(url)=",
					   $year, $mon, $mday, $hour, $min, $sec)
				.$dbh->quote(lc($url));	
			    $dbh->do($sql);
			}
		    }
		}
	    }
	}
    }
}

#str2time




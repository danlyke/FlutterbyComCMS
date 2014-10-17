#!/usr/bin/perl -w
use strict;

use DBI;
my ($dbh);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=weblog',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
}
sub END
{
    $dbh->disconnect;
}


my ($sth, $row);
$sth = $dbh->prepare('SELECT * FROM urls');
$sth->execute;
while ($row = $sth->fetchrow_hashref())
{
    if (defined($row->{'lastupdate'}))
    {
	my ($url, $sql);
	$url = $row->{'url'};

	unless ($url =~ /\.(htm|html|php|asp)$/i)
	{
	    unless ($url =~ /\/$/)
	    {
		$url .= '/';
		$sql = "UPDATE urls SET lastupdate='$row->{'lastupdate'}' WHERE lower(url)=".$dbh->quote(lc($url));
		$dbh->do($sql);
	    }
	    $url .= 'index.html';
	    $sql = "UPDATE urls SET lastupdate='$row->{'lastupdate'}' WHERE lower(url)=".$dbh->quote(lc($url));
	    $dbh->do($sql);
	}
	else
	{
	    if ($url =~ s/index\.(html|htm|php|asp)$//)
	    {
		$sql = "UPDATE urls SET lastupdate='$row->{'lastupdate'}' WHERE lower(url)=".$dbh->quote(lc($url));
		$dbh->do($sql);
	    }
	    if ($url =~ s/\/$//)
	    {
		$sql = "UPDATE urls SET lastupdate='$row->{'lastupdate'}' WHERE lower(url)=".$dbh->quote(lc($url));
		$dbh->do($sql);
	    }
	}
    }
}

#!/usr/bin/perl -w
use strict;
use DBI;
use LWP::UserAgent;

my ($dbh);
$dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
		    'danlyke',
		    'danlyke')
    or die $DBI::errstr;

my ($sql, $sth, $row);

$sql = 'SELECT * FROM trackbacks WHERE checked IS NULL';

$sth = $dbh->prepare($sql)
    || die "$sql\n".$dbh->errstr;
$sth->execute
    || die "$sql\n".$sth->errstr;

my ($ua);
$ua = LWP::UserAgent->new(agent => 'FlutterbyTrackbackChecker/0.01');
			  
while ($row = $sth->fetchrow_hashref)
{
    my ($response);

    $response = $ua->get($row->{'url'});
    if ($response->is_success)
    {
	if ($response->content 
	    =~ /http:\/\/[a-z\.]*flutterby.com\/archives\/[a-z\.\?\/]*$row->{'entry_id'}/)
	{
	    $sql = 'UPDATE trackbacks SET checked=NOW(), approved=TRUE WHERE id='
	    .$dbh->quote($row->{'id'});
	}
	else
	{
	    $sql = 'UPDATE trackbacks SET checked=NOW(), approved=FALSE WHERE id='
	    .$dbh->quote($row->{'id'});
	}
	print "$sql\n";
	$dbh->do($sql);
    }
}

$dbh->disconnect;

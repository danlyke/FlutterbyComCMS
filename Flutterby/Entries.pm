#!/usr/bin/perl -w
use strict;
package Flutterby::Entries;
use Flutterby::Util;
use URI::Escape;
use LWP::Simple;
use File::Temp;
use vars qw(%webloginfocache %weblogurlcache);


my $secretsalt = 'aachatahsooxeeng7lo5aifietahphuN';
# See comments below


sub GetCache
{
    my ($dbh, $where_clause) = @_;


    my $sql = 'SELECT text FROM blogentrycache WHERE where_clause='
        .$dbh->quote($where_clause)
        .' LIMIT 1';
    
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    if (my $row = $sth->fetchrow_arrayref())
    {
        return $row->[0];
    }
    return undef;
}

sub SetCache
{
    my ($dbh, $where_clause, $from_date, $to_date, $text) = @_;
    my $sql = 'INSERT INTO blogentrycache(where_clause, from_date, to_date, text) VALUES ('
        .join(', ',
              map { $dbh->quote($_) }
              ($where_clause, $from_date,$to_date,$text))
        .')';
    unless ($dbh->do($sql))
    {
        $sql = 'UPDATE blogentrycache SET text='
            .$dbh->quote($text)
            .' WHERE where_clause='
            .$dbh->quote($where_clause);
        $dbh->do($sql);
    }
}

sub InvalidateCache
{
    my ($dbh, @ids) = @_;

    my $sql = 'SELECT entered FROM blogentries WHERE id IN ('
        .join (',', map {$dbh->quote($_);} @ids).')';
    
    my $sth = $dbh->prepare($sql);
    $sth->execute();

    my @sqls;
    
    while (my $row = $sth->fetchrow_arrayref)
    {
        push @sqls, 'DELETE FROM blogentrycache WHERE from_date <= '
            .$dbh->quote($row->[0])
            .' AND to_date >= '
            .$dbh->quote($row->[0]);
    }
    for (@sqls)
    {
        $dbh->do($_);
    }
}

1;

__END__

=head1 NAME

Flutterby::Entries - Manage users in the Flutterby CMS schema

=head1 SYNOPSIS
    
 use Flutterby::Entries;

 $fcmsweblog_id = Flutterby::Entries::GetWeblogID($cgi->url(), $dbh);
 
=head1 DESCRIPTION

The C<Flutterby::Entries> class is a wrapper for a bunch of functions
that do oft-repeated user tasks on the Flutterby schema.

=head2 GetWeblogID

C<Flutterby::Entries::GetWeblogID> is a stub function which needs
development. It's based on Mark Hershberger's modification of the
schema to allow multiple weblogs, and it's this that will somehow
extract from the URL information about which weblog is being
accessed. For now it just returns "1".


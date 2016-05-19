#!/usr/bin/perl -w
use strict;
use CGI;
use DBI;
use lib 'flutterby_cms';
use Flutterby::Users;
#use CGI::Carp qw(fatalsToBrowser);
use vars qw($configuration);
use Flutterby::Config;
$configuration ||= Flutterby::Config::load();
use Flutterby::HTML;
use Flutterby::Output::HTMLProcessed;

sub main($)
  {
    my ($dbh) = @_;
    my ($cgi);
    $cgi = CGI->new(); $cgi->charset('utf-8');
    my ($cookie);
    $cookie = $cgi->cookie(-name=>'id',
			   -value=>'',
			   -path=>'/');
    print $cgi->header(-cookie => $cookie, -type=>'text/html', -charset=>'utf-8');
    print '<!DOCTYPE html>';
    my ($tree) = 
      Flutterby::HTML::LoadHTMLFileAsTree($configuration->{-htmlpath}.'logout.html');
    my ($variables);
    $variables = Flutterby::Users::GetWeblogInfo($cgi, $dbh);
    my ($out);
    $out = new Flutterby::Output::HTMLProcessed
      (
	       -variables => $variables,
	   -classcolortags => $configuration->{-classcolortags},
	   -colorschemecgi => $cgi,
      );
    $out->output($tree);
  }
my $dbh = DBI->connect($configuration->{-database},
			$configuration->{-databaseuser},
			$configuration->{-databasepass})
      or die DBI::errstr;
$dbh->{AutoCommit} = 1;

main($dbh);
$dbh->disconnect;

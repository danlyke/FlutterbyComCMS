#!/usr/bin/perl -w
use strict;
use CGI qw/-utf8/;
#use CGI::Carp qw(fatalsToBrowser);
use DBI;
use lib 'flutterby_cms';
use vars qw($configuration);
use Flutterby::Config;
$configuration ||= Flutterby::Config::load();
use Flutterby::HTML;
use Flutterby::Output::HTMLProcessed;
use Flutterby::Parse::HTML;
use Flutterby::Parse::Text;
use Flutterby::Parse::String;
use Flutterby::Parse::FullyEscapedString;
use Flutterby::Users;
use Flutterby::Util;
use Flutterby::DBUtil;

sub main
  {
    my ($cgi, $dbh,$userinfo,$loginerror);
    $dbh = DBI->connect($configuration->{-database},
			$configuration->{-databaseuser},
			$configuration->{-databasepass})
      or die $DBI::errstr;
$dbh->{AutoCommit} = 1;
    $cgi = CGI->new(); $cgi->charset('utf-8');

    ($userinfo,$loginerror) = Flutterby::Users::CheckLogin($cgi,$dbh);

    if (defined($userinfo->{'id'}))
      {
	my ($tree) = 
	  Flutterby::HTML::LoadHTMLFileAsTree($configuration->{-htmlpath}.'editcomment.html');
    
	my ($query);
	$query = join(' OR ',
		      map
		      {
			'articles.id='.$dbh->quote($_);
		      } (split (/\,/,$cgi->param('commentid'))))
	  if (defined($cgi->param('commentid')));

	my ($commentid);
	$commentid = $cgi->param('commentid');
	my ($variables);
	$variables = Flutterby::Users::GetWeblogInfo($cgi, $dbh);
	$variables->{'textentryrows'} = $userinfo->{'textentryrows'} || 16;
	$variables->{'textentrycols'} = $userinfo->{'textentrycols'} || 80;
	$variables->{'blogcomments_id'} = $commentid;
	$variables->{'queryterms'} = $query;

	my ($out);
	$cgi->param('commentid' => undef);
	$out = new Flutterby::Output::HTMLProcessed
	  (
	   -classcolortags => $configuration->{-classcolortags},
	   -colorschemecgi => $cgi,
	   -dbh => $dbh,
	   -variables => $variables,
	   -textconverters => 
	   { 
	    1 => new Flutterby::Parse::Text,
	    2 => new Flutterby::Parse::HTML,
	    'escapehtml' => new Flutterby::Parse::String,
	    'edithtml' => new Flutterby::Parse::FullyEscapedString,
	   },
	   -cgi => $cgi
	  );
	$out->output($tree);

    my $sql = "SELECT weblogcomments.entry_id AS blogentry_id FROM users, articles, weblogcomments WHERE ($query) AND ( articles.author_id=users.id AND weblogcomments.article_id=articles.id)";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_arrayref)
    {
        Flutterby::Entries::InvalidateCache($dbh, $row->[0]);
    }
    

      }
    else
      {
	Flutterby::Users::PrintLoginScreen($configuration,
					   $cgi, 
					   $dbh, 
					   './editcomment.cgi',
					   $loginerror);
      }
    $dbh->disconnect;
  }
&main;

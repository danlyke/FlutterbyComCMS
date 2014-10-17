#!/usr/bin/perl -w
use strict;
use DBI;
use DB_File;

use lib './flutterby_cms';
use Flutterby::Util;
my ($delwordlistdirectory) = './searchgdbm';

my (%wordlist);

my ($tableUrlsToId,$tableIdsToUrl,$tableWords);

sub AllocateHash($)
  {
    my ($filename) = @_;
    my (%h);
    tie(%h, 'DB_File', 
	$filename, 
	O_RDWR, 0644)
      ||
    tie(%h, 'DB_File', 
	$filename, 
	O_CREAT | O_RDWR, 0644)
      || die "dbcreat $filename $!\n";
    return \%h;
  }

$tableUrlsToId = AllocateHash('search_urlstoid.db')
  unless defined($tableUrlsToId);
$tableIdsToUrl = AllocateHash('search_idstourl.db')
  unless defined($tableIdsToUrl);
$tableWords = AllocateHash('search_words.db')
  unless defined($tableWords);;

if (!$tableIdsToUrl->{'** high count **'})
  {
    $tableIdsToUrl->{'** high count **'} = 1;
  }


sub BEGIN
{

}

sub END
{
}


sub AddDocument($$)
  {
    my ($document,$title) = @_;
    my ($id,$newtitle,$updated);
    ($id,$newtitle,$updated) = split /\x01/, $tableUrlsToId->{$document}
      if (defined($tableUrlsToId->{$document}));
    unless ($id)
      {
	$id = $tableIdsToUrl->{'** high count **'};
	$tableIdsToUrl->{'** high count **'} = $id + 1;
	$tableIdsToUrl->{$id} = "$document\x01$title";
	my ($filetime);
	$filetime = Flutterby::Util::UnixTimeAsISO8601(time());
	$tableUrlsToId->{$document} = "$id\x01$title\x01$filetime";
      }
    return $id;
  }

sub AddWords($$)
  {
    my ($document,$text) = @_;
    my (@words,%words,$i);
    @words = map {uc($_)} split (/[\W_]+/,$text);
    for ($i = 0; $i < $#words; $i++)
      {
	my ($word) = uc($words[$i]);
	$words{$word} = 0 unless ($words{$word});
	$words{$word} |= (1 << ($i % 16));
      }
    foreach (keys %words)
      {
	my (%h);
	if (defined($tableWords->{$_}))
	  {
	    %h = unpack ('S*',$tableWords->{$_});
	  }
	$h{$document} = 0 unless defined($h{$document});
	$h{$document} = $words{$_};
	$tableWords->{$_} = pack ('S*', %h);
      }
  }

use Time::Local 'timelocal';

sub IndexDocument($$$$)
  {
    my ($document, $time, $title, $text) = @_;
    my ($id,$newtitle,$lastindexed);
    ($id,$newtitle,$lastindexed) = split /\x01/, $tableUrlsToId->{$document}
      if (defined($tableUrlsToId->{$document}));

    $id = AddDocument($document,$title)
      unless (defined($id));
    if ($id)
      {
	$lastindexed = '0000-00-00 00:00:00' unless (defined($lastindexed));
	print "Comparing $time with $lastindexed\n";
	if ($time gt $lastindexed)
	  {
	    mkdir $delwordlistdirectory unless (-d $delwordlistdirectory);
	    my $cachefilename = $document;
	    $cachefilename =~ s/[\/\&]/\.\./g;
	    $cachefilename = "$delwordlistdirectory/$cachefilename";
	    if (open(I,$cachefilename)
		or (-f "$cachefilename.gz" 
		    and open(I, "gunzip -- < $cachefilename.gz|")))
	      {
		while (<I>)
		  {
		    chop;
		    my (%h);
		    if (defined($tableWords->{$_}))
		      {
			%h = unpack ('S*',$tableWords->{$_});
			delete ($h{$document});
			$tableWords->{$_} = pack ('S*', %h);
		      }
		  }
		close I;
	      }
	    if (open(O,"|gzip > $cachefilename.gz")
		or open(O, "$cachefilename"))
	      {
		my (%h);
		foreach (map {uc($_)} split (/[\W_]+/,$text))
		  {
		    $h{$_} = 1;
		  }
		foreach (keys %h)
		  {
		    print O "$_\n";
		  }
		close O;
	      }
#	    $dbh->do('DELETE FROM searchurlwords WHERE url_id='.$dbh->quote($id));
	    AddWords($id,$text);
	  }
      }
  }


my ($parserinfo) = {};

sub HTMLStart
  {
    my ($tagname,$attr) = @_;
    if ($tagname eq 'a' && defined($attr->{'href'}))
      {
	my ($url) = $attr->{'href'};
	$parserinfo->{-text} .= ' '.$url;
	my ($base) = $parserinfo->{-base};
	$base =~ s/\/[^\/]+$//;
	$base .= '/' unless (substr($base,-1,1) eq '/');
	if ((substr($url,0,length($parserinfo->{-site})) eq $parserinfo->{-site})
	    or ($url !~ /^\w+\:/))
	  {
	    $url =~ s/^\.\///;
	    while ($url =~ s/^\.\.//i)
	      {
		$base =~ s/^(.*\/)[\^\/]+\/$/$1/i;
	      }
	    $url =~ s/^\///;
	    push @{$parserinfo->{-documents}},$base.$url
	      unless $parserinfo->{-documentsadded}->{$base.$url};
	    $parserinfo->{-documentsadded}->{$base.$url} = 1;
	  }
      }
    elsif ($tagname eq 'title')
      {
	  print "In title\n";
	$parserinfo->{-title} = '';
	$parserinfo->{-intitle} = 1;
      }
    elsif ($tagname eq 'img' && defined($attr->{'alt'}))
      {
	$parserinfo->{-text} .= ' '.$attr->{'alt'};
      }
    $parserinfo->{-text} .= ' ';
  }
sub HTMLEnd
  {
    my ($tagname) = @_;
    $parserinfo->{-text} .= ' ';
    if ($tagname eq 'title')
    {
	print "Got title $parserinfo->{-title}\n";
	delete ($parserinfo->{-intitle});
    }
  }
sub HTMLText
  {
    my ($text) = @_;
    if (defined($text))
      {
	$parserinfo->{-title} .= $text if ($parserinfo->{-intitle});
	$parserinfo->{-text} .= $text;
      }
  }

use LWP::RobotUA;
use HTML::Parser;
my ($site) = 'http://exlunatest.coyotegrits.net/';
my ($documentroot) = '/var/www/exluna/';
my (@documents) = $site;
my (%documentsadded);
my (%documentssearched);

use File::Find;
sub wanted
  {
    if (/\.htm(l?)$/)
      {
	my ($filename,$filetime);
	$filename = $File::Find::name;
	$filetime = Flutterby::Util::UnixTimeAsISO8601((stat($filename))[9]);

	my ($parser);
	$parser = new HTML::Parser(api_version => 3,
				   start_h => [\&HTMLStart, "tagname, attr"],
				   end_h   => [\&HTMLEnd,   "tagname"],
				   text_h   => [\&HTMLText,   "text"],	
				   marked_sections => 1,
				  );
	my ($document) = $filename;
	$document =~ s/^$documentroot/$site/;
	$parserinfo = 
	  {
	   -site => $site,
	   -base => '',
	   -documentsadded => \%documentsadded,
	   -documents => \@documents,
	   -text => '',
	   -title => $document,
	  };
	$parser->parse_file($filename);

	IndexDocument($document,
		      $filetime,
		      $parserinfo->{-title},
		      $parserinfo->{-text});
      }
  }

if (1)
  {
    find(\&wanted, $documentroot);
  }
if (0)
  {
    my ($ua) = new LWP::UserAgent('flutterby-search/0.1','danlyke@flutterby.com');

    $documentsadded{$site} = 1;

    while ($#documents >= 0)
      {
	my ($document,$request,$response);
	my ($parser);
	$document = shift(@documents);
	print "Searching $document\n";
	$documentssearched{$site} = 1;
	$request = HTTP::Request->new('GET', $document);
	$response = $ua->request($request);
	if ($response)
	  {
	    print "Got $document with $response\n";
	    $parser = new HTML::Parser(api_version => 3,
				       start_h => [\&HTMLStart, "tagname, attr"],
				       end_h   => [\&HTMLEnd,   "tagname"],
				       text_h   => [\&HTMLText,   "text"],	
				       marked_sections => 1,
				      );
	    $parserinfo = 
	      {
	       -site => $site,
	       -base => $response->base,
	       -documentsadded => \%documentsadded,
	       -documents => \@documents,
	       -text => '',
	       -title => $document,
	      };
	    $parser->parse($response->content());
	    print "Indexing $parserinfo->{-text}\n";
	    IndexDocument($document,
			  '0000-00-00 00:00:00',
			  $parserinfo->{-title},
			  $parserinfo->{-text});
	  }
      }
  }

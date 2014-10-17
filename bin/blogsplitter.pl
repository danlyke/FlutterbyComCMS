#!/usr/bin/perl -w
use strict;
use lib '/home/danlyke/websites/flutterby.com/flutterby_cms/';
use LWP::RobotUA;
use DBI;

sub GetDocument($)
{
    my ($url) = @_;
    my ($ua, $request, $response);
    $ua = new LWP::UserAgent;
    $ua->agent("Flutterby.com:SimilarityChecker/0.1 ".$ua->agent);
    
    $request = HTTP::Request->new('GET', $url);
    
    $response = $ua->request($request);
    
    if ($response->is_success)
    {
#	print "Code:\n".$response->code."\n";
#	print "Message:\n".$response->message."\n";
#	print "Headers:\n".$response->headers."\n";
#	print "Content:\n".$response->content."\n";
	return $response->content;
    }
}

#    'camworld.html',
#    'genehack.html',
#    'scriptingnews.html',
#    'flutterby.html',

my ($bloginfo) = {
    "David Chess" =>
    {
	-cachefile => 'davidchess.html',
	-url => 'http://www.davidchess.com/words/log.html',
	-archivebaseurl => 'http://www.davidchess.com/words/',
	-documentstart => '\<a name\=\".*\"\>\<b\>(.*? 200[0-9])\<\/b\>\<\/a\>',
	-entryseparator => '\<a name\=\".*\"\>\<b\>(.*? 200[0-9])\<\/b\>\<\/a\>',
	-permalink => '\&nbsp\;\<a href\=\"(log.200.*?)\"\>\<img',
	-documentend => 'earlier entries',
    },
    "Justin's Journal" =>
    {
	-cachefile => 'justinsjournal.html',
	-url => 'http://www.dallasbay.net/journal/journal.php',
	-archivebaseurl => 'http://www.dallasbay.net/journal/',
	-documentstart => '\<div class\=\"blogentry\"\>',
	-entryseparator => '\<div class\=\"blogentry\"\>',
	-permalink => '\<h5\>\<a href\=\"(index.php?archive.*?)\"\>(.*?)\<\/h5\>',
	-documentend => 'Justin Thyme Productions',
    },
    'Backup Brain' =>
    {
	-cachefile => 'backupbrain.html',
	-url => 'http://www.backupbrain.com/',
	-archivebaseurl => 'http://www.backupbrain.com/',
	-documentstart => '\</SCRIPT',
	-entryseparator => '\<script\>if\(canEdit\[\d+\]\) document\.write',
	-permalink => '\>posted by .*?\<a href\=\"(.*?archive.html\#.*?)\"\>Link\<\/a\>',
	-documentend => '\<h3\>The Daily Grind\<\/h3\>',
    },
    'Whump/MoreLikeThis' =>
    {
	-cachefile => 'whump.html',
	-url => 'http://www.whump.com/moreLikeThis/index.php3',
	-archivebaseurl => 'http://www.whump.com/moreLikeThis/',
	-entryseparator => '\<div class\=\"title\"\>\<strong\>(.*?)\<\/strong\>\<\/div\>',
	-permalink => '\<span class\=\"permalink\"\>\<a href\=\"(.*?)\"\>PermaLink\<\/a\>\<\/span\>',
	-documentend => '\<p class\=\"note\"\>Annotating the WWW since 1998\.\<\/p\>',
    },
    'markpasc.blog' =>
    {
	-cachefile => 'markpasc.html',
	-url => 'http://www.markpasc.org/blog/',
	-archivebaseurl => 'http://www.markpasc.org/blog/',
	-documentstart => '\<h3 class\=\"day\">\<a .*?\>\&lt\;\<\/a\>\s*.*?\<a .*?\>\&gt\;\<\/a\>\<\/h3\>',
	-entryseparator => '\<\!\-\- item',
	-permalink => '\<span class\=\"when\"\>\<a href\=\"(.*?)" title\=\"Permanent link to this item\"\>',
	-documentend => '\<p class\=\"footer\"\>Last updated ',
    },
#    'dazereader.html' =>
#    {
#	-entryseparator => '\<p class\=\"date\"\>(.*?)\<\/p\>',
#	-documentend => '\<p\>\<a class\=\"next\" href\=\"archive',
#    },
    'Scripting News' =>
    {
	-cachefile => 'scriptingnews.html',
	-url => 'http://www.scripting.com/',
	-documentstart => '\<tr bgcolor\=\"\#000000\"\>\s*\<td colspan\=\"2\"\>\<font color\=\"\#F5F5F5\"\>\&nbsp\;\<b\>.*?\</b\>',
	-entryseparator => 'src\=\"http\:\/\/www\.scripting\.com\/images\/2001\/09\/20\/sharpPermaLink3.gif"',
	-permalink => '\&nbsp\;\<a href\=\"(http\:\/\/scriptingnews\.userland\.com\/backissues\/.*?)\"\s*title\=\"Permanent',
	-documentend => '\<font size=\"\-1\"\>\<b\>Last update\<\/b\>\: ',
    },
    'Pursed Lips' => 
    {
	-cachefile => 'pursedlips.html',
	-url => 'http://www.section12.com/users/debrahyde/',
	-entryseparator => '\<b\>\<font\s+size\=\"2\"\s+color\=\"330099\"\>(.*?)\<\/font\>\<\/b\>\<br\>',
	-permalink => '\<a.*?\shref=\"(.*?)\".*?\>discuss this entry\<\/a\>',
	-documentend => '\<small\>\<a\s+href\=\"index.cfm.*?\"\>older\&nbsp\;entries\<\/a\>',
    },
 };




my ($dbh,$sql);
$dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
		    'danlyke',
		    'danlyke')
    or die $DBI::errstr;

my ($sitetitle, $sitedata);
my ($ua, $request, $response);
$ua = new LWP::RobotUA 'Flutterby.com-SimilarityChecker/0.1',
    'danlyke@flutterby.com';

while (($sitetitle, $sitedata) = each %$bloginfo)
{
    my ($documentstart, $entryseparator, $archivelink, $entriesend);
    $entryseparator = $sitedata->{-entryseparator};
    $archivelink = $sitedata->{-permalink};
    $entriesend = $sitedata->{-documentend};
    if (defined($sitedata->{-documentstart}))
    {
	$documentstart = $sitedata->{-documentstart};
    }
    else
    {
	$documentstart = $entryseparator;
    }
    my ($t);

   
    $response = $ua->mirror($sitedata->{-url},
			    '/home/danlyke/websites/flutterby.com/var/blogsplitter/'
			    .$sitedata->{-cachefile});
    
    if ($response->is_success)
    {
#	print "Code:\n".$response->code."\n";
#	print "Message:\n".$response->message."\n";
#	print "Headers:\n".$response->headers."\n";
#	print "Content:\n".$response->content."\n";
	$t = $response->content;
    }


    if (defined($t) && $t =~ s/^.*?$documentstart//s)
    {
	my ($entryname);
	$entryname = $1;

	while ($t =~ s/^(.*?)$entryseparator//s)
	{
	    my ($nextentryname, $entrytext, @links,$entrylink);
	    $nextentryname = $2;
	    $entrytext = $1;

	    if ($entrytext =~ s/$archivelink//s)
	    {
		$entrylink = $1;
		$entryname = $2 if (defined($2));
	    }
	    while ($entrytext =~ s/href=[\"\'](.*?)[\"\']//)
	    {
		push @links, $1;
	    }
	    $entryname = '' unless defined($entryname);
	    $entrylink = $sitedata->{-archivebaseurl}.$entrylink 
		if (defined($sitedata->{-archivebaseurl}));
	    $entryname = "$sitedata->{-title} $entryname"
		unless $entryname ne '';

	    if ($#links >= 0 && defined($entrylink))
	    {
		$sql = 'INSERT INTO urls(title,url) VALUES ('
		    .$dbh->quote($entryname).','
			.$dbh->quote($entrylink).')';
		$dbh->do($sql);
		my ($link);
		foreach $link (@links)
		{
		    if ($link =~ /^http\:/)
		    {
			$sql = 'INSERT INTO urls(url) VALUES ('
			    .$dbh->quote($link).')';
			$dbh->do($sql);
			$sql = 'INSERT INTO urlsinurl(baseurl_id,referenceurl_id) '
			    .'VALUES ((SELECT id FROM urls WHERE url='
				.$dbh->quote($entrylink)
				    .'), (SELECT id FROM urls WHERE url='
					.$dbh->quote($link).'))';
			$dbh->do($sql);
		    }
		}
	    }
	    $entryname = $nextentryname
		if (defined($nextentryname));
	}
	if ($t =~ s/^(.*?)$entriesend//s)
	{
	    my ($entrytext, @links,$entrylink);
	    $entrytext = $1;
	    if ($entrytext =~ s/$archivelink//)
	    {
		$entrylink = $1;
		$entryname = $2 if (defined($2));
	    }
	    while ($entrytext =~ s/href=\"(.*?)\"//)
	    {
		push @links, $1;
	    }
	    $entryname = '' unless defined($entryname);
	    $entrylink = $sitedata->{-archivebaseurl}.$entrylink 
		if (defined($sitedata->{-archivebaseurl}));
	    $entrylink =~ s/\/\/+/\//g;
	    $entryname = "$sitedata->{-title} $entryname"
		unless $entryname ne '';

	    if ($#links >= 0 && defined($entrylink))
	    {
		$sql = 'INSERT INTO urls(title,url) VALUES ('
		    .$dbh->quote($entryname).','
			.$dbh->quote($entrylink).')';
		$dbh->do($sql);
		my ($link);
		foreach $link (@links)
		{
		    if ($link =~ /^http\:/)
		    {
			$sql = 'INSERT INTO urls(url) VALUES ('
			    .$dbh->quote($link).')';
			$dbh->do($sql);
			$sql = 'INSERT INTO urlsinurl(baseurl_id,referenceurl_id) '
			    .'VALUES ((SELECT id FROM urls WHERE url='
				.$dbh->quote($entrylink)
				    .'), (SELECT id FROM urls WHERE url='
					.$dbh->quote($link).'))';
			$dbh->do($sql);
		    }
		}
	    }
	}

    }
    else
    {
    }
}
#    my ($p,$tree);
#    $p = new Flutterby::Parse::HTML;
#    $tree = $p->parsefile($filename);
#    print Dumper($tree);
#    DumpTree($tree);


$dbh->disconnect;


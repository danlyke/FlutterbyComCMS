#!/usr/bin/perl -w
use strict;
use Net::NNTP;
use lib 'flutterby_cms';

use Flutterby::HTML;
use Flutterby::Output::HTML;
use Flutterby::Parse::HTML;
use Flutterby::Parse::Text;
use Flutterby::Tree::Find;


use DBI;
my ($dbh,$nntp);
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












sub FixURLReferences($$)
{
    my ($fixwith, $tree) =@_;

    my ($i);

    for ($i = ref($tree->[0]) eq 'HASH' ? 1 : 0; $i < scalar(@$tree); $i+=2)
    {
	if ($tree->[$i] eq '0')
	{
	}
	else
	{
	    if ($tree->[$i] eq 'img'
		&& $tree->[$i+1]->[0]->{'src'} =~ /^\//)
	    {
		$tree->[$i+1]->[0]->{'src'} =
		    $fixwith.$tree->[$i+1]->[0]->{'src'};
	    }
	    if ($tree->[$i] eq 'a'
		&& $tree->[$i+1]->[0]->{'href'} =~ /^\//)
	    {
		$tree->[$i+1]->[0]->{'href'} =
		    $fixwith.$tree->[$i+1]->[0]->{'href'};
	    }
	    &FixURLReferences($fixwith, $tree->[$i+1]);
	}
    }

}


sub WriteMessage($$$$@)
{
    my ($nntp,$dbh, $row,$messageid, $replyto) = @_;
    $replyto = '' unless defined($replyto);
    my ($message, $identity);
    $identity = $row->{'name'};
    if ($row->{'showemailinnntpversion'})
    {
	$identity .= " <$row->{'email'}>";
    }
    else
    {
	$identity .= " <prefersanonymity_$row->{'user_id'}\@flutterby.com>"
    }

    my ($formatters);
    $formatters =
    {
	1 => new Flutterby::Parse::Text,
	2 => new Flutterby::Parse::HTML,
    };
    my ($tree, $htmlmessage, $out);
    $tree = $formatters->{$row->{'texttype'}}->parse($row->{'text'});
    FixURLReferences('http://www.flutterby.com',$tree);
    $out = new Flutterby::Output::HTML
	(
	 -variables => {},
	 -textconverters => $formatters,
	 );
    $htmlmessage = '';

    my ($bodynode);
    $bodynode = Flutterby::Tree::Find::nodeChildInfo($tree, 'body');
    if (defined($bodynode))
    {
	my ($attrs, $newtree);
	$attrs = shift @$bodynode;
	$newtree = [{'class' => 'weblogmeta'},
		    '0', 'From the weblog entry at ',
		    'a',
		    [
		     {'class' => 'weblogmeta', 
		      'href' => "http://www.flutterby.com/archives/comments/$row->{'entry_id'}.html"
		      },
		     '0',
		     "http://www.flutterby.com/archives/comments/$row->{'entry_id'}.html"
		     ],
		    ];
	unshift @$bodynode, $attrs, 'p', $newtree;
    }

    $out->setOutput(\$htmlmessage);
    $out->output($tree);

    my ($messagebody);
    $messagebody =<<EOF;
--------------070800090206070100060108
Content-Type: text/plain; charset=us-ascii; format=flowed
Content-Transfer-Encoding: 7bit

EOF
    while ($row->{'text'} =~ s/^(.{1,78}\s|.{1,78}WAR\-|.*?\s)//s)
    {
	$messagebody .= "$1\n";
    }
    $messagebody .= $row->{'text'};

    $messagebody .=<<EOF;


--------------070800090206070100060108
Content-Type: text/html; charset=us-ascii
Content-Transfer-Encoding: 7bit

<!DOCTYPE html>
EOF

    while ($htmlmessage =~ s/^(.{1,78}\s|.{1,78}WAR\-|.*?\s)//s)
    {
	$messagebody .= "$1\n";
    }
    $messagebody .= "$htmlmessage\n\n";
    

    $message = <<EOF;
From: $identity
Message-ID: $messageid
Subject: \[Entry \#$row->{'entry_id'}\] $row->{'subject'}
Newsgroups: flutterby.weblogentries,flutterby.all,flutterby.blogs.all,flutterby.blogs.flutterby$replyto
Mime-Version: 1.0
Content-Type: multipart/alternative;
 boundary="------------070800090206070100060108"

$messagebody
EOF
    $nntp->post($message)
	|| die "Unable to post\n\n$message\n";
    my ($sql);
    $sql = 'UPDATE articles SET messageid='
	.$dbh->quote($messageid)
	    .' WHERE id='.$row->{'id'};
    $dbh->do($sql)
	|| die $dbh->errstr."\n$sql\n";
    print "Updated $row->{'entry_id'} $row->{'subject'} $messageid\n";
}


my ($sql, $sth, $row);


my (%passwordlist);
$sql = 'SELECT email, password FROM users';
$sth = $dbh->prepare($sql)
    || die $dbh->errstr."\n\n$sql\n";
$sth->execute
    || die $sth->errstr."\n\n$sql\n";
while ($row = $sth->fetchrow_arrayref)
{
    if (defined($row->[0]) && $row->[0] !~ /\s/s)
    {
	if (defined($passwordlist{$row->[0]}))
	{
	    $passwordlist{$row->[0]} = '';
	}
	else
	{
	    $passwordlist{$row->[0]} = $row->[1];
	}
    }
}

if (open O, '>/var/lib/news/db/newsusers')
{
    my ($user,$passwd);
    my @alphabet = ('.', '/', 0..9, 'A'..'Z', 'a'..'z');

    print O "genehack\@genehack.org:iCfcutBsc/GJE\n";

    while (($user,$passwd) = each %passwordlist)
    {
	if ($user ne '' && $passwd ne '')
	{
	    my $salt = join '', @alphabet[rand 64, rand 64];
	    print O "$user:".crypt ($passwd, $salt)."\n";
	}
    }
    close O;
}


$sql = 'SELECT '
    .join(', ',
	  'articles.id AS id',
	  "coalesce(articles.title,'') AS subject",
	  'articles.text AS text',
	  'coalesce(articles.texttype,1) AS texttype',
	  'weblogentries.id AS entry_id',
	  'users.name AS name',
	  'users.email AS email',
	  'users.showemailinnntpversion AS showemailinnntpversion',
	  'users.id AS user_id'
	  )
    .' FROM users, articles, weblogentries '
    .' WHERE '
    .join(' AND ',
	  'articles.author_id=users.id',
	  'weblogentries.article_id=articles.id',
	  'messageid IS NULL')
    .' ORDER BY id';

$sth = $dbh->prepare($sql)
    || die $dbh->errstr."\n$sql\n";
$sth->execute
    || die $sth->errstr."\n$sql\n";

$nntp = Net::NNTP->new('localhost',
		       Reader => 1,
#		       Debug => 1,
		       );
$nntp->authinfo('danlyke@flutterby.com','r2d2c3po');


while ($row = $sth->fetchrow_hashref)
{
    my $messageid;
    $messageid = "<flutterbycomweblogentry\$$row->{'entry_id'}\@mail.flutterby.com>";
    WriteMessage($nntp,$dbh,$row,$messageid);
}




$sql = 'SELECT '
    .join(', ',
	  'articles.id AS id',
	  "coalesce(articles.title,'') AS subject",
	  'articles.text AS text',
	  'articles.title AS subject',
	  'coalesce(articles.texttype,1) AS texttype',
	  'weblogcomments.entry_id AS entry_id',
	  'users.name AS name',
	  'users.email AS email',
	  'users.showemailinnntpversion AS showemailinnntpversion',	
	  'users.id AS user_id',
	  )
    .' FROM users, articles, weblogcomments '
    .' WHERE '
    .join(' AND ',
	  'articles.author_id=users.id',
	  'weblogcomments.article_id=articles.id',
	  'messageid IS NULL')
    .' ORDER BY id';

$sth = $dbh->prepare($sql)
    || die $dbh->errstr."\n$sql\n";
$sth->execute
    || die $sth->errstr."\n$sql\n";

while ($row = $sth->fetchrow_hashref)
{
    my $messageid;
    $messageid = "<flutterbycomweblogcomment\$$row->{'id'}\@mail.flutterby.com>";
    WriteMessage($nntp,$dbh,$row,$messageid,"\nReferences: <flutterbycomweblogentry\$$row->{'entry_id'}\@mail.flutterby.com>");

}




my ($lastcheckdate, $thischeckdate);
$lastcheckdate = 0;
if (open(I,"$ENV{'HOME'}/var/nntptoflutterbycomments"))
{
    $lastcheckdate = <I>;
    close I;
}
else
{
    print "Unable to open $ENV{'HOME'}/var/nntptoflutterbycomments, using 0 for time\n";
}
$thischeckdate = $nntp->date();

my ($newarticles, $article);
$newarticles = $nntp->newnews($lastcheckdate, 'flutterby.weblogentries');

foreach $article (@$newarticles)
{
    unless ($article =~ /^\<flutterbycomweblogcomment\$\d+\@/
	        || $article =~ /^\<flutterbycomweblogentry\$\d+\@/)
    {
	my ($head, %head, $body,$line);
	print "Checking $article\n";
	$head = $nntp->head($article);
	
	my ($prevkey);
	
	foreach $line (@$head)
	{
	        if ($line =~ /^([\w\-]+): (.*)$/)
		{
		    $head{$1} = $2;
		    $prevkey = $1;
		}
		    elsif ($line =~ /^[ \t]/)
		    {
			$head{$prevkey} .= $line
			}
	    }
	if (!defined($head{References}) || $head{References} =~ /^\s+$/xs)
	{
	    my ($sql);

	    $body = $nntp->body($article);
	        
	    my (%insertdata);
	    if ($head{From} =~ / *(.*?) +\<(.*?)\> *$/)
	    {
		my ($userid);
		($userid) = $dbh->selectrow_array('SELECT id FROM users,capabilities WHERE name='
						  .$dbh->quote($1)
						  .' AND email='
						  .$dbh->quote($2)
						  .' AND users.id=capabilities.user_id AND capabilities.addblogentries');
		$insertdata{author_id} = $userid;
	    }
	    if ($insertdata{author_id})
	    {
		$insertdata{messageid} = $head{'Message-ID'};
		$insertdata{title} = $head{'Subject'};

		$body = join('',@$body);

		$insertdata{text} = $body;
		$insertdata{texttype} = 1;

		if ($head{'Content-Type'} =~ /multipart\/alternative\;
		    .*boundary\=\"(.*?)\"/xsi)
		{
		    my (@bodies);
		    @bodies = split /$1\n/, $body;

		    foreach $body (@bodies)
		    {
		        if ($body =~ /^\n*Content-Type: text\/plain\;.*?\n\n(.*)$/si)
			{
			    $insertdata{text} = "$1\n";
			    $insertdata{texttype} = 1;
			}
			if ($body =~ /^\n*Content-Type: text\/html\;.*?\n\n(.*)$/si)
			{
			    $insertdata{text} = $1;
			    $insertdata{texttype} = 1;
			}
		    }
		}


		($insertdata{id}) = $dbh->selectrow_array("SELECT nextval('articles_id_seq')");
		$insertdata{trackrevisions} = 'false';
		
		my (@insertkeys);
		@insertkeys = keys %insertdata;
	        $sql = 'INSERT INTO articles ('
		    .join(', ',@insertkeys)
		    .') VALUES ('
		    .join(', ', map { $dbh->quote($insertdata{$_}) } @insertkeys)
		    .')';
	        
		if ($dbh->do($sql))
		{
		    $sql = 'INSERT INTO weblogentries(article_id, weblog) '
			."VALUES ($insertdata{id},1)";
		    $dbh->do($sql) or die "$sql\n".$dbh->errstr;
		    $dbh->commit();
		}
	    }
	    else
	    {
		warn "$sql\n".$dbh->errstr;
	    }
	}
	elsif ($head{References} =~ /<flutterbycomweblogentry\$(\d+)\@/s)
	{
	    my ($entrynum, $sql);
	    $entrynum = $1;
	        
	    print "New article $article references $1\n";
	    $body = $nntp->body($article);
	        
	    my (%insertdata);
	    if ($head{From} =~ / *(.*?) +\<(.*?)\> *$/)
	    {
		my ($userid);
		($userid) = $dbh->selectrow_array('SELECT id FROM users WHERE name='
						    .$dbh->quote($1)
						    .' AND email='
						  .$dbh->quote($2));
		$insertdata{author_id} = $userid;
#		die "Can't find '$1' - '$2'\n" unless $userid;
	    }

	    $insertdata{messageid} = $head{'Message-ID'};
	    $insertdata{title} = $head{'Subject'};

	    $body = join('',@$body);

	    $insertdata{text} = $body;
	    $insertdata{texttype} = 1;

	    if ($head{'Content-Type'} =~ /multipart\/alternative\;
		.*boundary\=\"(.*?)\"/xsi)
	    {
		my (@bodies);
		@bodies = split /$1\n/, $body;

		foreach $body (@bodies)
		{
		        if ($body =~ /^\n*Content-Type: text\/plain\;.*?\n\n(.*)$/si)
			{
			    $insertdata{text} = "$1\n";
			    $insertdata{texttype} = 1;
			}
			if ($body =~ /^\n*Content-Type: text\/html\;.*?\n\n(.*)$/si)
			{
			    $insertdata{text} = $1;
			    $insertdata{texttype} = 1;
			}
		    }
	    }


	    ($insertdata{id}) = $dbh->selectrow_array("SELECT nextval('articles_id_seq')");
	    $insertdata{trackrevisions} = 'true';

	    my (@insertkeys);
	    @insertkeys = keys %insertdata;
	        $sql = 'INSERT INTO articles ('
		    .join(', ',@insertkeys)
			.') VALUES ('
			    .join(', ', map { $dbh->quote($insertdata{$_}) } @insertkeys)
				.')';
	        
	    if ($dbh->do($sql))
	    {
	        $sql = 'INSERT INTO weblogcomments(entry_id, article_id) '
		    ."VALUES ($entrynum, $insertdata{id} )";
	        
		$dbh->do($sql) or die "$sql\n".$dbh->errstr;
		$dbh->commit();
	    }
	    else
	    {
		warn "$sql\n".$dbh->errstr;
	    }
	}
    }
}
if (open(O, ">$ENV{'HOME'}/var/nntptoflutterbycomments"))
{
    print O "$thischeckdate\n";
    close O;
}



$nntp->quit;




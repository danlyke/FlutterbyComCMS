#!/usr/bin/perl -w
use strict;
use DBI;

my ($dbhold, $dbhnew);
sub BEGIN
{
    $dbhold = DBI->connect('DBI:Pg:dbname=weblog',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
    $dbhnew = DBI->connect('DBI:Pg:dbname=flutterbycms',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
}
sub END
{
    $dbhold->disconnect;
    $dbhnew->disconnect;
}

sub CopyTableDirectly($@)
{
    my ($table, $tableto, %remap) = @_;
    my ($sth, $row);
    $tableto = $table unless defined($tableto);

    $sth = $dbhold->prepare("SELECT * FROM $table")
	or die $dbhold->errstr."\nUnable to select from $table\n";

    $sth->execute()
	or die $sth->errstr
	    ."\nUnable to execute $table select\n";

    while ($row = $sth->fetchrow_hashref)
    {
	my ($k, $v, @fields, @data, $sql);
	while (($k,$v) = each %$row)
	{
	    push @fields, $k;
	    push @data, $dbhnew->quote($v);
	}
	$sql = "INSERT INTO $tableto ("
	    .join(',',@fields)
		.') VALUES ('
		    .join(',',@data).')';
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
    }
    $dbhnew->do("SELECT SETVAL('".$tableto
		."_id_seq', (SELECT MAX(id) FROM $tableto))")
	|| print STDERR $dbhnew->errstr."\nunable to set id for $table\n";
}

sub
GetArticleID($$$$$$$)
{
    my ($text, $texttype, $subject, $author_id, $trackrevisions,
	$entered, $updated) = @_;
    my ($article_id);
    ($article_id) = $dbhnew->selectrow_array("SELECT NEXTVAL('articles_id_seq')");

    if ($article_id)
    {
	my ($sql, $sth);
	$sql = "INSERT INTO articles (id,"
	    ."text, texttype, title, author_id, trackrevisions,"
		."entered, updated) VALUES ($article_id";
	foreach ($text, $texttype, $subject, $author_id, $trackrevisions, $entered, $updated)
	{
	    $sql .= ','.$dbhnew->quote($_);
	}
	$sql .= ')';
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
	$dbhnew->commit();

	print "\n$sql\n" if ($article_id >  7820 && $article_id < 7835);
	if (0 && !($article_id % 1000))
	{
	    $dbhnew->disconnect();
	    $dbhnew = DBI->connect('DBI:Pg:dbname=flutterbycms',
				   'danlyke',
				   'danlyke')
		or die $DBI::errstr;
	}
    }
    return $article_id;
}

sub
CopyWeblogEntries
{
    my ($sth, $row, $sql);

    $sql = "SELECT * FROM blogentries ORDER BY id";
    $sth = $dbhold->prepare($sql)
	|| die $dbhold->errstr."\n$sql\n";
    $sth->execute
	|| die $sth->errstr."\n$sql\n";

    while ($row = $sth->fetchrow_hashref)
    {
	$row->{'texttype'} += 1;
	if ($row->{'texttype'} > 2)
	{
	    $row->{'texttype'} = 1 ;
	}

	$row->{'article_id'} =  GetArticleID($row->{'text'},
					     $row->{'texttype'},
					     $row->{'subject'},
					     $row->{'author_id'},
					     'N',
					     $row->{'entered'},
					     $row->{'updated'});
	foreach ('text','texttype','subject', 'entered','updated',
		 'category', 'lastchecked', 'deleted','category',
		 'author_id', 'commentcount', 'latestcomment')
	{
	    delete $row->{$_};
	}

	my ($k, $v, @fields, @data, $sql);
	while (($k,$v) = each %$row)
	{
	    push @fields, $k;
	    push @data, $dbhnew->quote($v);
	}
	$sql = "INSERT INTO weblogentries ("
	    .join(',',@fields)
		.') VALUES ('
		    .join(',',@data).')';
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
    }
}


sub
CopyWeblogComments
{
    my ($sth, $row, $sql);

    $sql = "SELECT * FROM blogcomments ORDER BY id";
    $sth = $dbhold->prepare($sql)
	|| die $dbhold->errstr."\n$sql\n";
    $sth->execute
	|| die $sth->errstr."\n$sql\n";

    while ($row = $sth->fetchrow_hashref)
    {
	$row->{'texttype'} += 1;
	if ($row->{'texttype'} > 2)
	{
	    $row->{'texttype'} = 1 ;
	}
	my ($sthchild, $rowchild, $sqlchild, $article_id);
	$sqlchild = "SELECT * FROM blogcommenthistory WHERE comment_id = $row->{'id'} ORDER BY id ";

	$sthchild = $dbhold->prepare($sqlchild)
	    || die $dbhold->errstr."\n$sqlchild\n";
	$sthchild->execute
	    || die $sthchild->errstr."\n$sqlchild\n";
	while ($rowchild = $sthchild->fetchrow_hashref)
	{
	    if ((!defined($rowchild->{'text'})) 
		|| $rowchild->{'text'} =~ /^\s*$/s)
	    {
		my ($k,$v);
		print "!! No text\n";
		while (($k,$v) = each %$rowchild)
		{
		    print "  $k - $v\n";
		}
	    }

	    $rowchild->{'texttype'} += 1;
	    if ($rowchild->{'texttype'} > 2)
	    {
		$rowchild->{'texttype'} = 1 ;
	    }
	    unless (defined($article_id))
	    {
		$article_id = GetArticleID($rowchild->{'text'},
					   $rowchild->{'texttype'},
					   undef,
					   $row->{'author_id'},
					   'Y',
					   $rowchild->{'entered'},
					   $rowchild->{'entered'});
	    }
	    else
	    {
		$sqlchild = "UPDATE articles SET";
		foreach ('text','texttype','entered')
		{
		    $sqlchild .= " $_=".$dbhnew->quote($rowchild->{$_}).",";
		}
		$sqlchild .= " updated=".$dbhnew->quote($rowchild->{'entered'})
		    ." WHERE id=$article_id";
	print "\n$sqlchild\n" if ($article_id >  7820 && $article_id < 7835);

		$dbhnew->do($sqlchild)
		    || die $dbhnew->errstr."\n$sqlchild\n";
		
	    }
	}
	if ((!defined($row->{'text'})) 
	    || $row->{'text'} =~ /^\s*$/s)
	{
	    my ($k,$v);
	    print "!! No row text\n";
	    while (($k,$v) = each %$row)
	    {
		print "  $k - $v\n";
	    }
	}

	unless (defined($article_id))
	{
	    $article_id = GetArticleID($row->{'text'},
				       $row->{'texttype'},
				       undef,
				       $row->{'author_id'},
				       'Y',
				       $rowchild->{'entered'},
				       $rowchild->{'entered'});
	}
	else
	{
	    $sqlchild = "UPDATE articles SET";
	    foreach ('text','texttype','entered')
	    {
		$sqlchild .= " $_=".$dbhnew->quote($row->{$_}).",";
	    }
	    $sqlchild .= " updated=".$dbhnew->quote($row->{'entered'})
		." WHERE id=$article_id";
		
	print "\n$sqlchild\n" if ($article_id >  7820 && $article_id < 7835);
	    $dbhnew->do($sqlchild)
		|| die $dbhnew->errstr."\n$sqlchild\n";
	}
	$sql = "INSERT INTO weblogcomments(entry_id, article_id) VALUES ($row->{'entry_id'}, $article_id)";
	
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
    }
}



$dbhnew->{AutoCommit} = 0;
if (1)
{
if (1)
{
    CopyTableDirectly('users');
    $dbhnew->commit();
}
if (1)
{
    CopyWeblogEntries();
    $dbhnew->commit();
    CopyWeblogComments();
    $dbhnew->commit();
}
if (1)
{
    CopyTableDirectly('blogtopics','articletopics');
    $dbhnew->commit();
}
if (1)
{
    my ($sth, $row, $sql);

    $sql = 'SELECT * FROM blogtopiclinks';
    $sth = $dbhold->prepare($sql)
	|| die $dbhold->errstr."\n$sql\n";
    $sth->execute
	|| die $sth->errstr."\n$sql\n";
    while ($row = $sth->fetchrow_hashref)
    {
	$sql = 'INSERT INTO articletopiclinks(topic_id, article_id)'
	    ." VALUES ($row->{'topic_id'}, (SELECT article_id FROM BLOGENTRIES WHERE id=$row->{'entry_id'}))";
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
    }
    $dbhnew->commit();
}
if (1)
{
    CopyTableDirectly('blogtopicterms','articletopicterms');
    $dbhnew->commit();
}
}

if (1)
{
    my ($sth, $row, $sql);

    $sql = 'SELECT * FROM photos';
    $sth = $dbhold->prepare($sql)
	|| die $dbhold->errstr."\n$sql\n";
    $sth->execute
	|| die $sth->errstr."\n$sql\n";
    while ($row = $sth->fetchrow_hashref)
    {
	my ($personid);
	($personid) = $dbhnew
	    ->selectrow_array("SELECT id FROM people WHERE "
			      ."user_id=$row->{'photographer_id'}");
	unless ($personid)
	{
	    my ($name, $userid);
	    ($userid,$name) = $dbhnew->selectrow_array("SELECT id,name FROM users WHERE id=$row->{'photographer_id'}");
	    ($personid) = $dbhnew->selectrow_array("SELECT NEXTVAL('people_id_seq')");
	    $dbhnew->do("INSERT INTO people(id, user_id,name) VALUES ("
			.join(",",
			     $dbhnew->quote($personid),
			     $dbhnew->quote($userid),
			     $dbhnew->quote($name))
			.")");
	}
	my ($articleid);
	$articleid = GetArticleID($row->{'description'},
				  1,
				  $row->{'alt_text'},
				  $row->{'photographer_id'},
				  'N',
				  $row->{'entered'},
				  $row->{'updated'});
	$row->{'photographer_id'} = $personid;
	$row->{'model_release'} = $row->{'model_release'} + 1;
	my (@copy);
	@copy = (
		 'id',
		 'taken',
		 'photographer_id',
		 'model_release',
		 'tech_notes',
		 'directory',
		 'name',
		 'show_on_browse',
		 'entered',
		 'updated'
		 );
	$sql = 'INSERT INTO photolist('
	    .join(',', @copy).',article_id) VALUES (';
	foreach (@copy)
	{
	    $sql .= $dbhnew->quote($row->{$_}).',';
	}
	$sql .= "$articleid )";
	
	$dbhnew->do($sql)
	    || die $dbhnew->errstr."\n$sql\n";
    }
    $dbhnew->commit();
    
}
if (1)
{
    CopyTableDirectly('photosizes','photosizes');
    $dbhnew->commit();
}

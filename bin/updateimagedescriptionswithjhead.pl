#!/usr/bin/perl -w
use strict;
use DBI;

my ($dbh);
$dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
		    'danlyke',
		    'danlyke')
    or die $DBI::errstr;
foreach (@ARGV) {&importdir($dbh, $_)};
$dbh->disconnect;


sub processcurrentfile($$$$$$$)
{
    my ($dbh, $userinfo, $dir,$currfile,$status,$rootprocessed,$alreadythere) = @_;
    my ($file, $ext, $width, $height, $sql);

    ($file, $ext) = ($1, $2) 
	if ($currfile->{'File name'} =~
	    /\/(\w+)(a\.jpg|\..*?jpg)/);
    ($width, $height) = ($1, $2)
	if ($currfile->{'Resolution'} =~ /(\d+) *x *(\d+)/);
    
    push @$status, "Got file $file\n<br />";
    
    my ($imageid, $taken);
    
    if (defined($currfile->{'Date/Time'}))
    {
	$taken = $currfile->{'Date/Time'};
	$taken =~ s/^(\d+):(\d+):/$1-$2-/;
	$taken = $dbh->quote($taken);
    }

    if (defined($rootprocessed->{$file}))
    {
	$imageid = $rootprocessed->{$file};
    }
    else
    {
	if (defined($alreadythere->{$file}))
	{
	    $imageid = $alreadythere->{$file};
	    $sql = "DELETE FROM photosizes WHERE photo_id=$imageid";
	    $dbh->do($sql)
		|| die "$sql\n".$dbh->errstr;
	}
	else
	{
	    my ($article_id);
	    $sql = "SELECT nextval('photolist_id_seq')";
	    ($imageid) =
		$dbh->selectrow_array($sql)
		    || die "$sql\n".$dbh->errstr;
	    
	    ($article_id) = 
		$dbh->selectrow_array("SELECT nextval('articles_id_seq')");
	    $sql = 'INSERT INTO articles (id, author_id) VALUES ('
		."$article_id, $userinfo->{'id'})";
	    $dbh->do($sql) or die $dbh->errstr;
				    
	    $sql = 'INSERT INTO photolist(id, photographer_id, article_id,directory, name) VALUES ('
		."$imageid, $userinfo->{'id'}, $article_id, '$dir', '$file' )";
	    push @$status, "$sql\n<br />";
				$dbh->do($sql)
				    || die "$sql\n".$dbh->errstr;
	}
	$rootprocessed->{$file} = $imageid;
    }
    if (defined($taken))
    {
	$sql = "UPDATE photolist SET taken=$taken WHERE id=$imageid";
	push @$status, "$sql\n<br />";
	$dbh->do($sql)
	    || push @$status, "$sql\n".$dbh->errstr;
    }
    my (@techinfo);
    
    foreach (
	     'Camera model',
	     'Flash used',
	     'Focal length',
	     'CCD Width',
	     'Exposure time',
	     'Aperture',
	     'Focus Dist.',
	     'Metering Mode'
	     )
    {
	push @techinfo, "$_ : $currfile->{$_}"
	    if (defined($currfile->{$_}));
    }
    if ($#techinfo >= 0)
    {
	$sql = "UPDATE photolist SET tech_notes="
	    .$dbh->quote(join(" / ", @techinfo))
		." WHERE id=$imageid";
	push @$status, "$sql\n<br />";
	$dbh->do($sql)
	    || die "$sql\n".$dbh->errstr;
    }
    $sql = 'INSERT INTO photosizes (photo_id, width, height, filename) VALUES ('
	."$imageid, $width, $height, '$file$ext')";
    $dbh->do($sql)
	|| die "$sql\n".$dbh->errstr;
}

sub importdir
{
    my ($dbh, $dir) = @_;
    my ($userinfo);
    $userinfo = {'id' => 1};
    my ($sth, $row, $sql, %alreadythere, @status);

    $sql = "SELECT id, name FROM photolist WHERE directory='$dir'";

    $sth = $dbh->prepare($sql)
	|| die "$sql\n".$dbh->errstr;
    $sth->execute
	|| die "$sql\n".$sth->errstr;
    while ($row = $sth->fetchrow_arrayref)
    {
	$alreadythere{$row->[1]} = $row->[0];
    }

    push @status, "About to run /usr/local/bin/jhead ../images/$dir/*.jpg \n<br />";
    if (open(JPEGINFO, "/usr/local/bin/jhead ../images/$dir/*.jpg|"))
    {
	my ($currfile, %rootprocessed);
	push @status, "Opened JPEGINFO!\n<br />";
	while (<JPEGINFO>)
	{
	    if (/^(.*?) *: +(.*)$/)
	    {
		my ($att, $val);
		$att = $1;
		$val = $2;
		
		if ($att eq 'File name')
		{
		    if (defined($currfile))
		    {
			processcurrentfile($dbh, $userinfo, $dir,$currfile,\@status,\%rootprocessed,\%alreadythere);
		    }
		    $currfile = {};
		}
		$currfile->{$att} = $val;
	    }
	}
	processcurrentfile($dbh, $userinfo, $dir,$currfile,\@status,\%rootprocessed,\%alreadythere) if (defined($currfile));

	close JPEGINFO;
	$dbh->commit();
    }
    print join("\n", @status);
    print "\n";
}


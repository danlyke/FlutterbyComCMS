#!/usr/bin/perl -w
use strict;
use DBI;
my ($dbh);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=weblog',
			'danlyke',
			'danlyke',
		       {AutoCommit => 0})
	or die $DBI::errstr;
}
sub END
{
    $dbh->disconnect;
}


sub InsertEntries($)
{
    my ($table) = @_;
    my ($sql,$sth,$id,$row);

    $sql = "SELECT id FROM blogentries ";
    $sth = $dbh->prepare($sql) or die $dbh->errstr."\n$sql\n";
    $sth->execute or die $sth->errstr."\n$sql\n";
    if ($id = $sth->fetchrow_arrayref)
    {
	$id = $id->[0];
	print "ID for $table is $id\n";
	$sql = "SELECT nextval('".$table."_id_seq')";
	print "$sql\n";
	$sth = $dbh->prepare($sql) or die $dbh->errstr."\n$sql\n";
	$sth->execute or die $sth->errstr."\n$sql\n";
	while (($row = $sth->fetchrow_arrayref) && ($row->[0] < $id))
	{
	    $sth = $dbh->prepare($sql) or die $dbh->errstr."\n$sql\n";
	    $sth->execute or die $sth->errstr."\n$sql\n";
	}
    }
}

my ($categories) =
  {
   'Books' =>
   {
    -terms =>
    [
     'Amazon',
     'books',
     'book',
     'Borders',
     'Barnes',
     'harry potter',
     'library'
    ]
   },
   'Psychology, Psychiatry and Personality' =>
   {
    -terms =>
    [
     'psychology',
     'psychological',
     'psychiatry',
     'personality',
     'therapy',
     'meyers-briggs',
     'guru',
     'emotions',
    ]
   },
   'Children and growing up' =>
   {
    -terms =>
    [
     'sprogopolis',
     'sprog',
     'children',
     'kids',
     'teenager',
     'teacher',
     'high school',
     'littleton',
     'trenchcoat mafia',
     'teachers',
     'textbook',
     'schools',
     'school',
    ]
   },
   'Child-freedom and growing up' =>
   {
    -terms =>
    [
     'sprogopolis',
     'sprog',
     'childfree',
     'child free',
     'breeder',
    ]
   },
   'Good Vibrations' =>
   {
    -terms =>
    [
     'Good Vibrations',
     'goodvibes',
    ]
   },
   'Erotic' =>
   {
    -terms =>
    [
     'nudes',
     'nude',
     'sex',
     'sexual',
     'pornography',
     'porn',
     'erotic',
     'erotica',
     'testicles',
     'obscene',
     'Scarlet Letters',
     'scarletletters',
     'Nerve',
     'cleansheets',
     'Clean Sheets',
     'Boutilier',
     'Good Vibrations',
     'Mohanraj',
    ]
   },
   'Cool Science' =>
   {
    -terms =>
    [
     'electricity',
     'fuel cell',
     'roton',
     'avweb',
     'aviation',
     'linear accelerator',
    ]
   },
   'Technology and Culture' =>
   {
    -terms =>
    [
     'tv',
     'television',
     'netfuture',
     'net future',
     'talbott',
     'talbot',
     'does not compute',
     'online community',
     'alberry',
     'meeks',
     'kaczynski',
    ]
   },
   'Apple Computer' =>
   {
    -terms =>
    [
     'apple',
     'kawasaki',
     'sculley',
    ]
   },
   'Sexual Culture' =>
   {
    -terms =>
    [
     'pedophile',
     'pedophiles',
     'pedophilia',
     'Palac',
     'abortion',
     'obscene',
     'obscenity',
     'feminine',
     'masculine',
     'Sturges',
     'Sally Mann',
     'swingers',
     'nude',
     'nudity',
     'goodvibes',
     'good vibrations',
     'sex',
     'sexual',
     'pornography',
     'pornographic',
     'porn',
     'eroticicize',
     'Debra Hyde',
     'scarleteen',
     'virgin',
     'virginity',
     'prostitutes',
     'prostitute',
     'mouthorgan',
     'Chong',
     'spectator',
     'spectatormag',
     'David Steinberg',
     'Susie Bright',
     'Suzie Bright',
     'Carol Queen',
     'Pat Califia',
     'Annie Sprinkle',
     'bisexuality',
     'polyamory',
     'tantra',
     'tantric',
     'masturbation',
     'masturbate',
     'gay',
     'lesbian',
     'exotic dancers',
     'exotic dancer',
    ],
   },
   'Drugs' =>
   {
    -terms =>
    [
     'drugs',
     'marijuana',
     'lsd',
     'bong',
     'bhong',
     'cocaine',
     'opium',
     'hoffman',
    ]
   },
   'Weblogs' =>
   {
    -terms =>
    [
     'web log',
     'web logs',
     'web-log',
     'web-logs',
     'weblogs',
     'weblog',
     'blog',
    ]
   },
   'Burning Man' =>
   {
    -terms =>
    [
     'Burning Man',
     'burningman',
     'firefall',
     'Fire Fall',
    ]
   },
   'Religion' =>
   {
    -terms =>
    [
     'jesus',
     'religion',
     'tantra',
     'christianity',
     'atheist',
     'atheism',
     'god',
     'christian',
     'jew',
     'jewish',
     'hindu',
     'buddhist',
     'zen',
     'church',
     'prayer',
     'spirituality',
     'spiritual',
     'vatican',
     'catholic',
    ]
   },
   'Language' =>
   {
    -terms =>
    [
     'Literate',
     'library',
     'literacy',
     'fowles',
     'davies',
     'etymology',
     'etymological',
    ]
   },
   'Dave Winer' =>
   {
    -terms =>
    [
     'Winer',
     'scripting.com',
     'userland',
    ]
   },
   'Marylaine BLock' =>
   {
    -terms =>
    [
     "My Word's Worth",
     'qconline',
     'marylaine',
    ]
   },
   'Ziffle' =>
   {
    -terms =>
    [
     'ziffle',
     'frank',
    ]
   },
   'Objectivism' =>
   {
    -terms =>
    [
     'objectivist',
     'objectivism',
     'atlas shrugged',
     'ayn'
    ]
   },
   'Libertarian' =>
   {
    -terms =>
    [
     'libertarian',
     'lp.org',
    ]
   },

   'Cameron Barrett' =>
   {
    -terms =>
    [
     'camworld',
     'Cameron',
     'Cam'
    ]
   },
   'John S Jacobs-Anderson' =>
   {
    -terms =>
    [
     'Genehack',
     'Jacobs-Anderson',
     'Jacobs Anderson',
    ]
   },
   'Hardware Hackery' =>
   {
    -terms =>
    [
     'Atmel',
     'PIC',
     'AVR',
     'RS-232',
     'RS232',
     'Centronics',
    ]
   },
   'Carl Coryell-Martin' =>
   {
    -terms =>
    [
     'Carl passed',
     'Carl passes',
     'via Carl',
     'Coryell',
     'civilution',

    ]
   },
   'Jorn Barger' =>
   {
    -terms =>
    [
     'Jorn',
     'Robot Wisdom',
     'robotwisdom'
    ]
   },
    'Content Management' =>
   {
    -terms =>
    [
     'newwwsboy',
     'cms',
     'content management',
     'xml',
     'aggregator',
     'my netscape',
     'mynetscape',
     'my.netscape',
     'rdf',
     'rss',
    ]
   },
   'Wireless' =>
   {
    -terms =>
    [
     'bluetooth',
     'blue tooth',
     'cell phone',
     'wireless',
     '802.11',
     '802.11b',
    ]
   },
   "Dan's Life" =>
   {
    -terms =>
    [
     'Catherine',
     'Charlene'
    ]
   },
   'Photography' =>
   {
    -terms =>
    [
     'photography',
     'camera',
     'cameras',
     'photograph',
     'Boutilier',
     'Boutillier',
     'adams gallery',
     'ansel adams',
     'ebb.ns.ca',
     '<img',
     '<IMG',
    ]
   },
   'Microsoft' =>
   {
    -terms =>
    [
     'Windows',
     'Microsoft',
     'nt',
     'sexchange',
     'msexchange',
     'outlook',
     'Melissa Virus',
     'mfc',
    ]
   },
    'Andersen/Accenture' =>
   {
    -terms =>
    [
     'Andersen',
     'Accenture'
    ]
   },
   'Privacy' =>
   {
    -terms =>
    [
     'CPRM',
     'Clipper',
     'Crypt',
     'freedom',
     'privacy',
     'cryptography',
     'serial number',
    ]
   },
   'Butterflies' =>
   {
    -terms =>
    [
     'butterfly',
     'butterflies',
    ]
   },
   'Music' =>
   {
    -terms =>
    [
     'MP3',
     'MP3s',
     'music',
     'audio',
     'CD',
     'CDs',
     'audio',
    ]
   },
   'Humor' =>
   {
    -terms =>
    [
     'skaggs',
     'exothermic exhuberance',
     'gefingerpoken',
     'humor',
     'humour',
     'humorous',
     'darwin awards',
     'dumbentia',
     'Borge',
     'wences',
     'sweetheart of the internet',
     'Keith Knight',
     'K Chronicles',
     'Sluggy',
     'User Friendly',
     'userfriendly',
     'Jesus',
     'SUV',
     'demotivators',
     'Family Circus',
     'segfault',
     'questionable medical',
     'surrealism',
     'surrealistic',
     'chomskybot',
     'kibo',
     'kibology',
     'talk.bizarre',
     'dumbentia',
    ]
   },
   'Quotes' =>
   {
    -terms =>
    [
     'Quote of the',
     'quotes',
     'qotd',
     'q.o.t.d.'
    ]
   },
   'Pixar' =>
   {
    -terms =>
    [
     'Pixar',
     'render man',
     'renderman',
     'toy story',
     "Bug's Life",
     'bugs life',
     'oil refinery',
    ]
   },
   'Animation' =>
   {
    -terms =>
    [
     'Animation',
     'animated',
     'Pixar',
     'toy story',
     "Bug's Life",
     'bugs life',
    ]
   },
   'User Interface' =>
   {
    -terms =>
    [
     'Nielsen',
     'Norman',
     'UI',
     'user interface',
    ]
   },
   'Politics' =>
   {
    -terms =>
    [
     'Bush',
     'Gore',
     'gwbush',
     'Dubya',
     'G.W.',
     'G. W.',
     'Clinton',
     'eastern europe',
     'objectivist',
     'objectivism',
     'libertarian',
     'congress',
     'house of representatives',
     'senate',
     'COPA',
     'Internal Revenue Service',
     'IRS',
     'taxes',
     'tax',
     'nato',
     'sarajevo',
     'yugoslavia',
     'rwanda',
     'politician',
     'political',
     'politics',
     'albania',
     'albanian',
    ]
   },
   'Star Wars' =>
   {
    -terms =>
    [
     'fandom menace',
     'phantom menace',
     'lucas',
     'star wars',
    ]
   },
   'Nostalgia' =>
   {
    -terms =>
    [
     'Krakowicz',
     'KIM1',
     'when i was a',
    ]
   },
   'Free Software' =>
   {
    -terms =>
    [
     'Open Source',
     'Linux',
     'Debian',
     'Red Hat',
     'Caldera',
     'BALUG',
     'SVLUG',
     'Torvalds',
     'Apache',
     'Stallman',
     'Free Software',
    ]
   },
   'Intellectual Property' =>
   {
    -terms =>
    [
     'trademark',
     'patent',
     'patent',
     'uspto',
    ]
    
   },
   'Web development' =>
   {
    -terms =>
    [
     'HTML',
     'SGML',
     'XML',
     'GIF',
     'GIFs',
     'webstandards',
     'markup language',
    ]
   },
   'Business' =>
   {
    -terms =>
    [
     'Red Herring',
     'News.com',
     'inside.com',
    ]
   },
   'Interactive Drama' =>
   {
    -terms =>
    [
     'interactive drama',
     'if',
     'interactive fiction',
     'interactive-fiction',
     'polti',
     'idrama',
     'oz project',
    ]
   },
   'Games' =>
   {
    -terms =>
    [
     'idrama',
     'interactive drama',
     'games',
     'game',
     'gaming',
     'Chris Crawford',
     'phrontisterion',
     'frontisterion',
     'Morbus Iff',
     'john carmack',
     'gamegrene',
     'gamasutra',
     'quake',
     'redneck rampage',
    ]
   },
  };

foreach (keys %$categories)
  {
    my ($sql);
#    $sql = 'INSERT INTO blogtopics (topic) VALUES ('.$dbh->quote($_).')';
    $dbh->do($sql);
    my ($topicid);
    $sql = 'SELECT id FROM blogtopics WHERE topic='.$dbh->quote($_);
    ($topicid) = $dbh->selectrow_array($sql);
    $categories->{$_}->{-id} = $topicid;
  }


if (0)
  {
    foreach (keys %$categories)
      {
	my ($sql,$required,@a);
	$required = $categories->{$_}->{-terms};
	$sql = 'SELECT id FROM blogentries WHERE '
	  .join(' OR ',
		(map
		 {
		   "upper(text) ~* "
		     .$dbh->quote("(^|[^a-zA-Z0-9])".uc($_)."(\$|[^a-zA-Z0-9])")
		       ." OR "
			 ."upper(subject) ~* "
			   .$dbh->quote("(^|[^a-zA-Z0-9])".uc($_)."(\$|[^a-zA-Z0-9])");
		 }
		 @$required));
	
	my ($sth,$id,$row);
	print "$sql\n";
	$sth = $dbh->prepare($sql) or die $dbh->errstr."\n$sql\n";
	$sth->execute or die $sth->errstr."\n$sql\n";
	while ($id = $sth->fetchrow_arrayref)
	  {
	    $sql = 'INSERT INTO blogtopiclinks (topic_id,entry_id) VALUES ('
	      .join(',',map {$dbh->quote($_);} ($categories->{$_}->{-id},$id->[0]))
		.')';
	    $dbh->do($sql);
	  }
      }
  }
else
  {
    my ($sql);
    $dbh->commit();
    $sql = 'SELECT id,text,subject FROM blogentries WHERE id > 3400';
    my ($sth,$row,$id,$text,$subject);
    print "$sql\n";
    $sth = $dbh->prepare($sql) or die $dbh->errstr."\n$sql\n";
    $sth->execute or die $sth->errstr."\n$sql\n";
    while (($id, $text, $subject) = $sth->fetchrow_array)
      {
print "Record $id\n";
	my ($category, %categories);
	foreach $category (keys %$categories)
	  {
	    my ($keywords);
	    
	    $keywords = $categories->{$category}->{-terms};
	    foreach (@$keywords)
	      {
		$text =~ s/\s+/ /sg;
		my ($keyword) = $_;
		$categories{$categories->{$category}->{-id}} = 1
		  if ($text =~ /(^|[^a-zA-Z0-9])$keyword(\$|[^a-zA-Z0-9])/i);
		$categories{$categories->{$category}->{-id}} = 1	
		  if (defined($subject) 
		      && $subject =~ /(^|[^a-zA-Z0-9])$keyword(\$|[^a-zA-Z0-9])/i);
	      }
	  }

	foreach $category (keys %categories)
	  {
	    $sql = 'INSERT INTO blogtopiclinks (topic_id,entry_id) VALUES ('
	      .join(',',map {$dbh->quote($_)} ($category,$id))
		.')';
	    $dbh->do($sql);
	  }
	$dbh->commit();
      }
  }

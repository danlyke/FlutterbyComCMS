#!/usr/bin/perl -w
use strict;
use DBI;
my ($dbh);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=weblog',
			'danlyke',
			'danlyke')
	or die $DBI::errstr;
}
sub END
{
    $dbh->disconnect;
}

sub LoadCategories($)
  {
    my ($dbh) = @_;
    my ($sql, $sth,$id,$topic,$text,$categories);
    $categories = {};
    $sql = 'SELECT id,topic,text FROM blogtopics, blogtopicterms WHERE blogtopics.id=blogtopicterms.topic_id';
    $sth = $dbh->prepare($sql) or die $dbh->errstr;
    $sth->execute or die $sth->errstr;
    while (($id,$topic,$text) = $sth->fetchrow_array)
      {
	$categories->{$topic} = {-id=>$id,-terms=>[]} unless defined($categories->{$topic});
	push @{$categories->{$topic}->{-terms}},$text;
      }
    return $categories;
  }

#my ($categories) = LoadCategories($dbh);
my ($categories) =
  {
   'Books' =>
   {
    -id =>  25 ,
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
    -id =>  38 ,
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
    -id =>  13 ,
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
    -id =>  47 ,
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
    -id =>  21 ,
    -terms =>
    [
     'Good Vibrations',
     'goodvibes',
    ]
   },
   'Erotic' =>
   {
    -id =>  33 ,
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
    -id =>  39 ,
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
    -id =>  42 ,
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
    -id =>  10 ,
    -terms =>
    [
     'apple',
     'kawasaki',
     'sculley',
    ]
   },
   'Sexual Culture' =>
   {
    -id =>  36 ,
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
    -id =>  11 ,
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
    -id =>  41 ,
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
    -id =>   8 ,
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
    -id =>   5 ,
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
    -id =>   3 ,
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
    -id =>  45 ,
    -terms =>
    [
     'Winer',
     'scripting.com',
     'userland',
    ]
   },
   'Marylaine BLock' =>
   {
    -id =>  43 ,
    -terms =>
    [
     "My Word's Worth",
     'qconline',
     'marylaine',
    ]
   },
   'Ziffle' =>
   {
    -id =>   4 ,
    -terms =>
    [
     'ziffle',
     'frank',
    ]
   },
   'Objectivism' =>
   {
    -id =>  20 ,
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
    -id =>  24 ,
    -terms =>
    [
     'libertarian',
     'lp.org',
    ]
   },

   'Cameron Barrett' =>
   {
    -id =>   9 ,
    -terms =>
    [
     'camworld',
     'Cameron',
     'Cam'
    ]
   },
   'John S Jacobs-Anderson' =>
   {
    -id =>  28 ,
    -terms =>
    [
     'Genehack',
     'Jacobs-Anderson',
     'Jacobs Anderson',
    ]
   },
   'Hardware Hackery' =>
   {
    -id =>  14 ,
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
    -id =>  44 ,
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
    -id =>   2 ,
    -terms =>
    [
     'Jorn',
     'Robot Wisdom',
     'robotwisdom'
    ]
   },
   'Content Management' =>
   {
    -id =>  40 ,
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
    -id =>  27 ,
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
    -id =>  32 ,
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
    -id =>  48 ,
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
    -id =>  30 ,
    -terms =>
    [
     'Andersen',
     'Accenture'
    ]
   },
   'Privacy' =>
   {
    -id =>  34 ,
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
    -id =>  15 ,
    -terms =>
    [
     'butterfly',
     'butterflies',
    ]
   },
   'Music' =>
   {
    -id =>  29 ,
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
    -id =>  22 ,
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
    -id =>  16 ,
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
    -id =>   1 ,
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
    -id =>  46 ,
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
    -id =>  31 ,
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
    -id =>  19 ,
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
    -id =>  26 ,
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
    -id =>  12 ,
    -terms =>
    [
     'Krakowicz',
     'KIM1',
     'when i was a',
    ]
   },
   'Free Software' =>
   {
    -id =>   7 ,
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
    -id =>   6 ,
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
    -id =>  23 ,
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
    -id =>  18 ,
    -terms =>
    [
     'Red Herring',
     'News.com',
     'inside.com',
    ]
   },
   'Interactive Drama' =>
   {
    -id =>  17 ,
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
    -id =>  35 ,
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

my ($category);
foreach $category (keys %$categories)
  {
    my ($keywords,$topicid);
    $topicid = $categories->{$category}->{-id};
    $keywords = $categories->{$category}->{-terms};
    foreach (@$keywords)
      {
	my ($sql);
	$sql = "INSERT INTO blogtopicterms(topic_id,text) VALUES ($topicid,"
	  .$dbh->quote($_).");\n";
	print $sql;
	unless ($dbh->do($sql))
	  {
	    my $errstr = $dbh->errstr;
	    print "$sql\n$errstr" unless $errstr =~ /Cannot insert a duplicate key into unique index/;
	  }
      }
  }

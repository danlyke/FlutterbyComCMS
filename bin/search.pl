#!/usr/bin/perl -w
use strict;
use DBI;
use lib 'flutterby_cms';
use Flutterby::Util;

my ($dbh,%wordlist);
sub BEGIN
{
    $dbh = DBI->connect('DBI:Pg:dbname=flutterbycms',
			'danlyke',
			'danlyke',
			{AutoCommit => 0})
	or die $DBI::errstr;
}

sub END
{
    $dbh->disconnect;
}


sub AddDocument($$)
  {
    my ($document,$title) = @_;
    $dbh->do('INSERT INTO urls(url,title) VALUES('
	     .join(',', map {$dbh->quote($_)} ($document, $title)).')');
    $dbh->commit();
    my ($id);
    ($id) =
      $dbh->selectrow_array('SELECT id FROM urls WHERE url='.$dbh->quote($document));
    return $id;
  }

sub AddWords($$)
  {
    my ($document,$text) = @_;
    my (@words,%words,$i);
    @words = map {uc($_)} split (/[\W_]+/,$text);
    for ($i = 0; $i < $#words; $i++)
      {
	unless ($wordlist{$words[$i]})
	  {
	    my ($id);
	    ($id) =
	      $dbh->selectrow_array('SELECT id FROM searchwords WHERE word='
				    .$dbh->quote($words[$i]));
	    unless ($id)
	      {
		$dbh->do('INSERT INTO searchwords(word) VALUES('
			 .$dbh->quote($words[$i]).')');
		($id) =
		  $dbh->selectrow_array('SELECT id FROM searchwords WHERE word='
					.$dbh->quote($words[$i]));
	      }
	    $wordlist{$words[$i]} = $id;
	  }
	$dbh->do('INSERT INTO searchurlwords (url_id, word_id, pos) VALUES ('
		 .join(',', 
		       map {$dbh->quote($_)}
		       ($document,$wordlist{$words[$i]},$i)).')');
      }
    $dbh->commit();
  }
use Time::Local 'timelocal';

sub IndexDocument($$$$$)
  {
    my ($dbh, $document, $time, $title, $text) = @_;
    my ($id, $lastindexed);
    ($id,$lastindexed) =
      $dbh->selectrow_array('SELECT id,lastindexed FROM urls WHERE url='
			    .$dbh->quote($document));
    $id = AddDocument($document,$title)
      unless (defined($id));
    if ($id)
      {
	$lastindexed = '0000-00-00 00:00:00' unless (defined($lastindexed));
	print "Comparing $time with $lastindexed\n";
	if ($time gt $lastindexed)
	  {
	    $dbh->do('DELETE FROM searchurlwords WHERE url_id='.$dbh->quote($id));
	    AddWords($id,$text);
	  }
      }
  }

if (0)
  {
    my ($file);
    foreach $file 
      (
       '1998_Aug/16_Snidecommentsonwwwwebstandardsorgrunamok.html',
       '1998_Aug/18_ReasonsImnotworriedaboutY2K.html',
       '1998_Aug/21_Towardsasmallerslowerpacedweb.html',
       '1998_Aug/31_Shasta.html',
       '1998_Dec/10_.html',
       '1998_Dec/11_TheDeclarationofIndependenceoftheThirteenColonies.html',
       '1998_Dec/11_ThePoliticalHearingsDrinkingGame.html',
       '1998_Dec/20_Motorists.html',
       '1998_Feb/28_LA&Story.html',
       '1998_Feb/28_Protectingourchildren.html',
       '1998_Feb/28_Wheredoyouwanttogotomorrow.html',
       '1998_Jul/01_SecurityHoleinWindows.html',
       '1998_Jul/29_JuryDuty.html',
       '1998_Jun/18_AnothertryatWinsockrant.html',
       '1998_Jun/19_Canphotographyblindus.html',
       '1998_Jun/22_libraryasbookstore.html',
       '1998_Jun/28_NotesfromtheSFPrideparade.html',
       '1998_Jun/30_Findingtripodholes.html',
       '1998_Mar/03_Protectingourchildren....html',
       '1998_Mar/03_USTeensRankLowinWorldTests.html',
       '1998_Mar/04_Photography.html',
       '1998_Mar/05_WhyPhotograph.html',
       '1998_Mar/27_MyresponsetoLinuxSeenasOSLifeboat.html',
       '1998_Mar/3_MusingsonTedKaczynski.html',
       '1998_May/08_ToHisCoyMistress.html',
       '1998_May/13_ConversationontheUllmanessay.html',
       '1998_May/6_Maintaininglistsaswebpages.html',
       '1998_Nov/16_Codingmythically.html',
       '1998_Nov/20_ReEarthsWebsite.html',
       '1998_Nov/23_MyresponsetoTheAntiLinuxCrusade.html',
       '1998_Nov/25_AOLacquiringNetscape.html',
       '1998_Oct/06_Danputsdownhiscalculator.html',
       '1998_Oct/16_PrimesandthePerlregularexpressionparser.html',
       '1998_Oct/16_Thedeathofeducation.html',
       '1998_Sep/10_TotheNikontotingBermudashortswearers.html',
       '1998_Sep/9_BurningMan98.html',
       '1998_Sep/9_MoreBurningMannotes.html',
       '1999_Apr/02_baby.html',
       '1999_Apr/09_parallelsfromYugoslavia.html',
       '1999_Apr/16_Volunteeringforcommunityworkingforfree.html',
       '1999_Apr/20_VirtualSex.html',
       '1999_Apr/22_Oloneeye.html',
       '1999_Apr/2_AuctionoffWindows.html',
       '1999_Apr/30_Comingout.html',
       '1999_Apr/30_ReAnheuserBuschadcampaignsupport.html',
       '1999_Apr/7_DellSells1250LinuxbasedDESKTOPS.html',
       '1999_Aug/11_SIGGRAPHmalaise.html',
       '1999_Aug/12_MysteryMenreview.html',
       '1999_Aug/12_TheWorldOutsideofSigraph.html',
       '1999_Aug/13_HTMLinEmail.html',
       '1999_Aug/17_myCNNsucks.html',
       '1999_Aug/20_Moremusingsonwebmanglement.html',
       '1999_Aug/20_SnideiMacrelatedcomments.html',
       '1999_Aug/23_SomeMyCNNsolutions.html',
       '1999_Aug/23_gratuitousiMacbashing.html',
       '1999_Aug/3_SIGGRAPHprivacy.html',
       '1999_Aug/9_JoshuaTree.html',
       '1999_Dec/07_SomeUnixnotes.html',
       '1999_Dec/10_Colorcopiersagan.html',
       '1999_Dec/10_WinterSolstice.html',
       '1999_Dec/11_Finalcolorcopiernote.html',
       '1999_Dec/16_Digitalprojector.html',
       '1999_Dec/18_DINstandards.html',
       '1999_Dec/18_XMLforCalendars.html',
       '1999_Dec/21_Ramblingsofaninsomniac.html',
       '1999_Dec/27_Chocolateasgatewaydrug.html',
       '1999_Dec/27_Gratitudesandreflections.html',
       '1999_Dec/28_CatholicChurchwearealreadypasttheyear2000.html',
       '1999_Dec/3_EricSchmidtandcookies.html',
       '1999_Dec/4_Archivingissues.html',
       '1999_Dec/6_HTMLEmailsecurityhole.html',
       '1999_Dec/6_Whatarearchivesfor.html',
       '1999_Dec/7_DeadPierreBezier.html',
       '1999_Dec/7_Updateoncopiercoderumor.html',
       '1999_Dec/8_VerynerdyXmasgreetings.html',
       '1999_Dec/8_VerynerdyXmassolution.html',
       '1999_Feb/10_ConceivingAda.html',
       '1999_Feb/11_ComplexBetter.html',
       '1999_Feb/12_OnionlinkspassedonfromTim.html',
       '1999_Feb/19_Ttttalkinboutmydemographic.html',
       '1999_Feb/1_Aboutonlineforumsandcommunity.html',
       '1999_Feb/1_RequiemfortheIndependentBookstore.html',
       '1999_Feb/25_WebrecreatesUsenetandotherthoughtsonwherethenetisgoing.html',
       '1999_Feb/2_Humaninteractiononline.html',
       '1999_Feb/9_HumorTelevisionSeasonPremieres.html',
       '1999_Jan/05_Danlooksahead.html',
       '1999_Jan/06_Xenophilesasacustomerbase.html',
       '1999_Jan/08_KoolAidcoloredboxes.html',
       '1999_Jan/20_ScamAlert.html',
       '1999_Jan/30_HermeneuticsinEverydayLife.html',
       '1999_Jul/07_Toolstotheminers.html',
       '1999_Jul/12_Newwwsboy2NewwwsHarder.html',
       '1999_Jul/14_XenophilicLuddite.html',
       '1999_Jul/17_4wheelsgood.html',
       '1999_Jul/18_AnotherQuadricycleUpdate.html',
       '1999_Jul/19_GodsTotalQualityManagementQuestionnaire.html',
       '1999_Jul/1_BurningManShopping.html',
       '1999_Jul/21_JFKJrredux.html',
       '1999_Jul/22_OnAsknot.html',
       '1999_Jul/2_SlashSold.html',
       '1999_Jul/2_TheTallShips.html',
       '1999_Jul/6_LifeasaPollsterTakedeux.html',
       '1999_Jun/10_StupidRenderManTricksatSIGGRAPH.html',
       '1999_Jun/22_MyFirstGuestRant.html',
       '1999_Jun/23_reducingtelemarketingcallsandmails.html',
       '1999_Jun/26_HappyDanDay.html',
       '1999_Jun/29_Godlastspottedat.html',
       '1999_Mar/04_AnnabelChongmeetstheOlympics.html',
       '1999_Mar/08_JillbertMSullivan.html',
       '1999_Mar/10_Notesforanautomatedweblogmanager.html',
       '1999_Mar/12_ArchitectsandInterfaceEngineering.html',
       '1999_Mar/14_Canfantasiescrosstheline.html',
       '1999_Mar/14_Niceguysdontgetlaid.html',
       '1999_Mar/15_Theneedformore.html',
       '1999_Mar/18_ThedeclineofSalon.html',
       '1999_Mar/24_WhitherFlutterbyoneyearlater.html',
       '1999_Mar/25_WhyXMLadoptionwillbeslow.html',
       '1999_Mar/30_AnotherdissatisfiedAmazoncustomer.html',
       '1999_Mar/31_Goingthewrongway.html',
       '1999_May/03_Buyingappliances.html',
       '1999_May/04_DisneyPixarannounceMonstersInc.html',
       '1999_May/10_Reportfromalandscapephotographyexhibit.html',
       '1999_May/11_RussianEnvoyHeadstoBejing.html',
       '1999_May/14_TheConciseShowBizDictionary.html',
       '1999_May/17_Brandsaslifestyles.html',
       '1999_May/17_Carjackingmaybeold.html',
       '1999_May/21_ReviewStarWarsEpisodeIThePhantomMenace.html',
       '1999_May/24_Apersonalnote.html',
       '1999_May/9_ThingsIlearnedaboutbrazing.html',
       '1999_Nov/10_AsafollowuptoTomDuffsIbeforeEqueries.html',
       '1999_Nov/10_FurthernotesontheIbeforeErule.html',
       '1999_Nov/10_ThehazardsofusingincompetentslikeATTfornetservices.html',
       '1999_Nov/19_ToyStory2DigitalScreenings.html',
       '1999_Nov/19_UnixUsability.html',
       '1999_Nov/19_Unixusability.html',
       '1999_Nov/25_HeardRoundtheThanksgivingTable.html',
       '1999_Nov/25_Thanksgiving.html',
       '1999_Oct/12_Foracause.html',
       '1999_Oct/17_BurningManVirginRant.html',
       '1999_Oct/17_OnISPeconomics.html',
       '1999_Oct/20_furtheradventuresatBurningMan.html',
       '1999_Oct/29_ObjectsandAPIstowhatend.html',
       '1999_Oct/29_Taxesoncash.html',
       '1999_Oct/31_XMLRPCpeace.html',
       '1999_Sep/07_BurningMan99.html',
       '1999_Sep/14_TechniciansRhapsody.html',
       '1999_Sep/14_Writingaboutsex.html',
       '1999_Sep/15_Mycolorschemecode.html',
       '1999_Sep/22_SusieBrightatCodys.html',
       '1999_Sep/23_NotesfromtheChurchillClub.html',
       '1999_Sep/24_Somewebcritiquing.html',
       '1999_Sep/27_RealismSurrealismandStupidity.html',
       '1999_Sep/8_BurningManRant.html',
       '1999_Sep/8_BurningManRecompression.html',
       '2000_Dec/12_Whatwirelessneeds.html',
       '2000_Dec/5_Emacscheatsheet.html',
       '2000_Feb/4_Vasectomy.html',
       '2000_Jan/1_BestY2Kscoresofar.html',
       '2000_Jan/22_WebCritiqueInformationdesign.html',
       '2000_Jan/2_Predictionsandresolutions.html',
       '2000_Jan/test.html',
       '2000_May/30_LasVegas.html',
       '2000_Nov/28_SierraTrip.html',
       '2000_Oct/13_Visitingthesoutheast.html',
       '2000_Oct/20_Autobiography.html',
       '2000_Oct/24_CraneArrival.html',
       '2000_Oct/2_CommunityStandards.html',
       '2000_Sep/10_PreliminaryBurningMan2knotes.html',
       '2000_Sep/14_InstallShieldforWindowsInstaller.html',
       '2000_Sep/8_Test.html',
       '2000_Sep/dayinlife.html',
       '2000_Sep/dayinlife1.html',
       '2000_Sep/dayinlife2.html',
       '2000_Sep/dayinlife3.html',
       '2000_Sep/dayinlife4.html',
       '2000_Sep/dayinlife5.html',
       '2000_Sep/dayinlife6.html',
       '2000_Sep/dayinlife7.html',
       '2001_Feb/19_PostgreSQLfromTclwithODBC.html',
       '2001_Feb/21_ChattanoogaSpiritwebsite.html',
       '2001_Feb/2_SwingClubsandBush.html',
      )
	{
	  my ($url) = "http://www.flutterby.com/archives/$file";
	  $url =~ s/txt$/html/;
	  
	  my ($text,$title,$filename,$filetime);
	  $filename = "/home/flutterby/website_text/archives/$file";
	  $filename =~ s/html$/txt/;
	  $filetime = Flutterby::Util::UnixTimeAsISO8601((stat($filename))[9]);
	  open I, $filename
	    or die "Unable to open $filename\n";
	  $title = $file;
	  $text = '';
	  while (<I>)
	    {
	      if (/^\* +(.*)$/)
		{
		  $title = $1;
		}
	      $text .= $_;
	    }
	  close I;
	  my ($id);
	  print "Indexing $url\n";
	  IndexDocument($dbh,$url,$filetime,$title,$text);
	}
  }

if (1)
  {
    my ($sth);
    $sth = $dbh->prepare("SELECT id,text,subject,updated FROM blogentries")
      or die $dbh->errstr;
    $sth->execute();
    my ($entryid,$text,$subject,$url,$updated);
    while (($entryid,$text,$subject,$updated) = $sth->fetchrow_array)
      {
	$subject = "Weblog entry $entryid" unless (defined($subject) && $subject ne '');
	$url = "http://www.flutterby.com/archives/viewentry.cgi?id=$entryid";
	my ($id);
	print "Indexing $url\n";
	IndexDocument($dbh,$url,$updated,$subject,$subject.' '.$text);
      }
  }

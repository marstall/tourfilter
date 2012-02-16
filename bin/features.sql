-- MySQL dump 10.11
--
-- Host: localhost    Database: tourfilter_shared
-- ------------------------------------------------------
-- Server version	5.0.45-community-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `features`
--

DROP TABLE IF EXISTS `features`;
CREATE TABLE `features` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` varchar(255) default NULL,
  `match_id` int(11) default NULL,
  `metro_code` char(32) default NULL,
  `image_id` varchar(255) default NULL,
  `mp3_url` varchar(255) default NULL,
  `mp3_credit_url` varchar(255) default NULL,
  `description` text,
  `tweet_date` date default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `editor_name` int(11) default NULL,
  `editor_metro_code` char(32) default NULL,
  `image_credit_url` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_text` (`term_text`)
) ENGINE=MyISAM AUTO_INCREMENT=86 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `features`
--

LOCK TABLES `features` WRITE;
/*!40000 ALTER TABLE `features` DISABLE KEYS */;
INSERT INTO `features` VALUES (72,'Zili Misik',104329,NULL,'285','','','8 women playing earthy, jingly african/carribbean rythyms. nice vibes, looks like a night you\'d walk away from feeling pretty good. Winners of 2 Boston Music Award this year: Best World Act & Best International Music Act',NULL,'2009-12-11 01:02:09','2009-12-11 01:02:09',0,NULL,'',2),(73,'marco benevento',99916,NULL,'286','','','like tortoise, new yorker marco benevento mixes rock with experimental music and jazz. downtempo, airy compositions filled with strange electronic sounds and flaming-lips-like crescendos. check out this <a href=\'http://www.youtube.com/watch?v=D2dYHCa-b38&feature=youtube_gdata\'>awesome video</a>.',NULL,'2009-12-11 16:38:47','2009-12-11 16:38:47',0,NULL,'',2),(74,'james cotton',99873,NULL,'287','','','\"Mr. Superharp\", born in Tunica, Miss. in 1935, has played harmonica for Muddy Waters, Led Zeppelin and B.B. King. Soulful, heart-dropping, sweat-dripping breakdowns. <a href=\'http://www.youtube.com/watch?v=jBeuco0PgJs&feature=youtube_gdata\'>check the video</a>',NULL,'2009-12-12 15:32:03','2009-12-12 15:32:03',0,NULL,'',2),(75,'Dutchess and The Duke',104440,NULL,'293','http://www.hardlyart.com/mp3/DD_LivingThisLife.mp3','','Spare, raw, blues & rock, simultaneously classic and very new sounding. seattle duo are touring for their second album, full of organs & sounds from the early Stones, Velvets. World-weary, rainy-day bitching on the microphone welcomes you in generously. Notice taken by Pitchfork et al.',NULL,'2009-12-14 16:55:18','2009-12-14 16:59:58',0,NULL,'',2),(76,'Willowz',107642,NULL,'294','','','the willowz are a garage rock band based in anaheim, california, formed 2002. the band\'s sound incorpthe willowz are a garage rock band based in anaheim, california, formed 2002. the band\'s sound incorp',NULL,'2009-12-14 19:30:15','2009-12-14 19:30:15',0,NULL,'',2),(77,'Xela',108273,NULL,'295','','','Brit John Twells runs the <a href=\'http://typerecords.com/\'>Type</a> imprint here in Boston and, as Xela, releases experimental records that would make fitting Tarkovsky soundtracks: broken electronics, 10-mile-high strings, backward loops, piano strings plucked.',NULL,'2009-12-16 01:15:43','2009-12-16 01:15:43',0,NULL,'',2),(78,'mission of burma',103360,NULL,'296','','','Formed in Boston in 1979, Mission of Burma is known best for their insouciant post-punk gems \"That\'s When I Reach For My Revolver\" and \"Academy Fight Song.\" With a new album just out, they\'re touring nationally.',NULL,'2009-12-17 00:10:42','2009-12-17 00:10:42',0,NULL,'',2),(79,'wrens',107308,NULL,'297','http://wrens.com/files/mp3s/The%20Wrens%20-%20Everyone%20Choose%20Sides.mp3','','The New Jersey-bred Wrens, touring at this end of 17 years of Aimee Mann-like label heartbreaks, rock in a grown-up, melodic way; their live show is reputed to be rhapsodic and rambunctious.',NULL,'2009-12-17 18:51:58','2009-12-17 18:51:58',0,NULL,'',2),(80,'Cribs',105251,NULL,'298','','','Johnny Marr, the God-like guitarist for the Smiths, is a Cribs member and will be touring with them for their visit to the Paradise. Laddish UK rock band, with saucy lyrics (sample song names: \"A Man\'s Needs\", \"Girls Like Mystery\"). ',NULL,'2009-12-18 17:29:10','2009-12-18 17:29:10',0,NULL,'',2),(81,'major stars',107158,NULL,'299','','','On this night Boston\'s Major Stars are celebrating their new album, out on on Chicago\'s <a href=\"http://www.dragcity.com\">Drag City</a> label, home to Bonnie \"Prince\" Billy, Bill Callahan, Jim O\'Rourke, etc. etc. Long signed to Cambridge\'s <a href=\'http://www.twistedvillage.com/\'>Twisted Village</a>, which is a noise/experimental label as well as an underground record shop on Eliot St. in Harvard Square, Major Stars play loud, guitar-heavy psychedelic rock.',NULL,'2009-12-20 23:01:37','2009-12-20 23:01:37',0,NULL,'',2),(82,'prefuse 73',107503,NULL,'302','','','an inspired, cut-up hip-hop productionist: short-half-life beats, high-impact samples, lsd-influenced, allusive passages. Prefuse 73 is the nom-de-laptop of Scott Herren, who came up in the Atlanta mixing rooms of the Dirty South rap movement and combines glowing, blaring funk with frequent trips to outer space.',NULL,'2009-12-29 17:09:53','2009-12-30 22:39:23',0,NULL,'',2),(83,'sodafrog',109854,NULL,'303','','','Sweet plucks of guitar strings, sleighbells, a lonely voice, and 74 plays on MySpace of this <a href=\'http://www.myspace.com/sodafrog\'> beautiful song \'Central Nonsense\'</a>.',NULL,'2009-12-30 23:19:19','2009-12-30 23:19:19',0,NULL,'',2),(85,'28 degrees taurus',107076,NULL,'309','','','Boston rockers deliver a loud show, though their recorded tracks have more of an ambient sound. Their (female) vocalist and flanging, warbling guitars give them echoes of My Bloody Valentine and Cocteau Twins. <a href=\'http://www.myspace.com/28degreestaurus\'>on MySpace</a>',NULL,'2010-01-04 11:51:40','2010-01-04 11:54:29',0,NULL,'http://www.myspace.com/28degreestaurus',2);
/*!40000 ALTER TABLE `features` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-01-08 20:21:32

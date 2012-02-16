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
-- Table structure for table `actions`
--

DROP TABLE IF EXISTS `actions`;
CREATE TABLE `actions` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `user_registered_on` datetime default NULL,
  `username` char(32) default NULL,
  `action` char(32) default NULL,
  `object_type` char(32) default NULL,
  `object_description` varchar(255) default NULL,
  `metro_code` char(16) default NULL,
  `user_id` int(11) default NULL,
  `object_id` int(11) default NULL,
  `note_entity` varchar(255) default NULL,
  `note` varchar(64) default NULL,
  `referer_domain` varchar(64) default NULL,
  `referer_path` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=54315 DEFAULT CHARSET=latin1;

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
CREATE TABLE `articles` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `description` text,
  `domain` char(64) default NULL,
  `priority` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_text` (`term_text`,`url`),
  KEY `term_text_2` (`term_text`)
) ENGINE=MyISAM AUTO_INCREMENT=18846 DEFAULT CHARSET=latin1;

--
-- Table structure for table `artist_terms`
--

DROP TABLE IF EXISTS `artist_terms`;
CREATE TABLE `artist_terms` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `term_text` varchar(255) default NULL,
  `artist_name` varchar(255) default NULL,
  `imported_event_id` int(11) default NULL,
  `status` enum('new','valid','invalid') default 'new',
  `match_probability` enum('likely','unlikely','undetermined') default 'undetermined',
  PRIMARY KEY  (`id`),
  KEY `term_text` (`term_text`),
  KEY `artist_name` (`artist_name`),
  KEY `imported_event_id` (`imported_event_id`),
  KEY `artist_name_2` (`artist_name`,`status`),
  KEY `artist_name_3` (`artist_name`,`status`)
) ENGINE=MyISAM AUTO_INCREMENT=2066034 DEFAULT CHARSET=latin1;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL default '0',
  `match_id` int(11) NOT NULL default '0',
  `text` text NOT NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `num_votes` int(11) default NULL,
  `total_vote` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=413 DEFAULT CHARSET=latin1;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL default '0',
  `recommendation_id` int(11) NOT NULL default '0',
  `email_address` varchar(255) default NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `contact_user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=332 DEFAULT CHARSET=latin1;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `action` char(8) default NULL,
  `object_type` char(16) default NULL,
  `object_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `info` varchar(255) default NULL,
  `username` char(32) default NULL,
  `metro_code` char(16) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=70041 DEFAULT CHARSET=latin1;

--
-- Table structure for table `external_clicks`
--

DROP TABLE IF EXISTS `external_clicks`;
CREATE TABLE `external_clicks` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `youser_id` int(11) default NULL,
  `ip_address` char(16) default NULL,
  `domain` char(64) default NULL,
  `url` char(255) default NULL,
  `referer` char(255) default NULL,
  `time_to_render` float default NULL,
  `session_id` char(64) default NULL,
  `perm_session_id` char(64) default NULL,
  `user_agent` char(255) default NULL,
  `referer_domain` char(255) default NULL,
  `original_referer_domain` varchar(64) default NULL,
  `original_referer_path` varchar(255) default NULL,
  `level` enum('primary','secondary') default NULL,
  `page_type` varchar(16) default NULL,
  `page_name` varchar(255) default NULL,
  `page_section` varchar(32) default NULL,
  `metro_code` varchar(32) default NULL,
  `source` char(16) default NULL,
  `link_source` char(32) default NULL,
  `term_text` varchar(255) default NULL,
  `referer_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `created_at` (`created_at`),
  KEY `term_text` (`term_text`),
  KEY `term_text_2` (`term_text`,`page_type`,`created_at`),
  KEY `created_at_3` (`created_at`,`page_type`,`term_text`),
  KEY `term_text_3` (`term_text`,`created_at`),
  KEY `created_at_2` (`created_at`,`term_text`),
  KEY `referer_id` (`referer_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1153224 DEFAULT CHARSET=latin1;

--
-- Table structure for table `facebook_sessions`
--

DROP TABLE IF EXISTS `facebook_sessions`;
CREATE TABLE `facebook_sessions` (
  `id` int(11) NOT NULL auto_increment,
  `facebook_userid` varchar(128) default NULL,
  `fb_sig_session_key` varchar(128) default NULL,
  `created_at` datetime default NULL,
  `data` blob,
  `activated` set('false','true') default 'false',
  PRIMARY KEY  (`id`),
  KEY `facebook_userid` (`facebook_userid`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Table structure for table `facebook_settings`
--

DROP TABLE IF EXISTS `facebook_settings`;
CREATE TABLE `facebook_settings` (
  `id` int(11) NOT NULL auto_increment,
  `facebook_userid` varchar(128) default NULL,
  `friend_id` varchar(128) default NULL,
  `name` varchar(128) default NULL,
  `metro_code` varchar(128) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `music` text,
  `zipcode` char(5) default NULL,
  `friends_music` text,
  `has_added_app` varchar(4) default NULL,
  `tv` text,
  `birthday` varchar(32) default NULL,
  `city` varchar(128) default NULL,
  `state` varchar(8) default NULL,
  `country` varchar(8) default NULL,
  `zip` varchar(8) default NULL,
  `visited_canvas` enum('true','false') default NULL,
  `tourfilter_username` varchar(128) default NULL,
  PRIMARY KEY  (`id`),
  KEY `facebook_userid` (`facebook_userid`)
) ENGINE=MyISAM AUTO_INCREMENT=3977 DEFAULT CHARSET=latin1;

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
  `editor_metro_code` char(32) default NULL,
  `image_credit_url` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `username` varchar(255) default NULL,
  `image_credit_description` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_text` (`term_text`)
) ENGINE=MyISAM AUTO_INCREMENT=285 DEFAULT CHARSET=latin1;

--
-- Temporary table structure for view `frequent_artists_month`
--

DROP TABLE IF EXISTS `frequent_artists_month`;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_month`*/;
/*!50001 CREATE TABLE `frequent_artists_month` (
  `id` int(11),
  `text` varchar(255),
  `cnt` bigint(21)
) */;

--
-- Temporary table structure for view `frequent_artists_week`
--

DROP TABLE IF EXISTS `frequent_artists_week`;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_week`*/;
/*!50001 CREATE TABLE `frequent_artists_week` (
  `id` int(11),
  `text` varchar(255),
  `cnt` bigint(21)
) */;

--
-- Temporary table structure for view `frequent_artists_year`
--

DROP TABLE IF EXISTS `frequent_artists_year`;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_year`*/;
/*!50001 CREATE TABLE `frequent_artists_year` (
  `id` int(11),
  `text` varchar(255),
  `cnt` bigint(21)
) */;

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
  `id` int(11) NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `width` int(4) default NULL,
  `height` int(4) default NULL,
  `alt_text` varchar(1024) default NULL,
  `term_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `term_text` varchar(128) default NULL,
  `source_url` char(255) default NULL,
  `problem` enum('yes','no') default 'no',
  `processed_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_text` (`term_text`)
) ENGINE=MyISAM AUTO_INCREMENT=799 DEFAULT CHARSET=latin1;

--
-- Table structure for table `imported_events`
--

DROP TABLE IF EXISTS `imported_events`;
CREATE TABLE `imported_events` (
  `id` int(11) NOT NULL auto_increment,
  `uid` char(64) default NULL,
  `date` datetime default NULL,
  `time` time default NULL,
  `venue_id` int(11) default NULL,
  `url` char(255) default NULL,
  `body` char(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `artist_id` int(11) default NULL,
  `major_cat_id` int(11) default NULL,
  `minor_cat_id` int(11) default NULL,
  `cancelled` enum('yes','no') default 'no',
  `status` enum('new','term_found','no_term_found','made_match','rejected','processed_unknown_disposition') default NULL,
  `level` enum('primary','secondary') default 'primary',
  `venue_name` char(255) default NULL,
  `source` char(16) default NULL,
  `user_id` int(11) default NULL,
  `username` char(32) default NULL,
  `user_metro` char(32) default NULL,
  `num_tickets` int(11) default NULL,
  `price_high` float(10,2) default NULL,
  `price_low` float(10,2) default NULL,
  `onsale_date` datetime default NULL,
  `presale_date` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `venue_id` (`venue_id`),
  KEY `major_cat_id` (`major_cat_id`),
  KEY `body` (`body`),
  KEY `status` (`status`),
  KEY `uid` (`uid`),
  KEY `source` (`source`,`body`,`date`,`venue_id`),
  KEY `venue_id_2` (`venue_id`,`body`),
  KEY `venue_id_3` (`venue_id`,`body`),
  KEY `user_id` (`user_id`),
  KEY `source_2` (`source`),
  KEY `onsale_date` (`onsale_date`)
) ENGINE=MyISAM AUTO_INCREMENT=1019308 DEFAULT CHARSET=latin1;

--
-- Table structure for table `invitations`
--

DROP TABLE IF EXISTS `invitations`;
CREATE TABLE `invitations` (
  `id` int(11) NOT NULL auto_increment,
  `email_address` varchar(255) default NULL,
  `from_user_id` int(11) default NULL,
  `to_user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `to_user_registered_at` datetime default NULL,
  `message` text,
  PRIMARY KEY  (`id`),
  KEY `email_address` (`email_address`)
) ENGINE=MyISAM AUTO_INCREMENT=1131 DEFAULT CHARSET=latin1;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
  `id` int(11) NOT NULL auto_increment,
  `term_id` int(11) default NULL,
  `term_text` char(64) default NULL,
  `asin` char(32) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `source_reference` char(8) default NULL,
  `detail_page_url` varchar(255) default NULL,
  `sales_rank` int(11) default NULL,
  `small_image_url` varchar(255) default NULL,
  `medium_image_url` varchar(255) default NULL,
  `large_image_url` varchar(255) default NULL,
  `artist` varchar(128) default NULL,
  `binding` char(32) default NULL,
  `format` char(32) default NULL,
  `label` char(128) default NULL,
  `list_price` int(11) default NULL,
  `number_of_discs` int(4) default NULL,
  `product_group` char(32) default NULL,
  `publisher` char(32) default NULL,
  `release_date` date default NULL,
  `studio` char(32) default NULL,
  `title` varchar(255) default NULL,
  `upc` char(16) default NULL,
  `lowest_new_price` int(11) default NULL,
  `lowest_used_price` int(11) default NULL,
  `total_new` int(11) default NULL,
  `total_used` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=116953 DEFAULT CHARSET=latin1;

--
-- Table structure for table `matches`
--

DROP TABLE IF EXISTS `matches`;
CREATE TABLE `matches` (
  `id` int(11) NOT NULL auto_increment,
  `term_id` int(11) NOT NULL default '0',
  `page_id` int(11) NOT NULL default '0',
  `status` enum('new','approved','notified','invalid') default NULL,
  `recommendations_count` int(11) default '0',
  `time_status` enum('past','reevaluating','future') default NULL,
  `year` int(11) default NULL,
  `month` int(11) default NULL,
  `day` int(11) default NULL,
  `date_for_sorting` datetime default NULL,
  `calculated_date_for_sorting` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `flag_count` int(11) default '0',
  `comments_count` int(11) default '0',
  `date_position` enum('before','after') default 'before',
  `month_position` int(4) default NULL,
  `date_block` text,
  `feature_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_id` (`term_id`,`page_id`,`status`),
  KEY `date_for_sorting` (`date_for_sorting`),
  KEY `status` (`status`),
  KEY `time_status` (`time_status`),
  KEY `time_status_2` (`time_status`,`status`,`date_for_sorting`),
  KEY `time_status_3` (`time_status`,`status`,`date_for_sorting`,`term_id`),
  KEY `term_id_2` (`term_id`,`time_status`,`status`,`date_for_sorting`),
  KEY `feature_id` (`feature_id`)
) ENGINE=MyISAM AUTO_INCREMENT=39674 DEFAULT CHARSET=latin1;

--
-- Table structure for table `metros`
--

DROP TABLE IF EXISTS `metros`;
CREATE TABLE `metros` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(128) NOT NULL default '',
  `code` varchar(128) default NULL,
  `num_places` int(11) default NULL,
  `status` set('active','inactive') default 'inactive',
  `state` char(4) default NULL,
  `zipcode` char(5) default NULL,
  `lng` double default NULL,
  `lat` double default NULL,
  `country_code` char(2) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=MyISAM AUTO_INCREMENT=1175 DEFAULT CHARSET=latin1;

--
-- Table structure for table `metros_venues`
--

DROP TABLE IF EXISTS `metros_venues`;
CREATE TABLE `metros_venues` (
  `id` int(11) NOT NULL auto_increment,
  `venue_id` int(11) NOT NULL,
  `metro_code` char(32) default NULL,
  `status` enum('valid','invalid') default 'valid',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `venue_id` (`venue_id`,`metro_code`)
) ENGINE=MyISAM AUTO_INCREMENT=33967 DEFAULT CHARSET=latin1;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
CREATE TABLE `notes` (
  `id` int(11) NOT NULL auto_increment,
  `source_id` int(11) default NULL,
  `action` varchar(16) default NULL,
  `message` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=206 DEFAULT CHARSET=latin1;

--
-- Table structure for table `npr_artists`
--

DROP TABLE IF EXISTS `npr_artists`;
CREATE TABLE `npr_artists` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `artist_id` int(11) default NULL,
  `normalized_name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10430 DEFAULT CHARSET=latin1;

--
-- Table structure for table `page_views`
--

DROP TABLE IF EXISTS `page_views`;
CREATE TABLE `page_views` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `youser_id` int(11) default NULL,
  `ip_address` char(16) default NULL,
  `domain` char(64) default NULL,
  `url` char(255) default NULL,
  `form_contents` char(255) default NULL,
  `referer` char(255) default NULL,
  `time_to_render` float default NULL,
  `session_id` char(64) default NULL,
  `perm_session_id` char(64) default NULL,
  `user_agent` char(255) default NULL,
  `referer_domain` char(255) default NULL,
  `source` set('js','ruby') default NULL,
  `original_referer_domain` varchar(64) default NULL,
  `original_referer_path` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  KEY `created_at` (`created_at`)
) ENGINE=MyISAM AUTO_INCREMENT=26062532 DEFAULT CHARSET=latin1;

--
-- Table structure for table `pages`
--

DROP TABLE IF EXISTS `pages`;
CREATE TABLE `pages` (
  `id` int(11) NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `raw_body` mediumtext,
  `body` mediumtext,
  `last_crawled_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `place_id` int(11) NOT NULL default '0',
  `meth` enum('GET','POST','MANUAL') default NULL,
  `flags` set('template-based') default NULL,
  `status` enum('past','future') default NULL,
  `year` int(11) default NULL,
  `month` int(11) default NULL,
  `day` int(11) default NULL,
  `raw_body_md5` char(16) default NULL,
  `num_consecutive_errors` int(4) default NULL,
  `last_changed_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `fk_pages_places` (`place_id`),
  KEY `status` (`status`)
) ENGINE=MyISAM AUTO_INCREMENT=1861 DEFAULT CHARSET=latin1;

--
-- Table structure for table `place_images`
--

DROP TABLE IF EXISTS `place_images`;
CREATE TABLE `place_images` (
  `id` int(11) NOT NULL auto_increment,
  `place_id` int(11) default NULL,
  `page_id` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `width` int(4) default NULL,
  `height` int(4) default NULL,
  `alt_text` varchar(1024) default NULL,
  `term_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `term_text` varchar(128) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=MyISAM AUTO_INCREMENT=3035 DEFAULT CHARSET=latin1;

--
-- Table structure for table `places`
--

DROP TABLE IF EXISTS `places`;
CREATE TABLE `places` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `url` varchar(255) NOT NULL default '',
  `ticket_url` varchar(255) default NULL,
  `metro_id` int(11) NOT NULL default '0',
  `notes` text,
  `date_type` set('before','after') default NULL,
  `date_regexp` varchar(255) default NULL,
  `day_regexp` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `time_type` set('permanent','temporary') default 'permanent',
  `start_date` date default NULL,
  `end_date` date default NULL,
  `status` set('active','inactive','broken') default 'active',
  `date_status` enum('working','broken','inconsistent') default NULL,
  `num_images` int(11) default NULL,
  `num_shows` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `status` (`status`)
) ENGINE=MyISAM AUTO_INCREMENT=81 DEFAULT CHARSET=latin1;

--
-- Table structure for table `playlists`
--

DROP TABLE IF EXISTS `playlists`;
CREATE TABLE `playlists` (
  `id` int(11) NOT NULL auto_increment,
  `source` varchar(8) default NULL,
  `url` varchar(255) default NULL,
  `show_id` varchar(8) default NULL,
  `body` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `show_id` (`show_id`)
) ENGINE=MyISAM AUTO_INCREMENT=30328 DEFAULT CHARSET=latin1;

--
-- Table structure for table `recommendations`
--

DROP TABLE IF EXISTS `recommendations`;
CREATE TABLE `recommendations` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL default '0',
  `match_id` int(11) NOT NULL default '0',
  `text` text NOT NULL,
  `mp3_url` varchar(255) default NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `event_at` date default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=270 DEFAULT CHARSET=latin1;

--
-- Table structure for table `recommendees_recommenders`
--

DROP TABLE IF EXISTS `recommendees_recommenders`;
CREATE TABLE `recommendees_recommenders` (
  `id` int(11) NOT NULL auto_increment,
  `recommendee_id` int(11) NOT NULL default '0',
  `recommender_id` int(11) NOT NULL default '0',
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=525 DEFAULT CHARSET=latin1;

--
-- Table structure for table `referers`
--

DROP TABLE IF EXISTS `referers`;
CREATE TABLE `referers` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `date` datetime default NULL,
  `ip_address` char(16) default NULL,
  `path` char(255) default NULL,
  `domain` char(64) default NULL,
  `search_engine` char(64) default NULL,
  `referer` char(255) default NULL,
  `length` int(11) default NULL,
  `result_code` int(11) default NULL,
  `user_agent` char(255) default NULL,
  `metro_code` varchar(32) default NULL,
  `source` char(16) default NULL,
  `term_text` varchar(255) default NULL,
  `keywords` varchar(255) default NULL,
  `keywords_without_metro` varchar(255) default NULL,
  `external_click_id` int(11) default NULL,
  `page_type` char(32) default NULL,
  `external_click_domain` char(64) default NULL,
  `referer_domain` char(64) default NULL,
  `match_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `created_at` (`created_at`),
  KEY `term_text` (`term_text`),
  KEY `external_click_id` (`external_click_id`)
) ENGINE=MyISAM AUTO_INCREMENT=582128 DEFAULT CHARSET=latin1;

--
-- Table structure for table `related_terms`
--

DROP TABLE IF EXISTS `related_terms`;
CREATE TABLE `related_terms` (
  `id` int(11) NOT NULL auto_increment,
  `term_id` int(11) default NULL,
  `term_text` varchar(64) default NULL,
  `related_term_id` int(11) default NULL,
  `related_term_text` varchar(64) default NULL,
  `count` int(11) default NULL,
  `played_with_count` int(11) default NULL,
  `score` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `term_id` (`id`),
  KEY `term_text` (`term_text`),
  KEY `term_id_2` (`term_id`),
  KEY `count` (`count`),
  KEY `count_3` (`count`),
  KEY `score` (`score`),
  KEY `term_text_2` (`term_text`,`related_term_text`),
  KEY `term_text_3` (`term_text`,`count`)
) ENGINE=MyISAM AUTO_INCREMENT=20983709 DEFAULT CHARSET=latin1;

--
-- Table structure for table `secondary_tickets`
--

DROP TABLE IF EXISTS `secondary_tickets`;
CREATE TABLE `secondary_tickets` (
  `id` int(11) NOT NULL auto_increment,
  `url` char(255) default NULL,
  `body` char(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `seller` char(32) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `body` (`body`,`seller`)
) ENGINE=MyISAM AUTO_INCREMENT=2206 DEFAULT CHARSET=latin1;

--
-- Table structure for table `shared_events`
--

DROP TABLE IF EXISTS `shared_events`;
CREATE TABLE `shared_events` (
  `id` int(11) NOT NULL auto_increment,
  `uid` int(11) default NULL,
  `date` datetime default NULL,
  `location` char(255) default NULL,
  `url` char(255) default NULL,
  `summary` char(255) default NULL,
  `description` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `metro_code` char(32) default NULL,
  `metro_name` char(32) default NULL,
  `metro_state` char(4) default NULL,
  `metro_zipcode` char(5) default NULL,
  `metro_lat` double default NULL,
  `metro_lng` double default NULL,
  `source` char(32) default NULL,
  `venue_id` int(11) default NULL,
  `ticket_json` text,
  PRIMARY KEY  (`id`),
  KEY `summary` (`summary`),
  KEY `date` (`date`),
  KEY `summary_2` (`summary`,`location`,`metro_code`),
  KEY `location` (`location`),
  KEY `metro_code` (`metro_code`)
) ENGINE=MyISAM AUTO_INCREMENT=17418816 DEFAULT CHARSET=latin1;

--
-- Table structure for table `shared_terms`
--

DROP TABLE IF EXISTS `shared_terms`;
CREATE TABLE `shared_terms` (
  `id` int(11) NOT NULL auto_increment,
  `text` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `num_tracks` int(11) default NULL,
  `num_ram_tracks` int(11) default NULL,
  `num_mp3_tracks` int(11) default NULL,
  `metro_code` char(32) default NULL,
  `mp3_url` varchar(255) default NULL,
  `source` char(32) default NULL,
  `url` varchar(255) default NULL,
  `num_trackers` int(11) default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `text_2` (`text`),
  KEY `text` (`text`),
  KEY `num_trackers` (`num_trackers`)
) ENGINE=MyISAM AUTO_INCREMENT=2705260 DEFAULT CHARSET=latin1;

--
-- Table structure for table `sources`
--

DROP TABLE IF EXISTS `sources`;
CREATE TABLE `sources` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) default NULL,
  `description` varchar(255) default NULL,
  `status` enum('new','contacted','responded','requires_action','declined','published') default NULL,
  `genre` varchar(32) default NULL,
  `locale` varchar(32) default NULL,
  `person1_firstname` varchar(128) default NULL,
  `person1_lastname` varchar(128) default NULL,
  `person1_title` varchar(128) default NULL,
  `person1_email` varchar(128) default NULL,
  `person1_phone` varchar(32) default NULL,
  `url` varchar(255) default NULL,
  `blog_url` varchar(255) default NULL,
  `rss_url` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `num_referrals` int(11) default NULL,
  `num_signups` int(11) default NULL,
  `num_tracks` int(11) default NULL,
  `category` varchar(32) default NULL,
  `user_id` int(11) default NULL,
  `notes_count` int(11) default '0',
  `image` varchar(255) default NULL,
  `mention_date` date default NULL,
  `blurb` text,
  `feature` enum('feature1','feature2','feature3') default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=246 DEFAULT CHARSET=latin1;

--
-- Table structure for table `taggings`
--

DROP TABLE IF EXISTS `taggings`;
CREATE TABLE `taggings` (
  `tag_id` int(11) NOT NULL default '0',
  `user_id` int(11) NOT NULL default '0',
  `target_id` int(11) NOT NULL default '0',
  `target_type` set('match','user','term','place') default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `term_urls`
--

DROP TABLE IF EXISTS `term_urls`;
CREATE TABLE `term_urls` (
  `id` int(11) NOT NULL auto_increment,
  `term_id` int(11) default NULL,
  `term_text` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `source_page_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=MyISAM AUTO_INCREMENT=3694 DEFAULT CHARSET=latin1;

--
-- Table structure for table `term_words`
--

DROP TABLE IF EXISTS `term_words`;
CREATE TABLE `term_words` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` int(11) default NULL,
  `word` varchar(255) NOT NULL,
  `source` char(16) default NULL,
  `created_at` datetime default NULL,
  `tweet_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `terms`
--

DROP TABLE IF EXISTS `terms`;
CREATE TABLE `terms` (
  `id` int(11) NOT NULL auto_increment,
  `text` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `num_tracks` int(11) default NULL,
  `num_ram_tracks` int(11) default NULL,
  `num_mp3_tracks` int(11) default NULL,
  `source` char(32) default NULL,
  `url` varchar(255) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `text_2` (`text`),
  KEY `text` (`text`)
) ENGINE=MyISAM AUTO_INCREMENT=27778 DEFAULT CHARSET=latin1;

--
-- Table structure for table `terms_temp`
--

DROP TABLE IF EXISTS `terms_temp`;
CREATE TABLE `terms_temp` (
  `id` int(11) NOT NULL auto_increment,
  `text` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `num_tracks` int(11) default NULL,
  `num_ram_tracks` int(11) default NULL,
  `num_mp3_tracks` int(11) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `text_2` (`text`),
  KEY `text` (`text`)
) ENGINE=MyISAM AUTO_INCREMENT=6348 DEFAULT CHARSET=latin1;

--
-- Table structure for table `terms_users`
--

DROP TABLE IF EXISTS `terms_users`;
CREATE TABLE `terms_users` (
  `user_id` int(11) NOT NULL default '0',
  `term_id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  KEY `term_id` (`term_id`),
  KEY `user_id` (`user_id`),
  KEY `user_id_2` (`user_id`,`term_id`),
  KEY `term_id_2` (`term_id`,`user_id`),
  KEY `user_id_3` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `ticket_offer_archives`
--

DROP TABLE IF EXISTS `ticket_offer_archives`;
CREATE TABLE `ticket_offer_archives` (
  `id` int(11) NOT NULL auto_increment,
  `uid` char(64) default NULL,
  `imported_event_id` int(11) default NULL,
  `price` int(11) default NULL,
  `quantity` int(11) default NULL,
  `section` varchar(32) default NULL,
  `row` varchar(4) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `source` char(16) default NULL,
  PRIMARY KEY  (`id`),
  KEY `imported_event_id` (`imported_event_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `ticket_offers`
--

DROP TABLE IF EXISTS `ticket_offers`;
CREATE TABLE `ticket_offers` (
  `id` int(11) NOT NULL auto_increment,
  `uid` char(64) default NULL,
  `imported_event_id` int(11) default NULL,
  `price` float(11,2) default NULL,
  `quantity` int(11) default NULL,
  `section` varchar(32) default NULL,
  `row` varchar(4) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `source` char(16) default NULL,
  PRIMARY KEY  (`id`),
  KEY `imported_event_id` (`imported_event_id`)
) ENGINE=MyISAM AUTO_INCREMENT=29066491 DEFAULT CHARSET=latin1;

--
-- Table structure for table `tracks`
--

DROP TABLE IF EXISTS `tracks`;
CREATE TABLE `tracks` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` varchar(255) default NULL,
  `band_name` varchar(255) default NULL,
  `track_name` varchar(255) default NULL,
  `album_name` varchar(255) default NULL,
  `url` varchar(255) default NULL,
  `file_type` enum('ram','m3u','mp3') default NULL,
  `offset` int(11) default NULL,
  `playlist_id` int(11) default NULL,
  `playlist_url` varchar(255) default NULL,
  `source_reference` char(8) default NULL,
  `label` varchar(255) default NULL,
  `archive_id` varchar(8) default NULL,
  `show_id` varchar(8) default NULL,
  `year` int(11) default NULL,
  `description` text,
  `status` enum('valid','invalid') default NULL,
  `ttl` int(11) default NULL,
  `filename` varchar(255) default NULL,
  `locally_cached` enum('true','false') default 'false',
  PRIMARY KEY  (`id`),
  KEY `band_name` (`band_name`),
  KEY `track_name` (`track_name`),
  KEY `file_type` (`file_type`),
  KEY `file_type_2` (`file_type`),
  KEY `term_id_2` (`file_type`),
  KEY `file_type_3` (`file_type`),
  KEY `file_type_4` (`file_type`),
  KEY `term_id_4` (`file_type`),
  KEY `term_text` (`term_text`)
) ENGINE=MyISAM AUTO_INCREMENT=10256331 DEFAULT CHARSET=latin1;

--
-- Table structure for table `tweets`
--

DROP TABLE IF EXISTS `tweets`;
CREATE TABLE `tweets` (
  `id` int(11) NOT NULL auto_increment,
  `guid` int(11) default NULL,
  `term_text` int(11) default NULL,
  `date` datetime default NULL,
  `text` varchar(255) NOT NULL,
  `author` text NOT NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `email_address` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `registered_on` datetime default NULL,
  `last_logged_in_on` datetime default NULL,
  `privs` set('admin','manage_places','manage_urls','manage_matches','send_emails') default NULL,
  `last_visited_on` datetime default NULL,
  `last_user_agent` varchar(255) default NULL,
  `about` text,
  `referer_domain` varchar(128) default NULL,
  `referer_path` varchar(255) default NULL,
  `wants_newsletter` enum('true','false') default NULL,
  `wants_private_messages` enum('true','false') default 'true',
  `wants_weekly_newsletter` enum('true','false') default 'false',
  `registration_type` enum('normal','basic') default 'normal',
  `registration_code` char(32) default NULL,
  `newsletter_last_sent_on` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `registration_type` (`registration_type`),
  KEY `registration_type_2` (`registration_type`),
  KEY `last_visited_on` (`last_visited_on`)
) ENGINE=MyISAM AUTO_INCREMENT=10878 DEFAULT CHARSET=latin1;

--
-- Table structure for table `venue_name_link`
--

DROP TABLE IF EXISTS `venue_name_link`;
CREATE TABLE `venue_name_link` (
  `id` int(11) NOT NULL auto_increment,
  `venue_name_1` varchar(255) default NULL,
  `venue_name_2` varchar(255) default NULL,
  `status` enum('new','invalid','valid') default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `venue_name_1` (`venue_name_1`,`venue_name_2`),
  KEY `venue_name_1_2` (`venue_name_1`),
  KEY `venue_name_1_3` (`venue_name_1`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `venues`
--

DROP TABLE IF EXISTS `venues`;
CREATE TABLE `venues` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `code` varchar(32) NOT NULL default '',
  `url` varchar(255) NOT NULL default '',
  `affiliate_url_1` varchar(1024) default NULL,
  `affiliate_url_2` varchar(1024) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `status` set('active','inactive','broken') default 'active',
  `source` varchar(16) NOT NULL default '',
  `address` varchar(255) default NULL,
  `corrected_address` varchar(255) default NULL,
  `geo_precision` char(32) default NULL,
  `address_2` varchar(255) default NULL,
  `city` varchar(64) default '',
  `state` varchar(3) default '',
  `country` varchar(3) default '',
  `zipcode` varchar(8) default NULL,
  `lat` double default NULL,
  `lng` double default NULL,
  `logo_url` varchar(255) default NULL,
  `events_last_imported` int(4) default '0',
  `last_crawled_at` datetime default NULL,
  `user_id` int(11) default NULL,
  `username` char(32) default NULL,
  `user_metro` char(32) default NULL,
  `metros` varchar(255) default NULL,
  `num_shows` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=67377 DEFAULT CHARSET=latin1;

--
-- Table structure for table `venues_located`
--

DROP TABLE IF EXISTS `venues_located`;
CREATE TABLE `venues_located` (
  `name` varchar(255) NOT NULL default '',
  `address` varchar(255) default NULL,
  `city` varchar(64) default '',
  `state` varchar(3) default '',
  `lat` double default NULL,
  `lng` double default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Final view structure for view `frequent_artists_month`
--

/*!50001 DROP TABLE IF EXISTS `frequent_artists_month`*/;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_month`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`chris`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `frequent_artists_month` AS select `terms`.`id` AS `id`,`terms`.`text` AS `text`,count(0) AS `cnt` from (`matches` join `terms`) where ((`matches`.`term_id` = `terms`.`id`) and (`matches`.`status` = _latin1'notified') and ((`matches`.`date_for_sorting` + interval 1 month) > now()) and (`matches`.`day` is not null)) group by `terms`.`text` order by count(0) */;

--
-- Final view structure for view `frequent_artists_week`
--

/*!50001 DROP TABLE IF EXISTS `frequent_artists_week`*/;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_week`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`chris`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `frequent_artists_week` AS select `terms`.`id` AS `id`,`terms`.`text` AS `text`,count(0) AS `cnt` from (`matches` join `terms`) where ((`matches`.`term_id` = `terms`.`id`) and (`matches`.`status` = _latin1'notified') and ((`matches`.`date_for_sorting` + interval 1 week) > now()) and (`matches`.`day` is not null)) group by `terms`.`text` order by count(0) */;

--
-- Final view structure for view `frequent_artists_year`
--

/*!50001 DROP TABLE IF EXISTS `frequent_artists_year`*/;
/*!50001 DROP VIEW IF EXISTS `frequent_artists_year`*/;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`chris`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `frequent_artists_year` AS select `terms`.`id` AS `id`,`terms`.`text` AS `text`,count(0) AS `cnt` from (`matches` join `terms`) where ((`matches`.`term_id` = `terms`.`id`) and (`matches`.`status` = _latin1'notified') and ((`matches`.`date_for_sorting` + interval 1 year) > now()) and (`matches`.`day` is not null)) group by `terms`.`text` order by count(0) */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-06-19 18:56:26

CREATE TABLE `imported_events_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT '0',
  `imported_event_id` int(11) NOT NULL DEFAULT '0',
  `metro_code` char(32) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
)

alter table imported_events_users add column deleted_flag boolean default false;

CREATE TABLE `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `text` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
);

CREATE TABLE `taggings` (
  `tag_id` int(11) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `imported_event_id` int(11) NOT NULL DEFAULT '0',
  KEY `tag_id` (`tag_id`),
  KEY `imported_event_id` (`imported_event_id`)
)

alter table images add column md5 char(64);
alter table images add index(md5);
alter table taggings add column `id` int(11) PRIMARY KEY NOT NULL AUTO_INCREMENT ;

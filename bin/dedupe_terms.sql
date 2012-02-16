drop table terms_temp;
CREATE TABLE `terms_temp` (
  `id` int(11) NOT NULL auto_increment,
  `text` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `num_tracks` int(11) default NULL,
  `num_ram_tracks` int(11) default NULL,
  `num_mp3_tracks` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `text` (`text`)
)
alter table terms_temp add constraint unique(text);

insert ignore into terms_temp (select * from terms); 

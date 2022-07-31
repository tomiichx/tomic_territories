CREATE TABLE IF NOT EXISTS `tomic_territories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text DEFAULT 'NewTerritory',
  `owner` text DEFAULT 'noone',
  `label` text DEFAULT 'NoOne',
  `radius` int(11) DEFAULT 50,
  `coords` longtext NOT NULL,
  `type` text DEFAULT 'default',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `tomic_territories` (`id`, `name`, `owner`, `label`, `radius`, `coords`, `type`) VALUES
	(1, 'Motel', 'gsf', 'GSF', 60, '{"z":33.239501953125,"y":3574.15380859375,"x":1567.4241943359376}', 'dealer'),
	(2, 'Docks', 'noone', 'NoOne', 65, '{"x":1011.2307739257813,"z":39.15380859375,"y":-2867.156005859375}', 'market'),
	(3, 'Plaza', 'noone', 'NoOne', 50, '{"x":-1838.6373291015626,"z":13.0029296875,"y":-1223.5911865234376}', 'dealer'),
	(4, 'Galileo', 'noone', 'NoOne', 55, '{"z":327.6732177734375,"y":1110.7120361328126,"x":-429.21759033203127}', 'dealer'),
	(5, 'Dump', 'noone', 'NoOne', 80, '{"z":19.13623046875,"x":-533.7362670898438,"y":-1682.756103515625}', 'market');

ALTER TABLE `jobs`
  ADD `nedpoeni` INT(11) DEFAULT 0,
  ADD `mespoeni` INT(11) DEFAULT 0,  
  ADD `poeni` INT(11) DEFAULT 0;  

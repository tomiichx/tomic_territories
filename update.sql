-- Execute this to update the columns if you already have used the script before.

ALTER TABLE `jobs`
  CHANGE COLUMN `nedpoeni` `weeklyPoints` INT(11) DEFAULT 0,
  CHANGE COLUMN `mespoeni` `monthlyPoints` INT(11) DEFAULT 0,
  CHANGE COLUMN `poeni` `totalPoints` INT(11) DEFAULT 0;
DROP TABLE IF EXISTS `CSVDATA`;
DROP TABLE IF EXISTS `CATEGORIES`;
DROP TABLE IF EXISTS `MOVING`;
DROP TABLE IF EXISTS `ACCOUNTS`;

--
-- Table structure for table `ACCOUNTS`
--
CREATE TABLE `ACCOUNTS` (
  `id` varchar(10) NOT NULL,
  `name` varchar(255),
  `start_date` date,
  `start_value` FLOAT(8,2),
  `updated` TIMESTAMP NULL DEFAULT NULL,
  `inserted` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
--
-- Table structure for table `CATEGORIES`
--
CREATE TABLE `CATEGORIES` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `matches` VARCHAR(2000), -- comma separated values
  `updated` TIMESTAMP NULL DEFAULT NULL,
  `inserted` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

--
-- Table structure for table `MOVING`
--
CREATE TABLE `MOVINGS` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `matches` VARCHAR(2000), -- comma separated values
  `tolerance` INT,
  `add_month` INT,
  `updated` TIMESTAMP NULL DEFAULT NULL,
  `inserted` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);

--
-- Table structure for table `CSVDATA`
--
CREATE TABLE `CSVDATA` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account` VARCHAR(10) NOT NULL,
  `booking` DATE NOT NULL,
  `valuta` DATE NOT NULL,
  `type` VARCHAR(45) NOT NULL,
  `text` VARCHAR(255),
  `recipient` VARCHAR(255),
  `recipient_account` VARCHAR(40),
  `recipient_bankcode` VARCHAR(40),
  `value` FLOAT(8,2) NOT NULL,
  `currency` VARCHAR(3),
  `info` VARCHAR(255),
  
  `updated` TIMESTAMP NULL DEFAULT NULL,
  `inserted` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  `month` INT,
  `sticky` VARCHAR(1),
  `notes` VARCHAR(255),
  `category` INT,
  
  PRIMARY KEY (`id`),
  FOREIGN KEY (account) REFERENCES ACCOUNTS(id),
  FOREIGN KEY (category) REFERENCES CATEGORIES(id)
);
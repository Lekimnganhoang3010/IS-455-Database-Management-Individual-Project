-- Create database and switch to it
CREATE DATABASE yelp_analysis;
USE yelp_analysis;

-- USER TABLE --------------------------

CREATE TABLE USER (
    user_id VARCHAR(22) PRIMARY KEY,
    user_name VARCHAR(255),
    review_count INT,
    yelping_since DATETIME,
    friends JSON,
    useful_count INT,
    funny_count INT,
    cool_count INT,
    fan_count INT,
    average_rating DECIMAL(4,2),
    elite_years_count JSON,
    count_compliment_hot INT,
    count_compliment_more INT,
    count_compliment_profile INT,
    count_compliment_cute INT,
    count_compliment_list INT,
    count_compliment_note INT,
    count_compliment_plain INT,
    count_compliment_cool INT,
    count_compliment_funny INT,
    count_compliment_writer INT,
    count_compliment_photos INT
);

-- BUSINESS TABLE ----------------------

CREATE TABLE BUSINESS (
    business_id VARCHAR(22) PRIMARY KEY,
    name VARCHAR(255),
    address VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    postal_code VARCHAR(10),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    average_star_rating DECIMAL(4,2),
    review_count INT,
    categories JSON,
    is_open TINYINT,
    business_options JSON,
    open_close_time JSON
);

-- REVIEW TABLE ------------------------

CREATE TABLE REVIEW (
    review_id VARCHAR(22) PRIMARY KEY,
    user_id VARCHAR(22),
    business_id VARCHAR(22),
    review_rating DECIMAL(4,2),
    review_date DATETIME,
    review_text TEXT,
    useful_count INT,
    funny_count INT,
    cool_count INT,
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (business_id) REFERENCES BUSINESS(business_id)
);

-- TIP TABLE --------------------------------

CREATE TABLE TIP (
    user_id VARCHAR(22),
    business_id VARCHAR(22),
    tip_text TEXT,
    tip_date DATETIME,
    compliment_count INT,
    PRIMARY KEY (user_id, business_id, tip_date),
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (business_id) REFERENCES BUSINESS(business_id)
);

-- CHECKIN TABLE -------------------------------

CREATE TABLE CHECKIN (
    business_id VARCHAR(22) PRIMARY KEY,
    check_in JSON,
    FOREIGN KEY (business_id) REFERENCES BUSINESS(business_id)
);


-- SELECT STATEMENTS ----------------

-- Sample query 1--
SELECT
    r.user_id,
    u.user_name,
    b.name AS business_name,
    COUNT(r.review_id) AS review_count_business_A
FROM review r
JOIN user u ON r.user_id = u.user_id
JOIN business b ON r.business_id = b.business_id
WHERE r.business_id = '_GGgSYM6yN3-2ZVxvp65HA'
GROUP BY r.user_id, u.user_name, b.name
LIMIT 10;


-- Sample query 2 --

SELECT 
    b.business_id, 
    b.name,
    b.categories,
    b.city, 
    COUNT(c.check_in) AS checkin_count
FROM BUSINESS b
LEFT JOIN CHECKIN c
    ON b.business_id = c.business_id
WHERE 
    b.categories = (SELECT categories FROM business WHERE business_id = '_GGgSYM6yN3-2ZVxvp65HA') AND 
    b.city = (SELECT city FROM business WHERE business_id = '_GGgSYM6yN3-2ZVxvp65HA')
GROUP BY b.business_id, b.name, b.categories, b.city
ORDER BY checkin_count DESC
LIMIT 10;


-- Sample query 3 --

SELECT 
    user_id, 
    business_id, 
    tip_text, 
    YEAR(tip_date) AS tip_year_entered, 
    compliment_count
FROM tip
WHERE 
    business_id = (SELECT business_id FROM business WHERE name = 'D\'Angelo\'s Bakery')
    AND YEAR(tip_date) = 2011
ORDER BY compliment_count DESC
LIMIT 10;


-- DATABASE ADMINISTRATION-----------

-- Stored procedure 1 : Storage check (via table size and log growth)

CREATE TABLE IF NOT EXISTS db_table_growth (
    log_time DATETIME,
    table_name VARCHAR(100),
    data_mb DECIMAL(12,2),
    index_mb DECIMAL(12,2)
);

DELIMITER //

CREATE PROCEDURE check_table_usage()
BEGIN
    INSERT INTO db_table_growth
    SELECT
        NOW(),
        table_name,
        data_length/1024/1024 AS data_mb,
        index_length/1024/1024 AS index_mb
    FROM information_schema.tables
    WHERE table_schema = 'yelp_analysis';
END //

DELIMITER ;

-- Sample query for procedure 1
SELECT * FROM db_table_growth ORDER BY log_time DESC;


-- Stored procedure 2: Insertion daily count 

DELIMITER //

CREATE PROCEDURE daily_review_activity()
BEGIN
    SELECT 
        COUNT(*) AS reviews_last_24h
    FROM review
    WHERE review_date >= NOW() - INTERVAL 1 DAY;
END //

DELIMITER ;



-- Stored procedure 3: Automatic MySQL Backup 

DELIMITER //

CREATE PROCEDURE backup_yelp_database()
BEGIN
    -- This uses a system call (MySQL must allow this)
    SELECT
    sys_exec(CONCAT(
        'mysqldump -u root -pYOUR_PASSWORD yelp_analysis > /backup/yelp_analysis_', 
        DATE_FORMAT(NOW(),'%Y%m%d_%H%i'),
        '.sql'
    ));
END //

DELIMITER ;

-- Sample schedule

CREATE EVENT IF NOT EXISTS evt_daily_backup
ON SCHEDULE EVERY 1 DAY
DO CALL backup_yelp_database();



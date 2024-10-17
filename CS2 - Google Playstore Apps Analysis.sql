SELECT 
    *
FROM
    playstore_data;
truncate table playstore_data;

SET GLOBAL local_infile = 'ON';
LOAD DATA INFILE 'D:/SQL practice/google play store/playstore.csv'
INTO TABLE practice.playstore_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT 
    COUNT(*)
FROM
    playstore_data;

DESCRIBE practice.playstore_data;
ALTER TABLE practice.playstore_data MODIFY COLUMN size VARCHAR(255);

SELECT 
    COUNT(*)
FROM
    playstore_data;


SELECT DISTINCT
    (app)
FROM
    playstore_data;

-- 1.You're working as a market analyst for a mobile app development company. Your task is to identify the most promising categories(TOP 5) for 
-- launching new free apps based on their average ratings.
SELECT 
    category, ROUND(AVG(rating), 2) AS 'Average'
FROM
    playstore_data
WHERE
    TYPE = 'FREE'
GROUP BY category
ORDER BY Average DESC
LIMIT 5;

-- 2. As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most revenue from paid apps.
-- This calculation is based on the product of the app price and its number of installations.
SELECT 
    category, ROUND(SUM(price * installs), 2) AS 'Revenue'
FROM
    (SELECT 
        *, (price * installs) AS 'revenue'
    FROM
        playstore_data
    WHERE
        type = 'Paid') t
GROUP BY category
ORDER BY 'revenue' DESC
LIMIT 3;

-- 3. As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category. 
-- This information will help the company understand the distribution of gaming apps across different categories.
SELECT 
    category,
    COUNT(*) AS num_games,
    ROUND((COUNT(*) / (SELECT 
                    COUNT(*)
                FROM
                    playstore_data)) * 100,
            2) AS 'percentage'
FROM
    Playstore_data
GROUP BY category;

-- 4. As a data analyst at a mobile app-focused market research firm, 
-- you'll recommend whether the company should develop paid or free apps for each category based on the  ratings of that category.
WITH free_apps as 
(SELECT category,AVG(rating) as 'Rating_Free' from playstore_data
WHERE type = 'FREE'
GROUP BY category),

paid_apps as 
(SELECT category,AVG(rating) as 'Rating_paid' from playstore_data
WHERE type = 'Paid'
GROUP BY category)

SELECT category, if(Rating_free >Rating_paid ,'Develop FREE app','Develop Paid app') as 'Recommendation'
FROM 
(SELECT f.category,f.Rating_free, p.Rating_paid
FROM Free_apps as f
INNER JOIN paid_apps as p
ON f.category = p.category)k;

-- 5.Suppose you're a database administrator, your databases have been hacked  and hackers are changing price of certain apps on the database , its taking long for IT team to 
-- neutralize the hack , however you as a responsible manager  dont want your data to be changed , do some measure where the changes in price can be recorded as you cant 
-- stop hackers from making changes

CREATE TABLE price_change_log (
    app VARCHAR(255),
    old_price DECIMAL(10 , 2 ),
    new_price DECIMAL(10 , 2 ),
    operation_type VARCHAR(10),
    operation_date TIMESTAMP
);

CREATE TABLE PLAY AS 
SELECT * FROM playstore_data

- for updates 
DROP TRIGGER price_change_update
DELIMITER //
CREATE TRIGGER price_change_update
AFTER UPDATE ON play
FOR EACH ROW
BEGIN 
	INSERT INTO price_change_log(app,old_price,new_price,operation_type,operation_date)
	VALUES(NEW.app,OLD.price,NEW.price,'update', current_timestamp);
END
//

-- before change app status 
SELECT 
    *
FROM
    play
WHERE
    app = 'Infinite Painter';

- changes in db
SET SQL_SAFE_UPDATES = 0;
UPDATE play 
SET 
    price = 4
WHERE
    app = 'Infinite Painter';

-- post update 
SELECT * FROM price_change_log

-- original data
select * from play where app='Sketch - Draw & Paint'

-update
UPDATE play
SET price = 5
WHERE app = 'Sketch - Draw & Paint';

-- post update 
SELECT * FROM price_change_log

-- 6. your IT team have neutralize the threat,  however hacker have made some changes in the prices, but becasue of your measure you have noted the changes , now you want
-- correct data to be inserted into the database.

-- inner join 

DROP TRIGGER price_change_update

UPDATE play as p1 
INNER JOIN price_change_log as p2 ON
p1.app = p2.app
SET p1.price = p2.old_price;

SELECT 
    *
FROM
    play
WHERE
    app = 'Sketch - Draw & Paint';

-- 7. As a data person you are assigned the task to investigate the correlation between two numeric factors: app ratings and the quantity of reviews.
SET @x = (SELECT ROUND(AVG(rating), 2) FROM playstore_data);
SET @y = (SELECT ROUND(AVG(reviews), 2) FROM playstore_data);    

with t as 
(
	select  *, round((rat*rat),2) as 'sqrt_x' , round((rev*rev),2) as 'sqrt_y' from
	(
		select  rating , @x, round((rating- @x),2) as 'rat' , reviews , @y, round((reviews-@y),2) as 'rev'from playstore_data
	)a                                                                                                                        
)
-- select * from  t
select  @numerator := round(sum(rat*rev),2) , @deno_1 := round(sum(sqrt_x),2) , @deno_2:= round(sum(sqrt_y),2) from t ; -- setp 4 
select round((@numerator)/(sqrt(@deno_1*@deno_2)),2) as corr_coeff

-- 8. Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when developing the  recommendor system from the data
-- he/she asssigned you the task to clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank.
select * from playstore_data

DELIMITER //
CREATE FUNCTION f_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
	SET @l = locate(';',a);
    SET @s = IF(@l > 0, LEFT(a,@l-1),a);
    RETURN @s;
END//


SELECT f_name('Art & Design;Pretend Play');

-- function for second genre 
DROP FUNCTION l_name;
DELIMITER //
CREATE FUNCTION l_name(a VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    SET @l = LOCATE(';', a);
    SET @s = IF(@l = 0, '', SUBSTRING(a, @l + 1, LENGTH(a) - @l));
    RETURN @s;
END//
DELIMITER ;


SELECT L_NAME('Art & Design;Pretend Play;Dance');

-- 9. Your senior manager wants to know which apps are  not performing as par in their particular category, however he is not interested in handling too many files or
-- list for every  category and he/she assigned  you with a task of creating a dynamic tool where he/she  can input a category of apps he/she  interested in and 
-- your tool then provides real-time feedback by
-- displaying apps within that category that have ratings lower than the average rating for that specific category.
-- drop if already exists
DROP PROCEDURE checking
DELIMITER //
CREATE PROCEDURE checking(IN cat VARCHAR(30))
BEGIN
	SET @c = (
    SELECT avg_rating FROM 
    (SELECT category, ROUND(AVG(rating),2) AS avg_rating
    FROM playstore_data
    GROUP BY category)m
    WHERE category = cat);
    
SELECT 
    *
FROM
    playstore_data
WHERE
    category = cat AND rating < @c;
END//
DELIMITER ;

CALL checking('Business')




-- APP TRADER PROJECT
-- Your team has been hired by a new company called App Trader to help them explore and gain insights from apps that are made available through the Apple App Store and Android Play Store.   

-- App Trader is a broker that purchases the rights to apps from developers in order to market the apps and offer in-app purchases. The apps' developers retain all money from users purchasing the app from the relevant app store, 
-- and they retain half of the money made from in-app purchases. App Trader will be solely responsible for marketing any apps they purchase the rights to.

-- Unfortunately, the data for Apple App Store apps and the data for Android Play Store apps are located in separate tables with no referential integrity.




-- Assumptions
-- Based on research completed prior to launching App Trader as a company, you can assume the following:

	-- a. App Trader will purchase the rights to apps for 10,000 times the list price of the app on the Apple App Store/Google Play Store, however the minimum price to purchase the rights to an app is $25,000. 
	-- For example, a $3 app would cost $30,000 (10,000 x the price) and a free app would cost $25,000 (The minimum price). NO APP WILL EVER COST LESS THEN $25,000 TO PURCHASE. 1 purchase will grant access to both stores, 
	-- if the price is different between Apple App Store and Google play store choose the higher price.

	-- b. Apps earn $5000 per month, per platform on average from in-app advertising and in-app purchases regardless of the price of the app. This means an app in both stores will earn double monthly.

	-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.

	-- d. An app will earn money monthly during its longevity.  The minimum longevity for an app is 1 year and for every quarter-point that an app gains in rating, its projected lifespan increases by 6 months. 
	-- For example, an app with a rating of 0 would have a longevity of 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years. Ratings should be rounded 
	-- to the nearest 0.25 to evaluate an app's likely longevity.  If the rating differs among stores, use the lower rating.














-- 3. MVP

	-- a. Develop some general recommendations about the price range, genre, content rating, or any other app characteristics that the company should target.



	-- b. Develop a Top 10 List of the apps that App Trader should buy based on profitability/return on investment as the sole priority.



	-- c. Develop a Top 4 list of the apps that App Trader should buy that are profitable but that also are thematically appropriate for the upcoming Fourth of July themed campaign.




	-- d. Submit a report based on your findings. The report should include both of your lists of apps along with your analysis of their cost and potential profits. ALL analysis work must be done using PostgreSQL, 
	-- however you may export query results to create charts in Excel for your report.




	-- e. Prepare a short presentation, up to 5 minutes, to share your findings.  The presentation should be a slideshow which includes charts and/or tables.


SELECT SUM(price):: money, primary_genre AS genre
FROM app_store_apps
WHERE rating > 4.5
GROUP BY genre 
ORDER BY SUM(price) DESC


SELECT COUNT(*), primary_genre
FROM app_store_apps
GROUP BY primary_genre
ORDER BY count(*) DESC


-- Top 3 play_store app genres
-- Events, Education and Art & Design
SELECT DISTINCT category, AVG(rating)
FROM play_store_apps
GROUP BY category
ORDER BY AVG(rating) DESC
LIMIT 3


SELECT *
FROM play_store_apps
WHERE category = 'Events' 
	OR category = 'Education' 
	OR category = 'ART_AND_DESIGN'
	AND rating IS NOT NULL
	AND review_count > 10000
	AND rating > 4.5
	AND type = 'Free'
ORDER BY rating DESC




SELECT DISTINCT(primary_genre)
FROM app_store_apps

-- RECCOMENDED PLAY STORE APPS
-- Art & Design Apps

SELECT name, price:: money, review_count:: numeric, rating, content_rating, primary_genre
FROM app_store_apps
WHERE rating > 4.7
	AND review_count:: numeric > 1000 
ORDER BY rating DESC




--- INFORMATION WE ARE LOOKING FOR
SELECT DISTINCT name, a_store.price:: money AS app_store_price, p_store.price:: money AS play_store_price, a_store.rating AS app_store_rating, p_store.rating AS play_store_rating, 
		a_store.primary_genre AS app_store_genre, p_store.genres AS play_store_genre, ROUND(((a_store.rating + p_store.rating) / 2),2) AS avg_rating
FROM app_store_apps AS a_store
	INNER JOIN play_store_apps AS p_store USING(name)
WHERE a_store.rating > 4.0
AND p_store.rating > 4.0
AND a_store.review_count:: integer > 10000
AND p_store.review_count:: integer > 10000
ORDER BY avg_rating DESC
LIMIT 10








-- 4th of July related apps
SELECT DISTINCT name, a_store.price:: money AS app_store_price, p_store.price:: money AS play_store_price, a_store.rating AS app_store_rating, p_store.rating AS play_store_rating, 
		a_store.primary_genre AS app_store_genre, p_store.genres AS play_store_genre, a_store.content_rating AS app_store_content, p_store.content_rating AS play_store_content, ROUND(((a_store.rating + p_store.rating) / 2),2) AS avg_rating
FROM app_store_apps AS a_store
	INNER JOIN play_store_apps AS p_store USING(name)
WHERE a_store.rating > 4.0
AND p_store.rating > 4.0
AND a_store.review_count:: integer > 10000
AND p_store.review_count:: integer > 10000
AND p_store.content_rating = 'Everyone'
-- AND a_store.primary_genre = 'Food & Drink'
ORDER BY avg_rating DESC





-- FINAL TEAM ANALYSIS --

WITH joined_apps AS(
SELECT DISTINCT LOWER(a.name) AS app_name, REPLACE(a.price::text,'$',''):: numeric AS apple_price,
REPLACE(p.price::text,'$',''):: numeric AS play_price,
ROUND(a.rating/.25)*.25 AS apple_rating,
ROUND(p.rating/.25)*.25 AS play_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p 
ON LOWER(TRIM(a.name))=LOWER(TRIM(p.name))
WHERE a.rating IS NOT NULL )
,
both_apps AS (
SELECT app_name, COUNT(*) AS store_count, GREATEST(MAX(apple_price),MAX(play_price)) AS max_price, LEAST(MIN(apple_rating),MIN(play_rating)) AS min_rating
FROM joined_apps
GROUP BY app_name
),
both_apps_profits AS(
SELECT app_name,
store_count,
max_price,
min_rating,
---PURCHASE COST... x$10,000 for max_price but x25,000 for free
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END as purchase_price,
5000*store_count AS monthly_profit,
1000 AS marketing_cost,
---store count * app's life span in months
---Total Profit= monthly profit over app's lifespan - purchase cost- total marketing cost
(5000*2-1000) * (12+((min_rating/.25)*6)) -
---PURCHASE COST---
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END AS total_profit

FROM both_apps
)
SELECT *
FROM both_apps_profits
ORDER BY total_profit DESC









WITH joined_apps AS(
SELECT DISTINCT LOWER(a.name) AS app_name,a.primary_genre AS genre,a.content_rating AS content_rating, REPLACE(a.price::text,'$',''):: numeric AS apple_price,
REPLACE(p.price::text,'$',''):: numeric AS play_price,
ROUND(a.rating/.25)*.25 AS apple_rating,
ROUND(p.rating/.25)*.25 AS play_rating
FROM app_store_apps AS a
INNER JOIN play_store_apps AS p 
ON LOWER(TRIM(a.name))=LOWER(TRIM(p.name))
WHERE a.rating IS NOT NULL )
,
both_apps AS (
SELECT app_name, genre,content_rating,
CASE
WHEN MAX(apple_price)>MAX(play_price) THEN MAX(apple_price)
ELSE MAX(play_price)
END AS max_price,
CASE 
WHEN MIN(apple_rating) < MIN (play_rating) THEN MIN(apple_rating)
ELSE MIN(play_rating)
END AS min_rating
FROM joined_apps
GROUP BY app_name,genre,content_rating
),
both_apps_profits AS(
SELECT app_name,genre,content_rating,
max_price,
min_rating,
---PURCHASE COST... x$10,000 for max_price but x25,000 for free
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END as purchase_price,
5000*2 AS monthly_profit,
1000 AS marketing_cost,
---store count * app's life span in months
---Total Profit= monthly profit over app's lifespan - purchase cost- total marketing cost
(5000*2-1000) * (12+((min_rating/.25)*6)) -
---PURCHASE COST---
CASE
	WHEN max_price *10000 <25000 THEN 25000
	ELSE max_price *10000
END AS total_profit

FROM both_apps
)
SELECT *
FROM both_apps_profits
ORDER BY total_profit DESC
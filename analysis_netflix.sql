-- Data analysis in Netflix data.

DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

SELECT * FROM netflix;

-- 1. Count the number of Movies vs TV Shows
SELECT type, COUNT(*)
FROM netflix
GROUP BY 1;

-- 2. Find the most common rating for movies and TV shows
WITH rankings AS (SELECT type, 
	   rating, 
	   COUNT(*) AS rating_count,
	   RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS rank
FROM netflix
GROUP BY 1,2)
SELECT * 
FROM rankings
WHERE rank = 1;

-- 3. List all movies released in a specific year (e.g., 2020)
SELECT *
FROM netflix
WHERE release_year = 2020 AND type = 'Movie';

-- 4. Find the top 5 countries with the most content on Netflix
SELECT c.country, COUNT(*) AS total_content
FROM netflix n
CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(n.country, ',')) AS c(country)
WHERE c.country IS NOT NULL
GROUP BY c.country
ORDER BY total_content DESC
LIMIT 5;

-- 5. Identify the longest movie
SELECT title, SPLIT_PART(duration, ' ', 1)::INT AS duration  
FROM netflix
WHERE type = 'Movie' AND SPLIT_PART(duration, ' ', 1)::INT IS NOT NULL
ORDER BY SPLIT_PART(duration, ' ', 1)::INT DESC
LIMIT 1;

-- 6. Find content added in the last 5 years
SELECT * 
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years'
ORDER BY TO_DATE(date_added, 'Month DD, YYYY') DESC;

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT title, director
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';

--ALTERNATIVE
SELECT DISTINCT title, director
FROM (
    SELECT 
        *,
        UNNEST(STRING_TO_ARRAY(director, ',')) AS director_name
    FROM netflix
) AS t
WHERE director_name = 'Rajiv Chilaka';

-- 8. List all TV shows with more than 5 seasons
SELECT title, 
		SPLIT_PART(duration, ' ', 1)::INT AS season_number
FROM netflix
WHERE type = 'TV Show' AND SPLIT_PART(duration, ' ', 1)::INT > 5
ORDER BY 2 DESC;

-- 9. Count the number of content items in each genre
SELECT genre, COUNT(*)
FROM
(SELECT *, 
		UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS genre
FROM netflix)
GROUP BY genre
ORDER BY 2 DESC;

-- 10.Find each year and the average numbers of content release in India on netflix. 
-- return top 5 year with highest avg content release!
SELECT 
    country,
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        COUNT(show_id)::numeric /
        (SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100, 2
    ) AS avg_release
FROM netflix
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY avg_release DESC
LIMIT 5;

-- 11. List all movies that are documentaries
SELECT type, title, listed_in AS genre
FROM netflix
WHERE type = 'Movie' AND listed_in LIKE '%Documentaries%';

-- 12. Find all content without a director
SELECT * FROM netflix
WHERE director IS NULL;

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT title, release_year
FROM netflix
WHERE casts LIKE '%Salman Khan%' AND
			release_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT 
		UNNEST(STRING_TO_ARRAY(casts, ',')) AS actors,
		COUNT(show_id) AS number_movies
FROM netflix
WHERE country LIKE '%India%' 
		AND type = 'Movie'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

WITH horror_categorization AS (SELECT *,
		CASE 
			WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE 'violence' THEN 'bad'
			ELSE 'good'
			END AS category
FROM netflix)
SELECT category, COUNT(*)
FROM horror_categorization
GROUP BY category;


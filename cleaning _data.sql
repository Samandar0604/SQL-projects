-- cleaning data

select * 
from layoffs;

-- 1. remove dupicates 
-- 2. standardize data
-- 3. Null values or blank vlaues
-- 4. Remove any columns 

create table layoff_staging
like layoffs;

-- create copy table
select * 
from layoff_staging; 
-- populate the copy data using the data of the real data
insert layoff_staging
select * from layoffs;
-- label the duplicates of the rows using the most important columns
select *,
row_number() over(partition by company, industry, total_laid_off, percentage_laid_off, `date`) as row_num
from layoff_staging; 
-- find the duplicates
with dup_cte as
(
select *,
row_number() over(partition by company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoff_staging 
)
select * 
from dup_cte 
where row_num > 1;
-- show the duplicate rows for specific company
select *
from layoff_staging
where company = 'Cazoo';

-- create another the new table
CREATE TABLE `layoff_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  row_num INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


select * 
from layoff_staging2;

-- populate the new table with the data of the previous copy of data, while adding new columns to show the duplicates
insert into layoff_staging2
select *,
row_number() over(partition by company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoff_staging;

-- delete the duplicates
delete 
from layoff_staging2
where row_num > 1; 

select * 
from layoff_staging2
where row_num > 1;

-- Standardizing data
-- check the company column has extra spaces in the data
select company, trim(company)
from layoff_staging2;
-- remove the spaces
update layoff_staging2 
set company = trim(company);

select distinct country, trim(trailing '.' from country)
from layoff_staging2
order by country;

-- find the similar industries or countries but with different words
select distinct(industry)
from layoff_staging2
order by 1;
 
select *
from layoff_staging2
where industry like '%crypto%';

update layoff_staging2
set industry = 'Crypto'
where industry like '%crypto%';

update layoff_staging2
set country = 'United States'
where country like 'United States%';

-- change the type of the date column from string to date type
select `date`
from layoff_staging2;

update layoff_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');

-- give the right format for the column
alter table layoff_staging2
modify column `date` date;

select *
from layoff_staging2
where total_laid_off is NULL
and percentage_laid_off is null;

select *
from layoff_staging2
where industry is null
or industry = '';

select *
from layoff_staging2
where company = 'Airbnb';

select t1.industry, t2.industry
from layoff_staging2 t1
join layoff_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoff_staging2
set industry = NUll
where industry = '';


update layoff_staging2 t1
join layoff_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry 
where t1.industry is null 
and t2.industry is not null;

select *
from layoff_staging2
where total_laid_off is NULL
and percentage_laid_off is null;


delete
from layoff_staging2
where total_laid_off is NULL
and percentage_laid_off is null;

alter table layoff_staging2
drop column row_num;
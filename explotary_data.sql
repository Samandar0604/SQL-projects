-- Exploratory Data analysis

select *
from layoff_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoff_staging2;

select *
from layoff_staging2
where percentage_laid_off = 1
order by total_laid_off desc;

select company, sum(total_laid_off)
from layoff_staging2
group by company
order by 2 desc;


select min(`date`), max(`date`)
from layoff_staging2;

select year(`date`), sum(total_laid_off)
from layoff_staging2
group by year(`date`)
order by 1 desc;

select substring(`date`, 1, 7) as `Month`, sum(total_laid_off) 
from layoff_staging2
where substring(`date`, 1, 7) is not null
group by `Month`
order by 1;


with total_rolling as
(
select substring(`date`, 1, 7) as `Month`, sum(total_laid_off) as total_off 
from layoff_staging2
where substring(`date`, 1, 7) is not null
group by `Month`
order by 1
)
select `Month`, total_off, sum(total_off) over(order by `Month`) as rolling_total
from total_rolling;

select company, year(`date`), sum(total_laid_off)
from layoff_staging2
where year(`date`) is not null
group by company, year(`date`)
order by 1 asc;

with company_year(company, years, total_laid_off) as
(
select company, year(`date`), sum(total_laid_off)
from layoff_staging2
group by company, year(`date`)
), company_year_rank as
(select *, dense_rank() over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null)
select * 
from company_year_rank
where ranking <= 5;

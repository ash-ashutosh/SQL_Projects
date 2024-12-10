use company

-- renaming the table name after data import
--EXEC sp_rename 'credit_card_transcations', 'credit_card_transactions'

-- View the dataset 
select * from credit_card_transactions

-- Generic queries to explore the data set and findings. 
-- Scroll below to view business question
-- 1. Transactions by Expense Type
select exp_type, sum(amount) total_amount, count(*) as total_transactions
from credit_card_transactions
group by exp_type

-- 2. Monthly Trend of Transactions
select DATEPART(YEAR, transaction_date) as current_year, DATEPART(month, transaction_date) as current_month, count(*) as total_transaction
from credit_card_transactions
group by DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date)
order by DATEPART(YEAR, transaction_date), DATEPART(MONTH, transaction_date)

select Format(transaction_date,'yyyy-MM') as year_month, count(*) as total_transaction
from credit_card_transactions
group by Format(transaction_date,'yyyy-MM')
order by year_month











-- IMPORTANT BUSINESS PROBLEM QUESTION ON CREDIT CARD DATASET. 

-- Identify cities with the highest credit card spending to focus on promotions or tailored campaigns.
-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with city_amount as (
	select city, sum(amount) as city_total_amount
	from credit_card_transactions
	group by city ),
total_spent as (
	select sum(cast (amount as bigint)) as total_credit_cardspent
	from credit_card_transactions)
select TOP 5 *, ROUND((city_total_amount*1.0/total_credit_cardspent)*100,2) as contribution
from city_amount
inner join total_spent
on 1=1
order by contribution desc



--Ensure the business is prepared for higher transaction volumes during those months.
-- 2- write a query to print highest spend month and amount spent in that month for each card type

with card_month_spent as ( 
	select card_type, FORMAT(transaction_date,'yyyy-MM') as year_month, sum(amount) as month_spent
	from credit_card_transactions
	group by card_type, FORMAT(transaction_date,'yyyy-MM')),
	--order by card_type,month_spent),
highest_spent as (
	select *,
	rank() over (partition by card_type order by month_spent desc) as rnk
	from card_month_spent )
select card_type, year_month, month_spent
from highest_spent
where rnk = 1



--Designing card-specific offers or rewards for customers nearing or exceeding high spend thresholds
--3- write a query to print the transaction details(all columns from the table) for each 
--   card type when it reaches a cumulative of 1000000 total spends or immidiate less
--   (We should have 4 rows in the o/p one for each card type)
with roll_sum as (
	SELECT *,
	sum(amount) over (partition by card_type order by transaction_date, transaction_id) as rolling_sum
	from credit_card_transactions ),
ranking as (select *,
	rank() over (partition by card_type order by rolling_sum) as rnk
	from roll_sum 
	where rolling_sum < 1000000),
max_rank as (
	select card_type, max(rnk) as mx_rnk
	from ranking
	group by card_type)
select r.*
from ranking r
inner join max_rank r1
on r1.card_type = r.card_type AND  r1.mx_rnk = r.rnk 



--Tweaking the Gold card features or offers to better appeal to customers in low-spend regions.
--4- write a query to find city which had lowest percentage spend for gold card type
--LETS CONNECT TO DISCUSS MORE OF SQL PROBLEM!! SOLVE THIS QUESTION AND SEND ME SOLUTION



--Enabling marketers to focus on cities with high spending in particular categories for personalized offers, while identifying low-performing categories that might need promotions or different strategies
--5- write a query to print 3 columns
--  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with city_total_amount as ( 
	select city, exp_type, sum(amount) as total_exp_amount
	from credit_card_transactions
	group by city, exp_type ),
ranking as (
	select *,
	rank() over (partition by city order by total_exp_amount desc) as rn_highest,
	rank() over (partition by city order by total_exp_amount asc) as rn_lowest
	from city_total_amount)
select city,
MAX(case when rn_lowest = 1 then exp_type end) as lowest_expense_type,
MAX(case when rn_highest = 1 then exp_type end) as highest_expense_type
from ranking
group by city 



--Understanding which expense categories are more popular among female cardholders, enabling the design of targeted campaigns or offers for females in those categories.
--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type, sum(amount) as exp_total_amount,
SUM(case when gender = 'F' then amount end) as female_contribution,
(SUM(case when gender = 'F' then amount end)*1.0)*100 / sum(amount) as percentage_of_female
from credit_card_transactions
group by exp_type
order by percentage_of_female desc



-Helping predict future growth areas and enabling better inventory or service planning based on categories with accelerating demand
--7- which card and expense type combination saw highest month over month growth in Jan-2014

with combination as ( 
	select card_type, exp_type, sum(amount) as total_amount,
	Format(transaction_date, 'yyyy-MM') as year_month
	from credit_card_transactions
	group by card_type, exp_type,Format(transaction_date, 'yyyy-MM')),
previous_month_amount as (
	select *,
	lag(total_amount) over (partition by card_type,exp_type order by year_month ) as previous_month
	from combination)
select TOP 1 *, (total_amount - previous_month ) as mom_growth
from previous_month_amount
where year_month = '2014-01'
order by mom_growth desc



--Understanding spending patterns during weekends, which could help in refining loyalty programs or reward offers for customers in these cities.
--8- during weekends which city has highest total spend to total no of transcations ratio 

with weekends as (select *
	from credit_card_transactions
	where Datepart(weekday,FORMAT(transaction_date, 'yyyy-MM-dd')) = 7
OR
	Datepart(weekday,FORMAT(transaction_date, 'yyyy-MM-dd')) = 1 ) 
select city, sum(amount) as total_spend, count(*) as total_transaction, sum(amount)*1.0/count(*) as ratio 
from weekends
group by city 
order by ratio desc



--Determining which city has the fastest adoption rate for credit card transactions, indicating high market penetration or demand
-- 9- which city took least number of days to reach its 500th transaction after 
--    the first transaction in that city

with r_number as (select *,
	ROW_NUMBER() over (partition by city order by transaction_date) as rn 
	from credit_card_transactions),
final_date as ( 
	select city, Min(transaction_date) as first_transaction, 
	MAX(case when rn = 500 then transaction_date end ) as final_transaction
	from r_number
	where rn <= 501   
	group by city
	having count(*) > 500 )
select *,
DATEDIFF(day,first_transaction, final_transaction) as total_days
from final_date
order by total_days asc


use company

-- view orders data set 
select * from Orders;
SELECT DISTINCT(order_id) 
from Orders;

-- view return data set 
select * from returns;
select distinct(return_reason)
from returns



-- IMPORTANT BUSINESS PROBLEM QUESTION BASED ON SUPER STORE DATASET 
--How many return orders were made in each region?
--1 - write a query to get region wise count of return orders

select o.region, count(r.order_id) as total_return
from Orders as o
inner join returns as r
on o.order_id = r.order_id
group by region
order by total_return;


--What are the sales figures for each category excluding returned orders
--2 - write a query to get category wise sales of orders that were not returned

select o.category, sum(o.sales) as total_sale
from Orders as o
left join returns as r
on o.order_id = r.order_id
where r.order_id is null
group by category;


--Which subcategories experience all three types of returns (others, bad quality, wrong items)?
--3 - write a query to print sub categories where we have all 3 kinds of returns (others,bad quality,wrong items)

select o.sub_category
from Orders as o
inner join returns as r
on o.order_id = r.order_id
group by sub_category
having count(distinct r.return_reason) = 3;


--Which cities have a perfect record with no order returns?
--4 - write a query to find cities where not even a single order was returned.

select o.city
from Orders as o
left join returns as r
on o.order_id = r.order_id
group by city
having count (r.order_id) = 0;


--What are the top 3 subcategories by sales value for returned orders in the East region?
--5 - write a query to find top 3 subcategories by sales of returned orders in east region

select o.sub_category, sum(o.sales) as total_sales
from Orders as o
inner join returns as r
on o.order_id = r.order_id
where region = 'east'
group by sub_category
order by total_sales desc;


--Which subcategories have never had any return orders in November, regardless of the year?
--This helps identify consistently well-performing subcategories during November.
--6 - write a query to find subcategories who never had any return orders in the month of november (irrespective of years)

select sub_category
from orders o
left join returns r 
on o.order_id=r.order_id
where DATEPART(month,order_date)=11
group by sub_category
having count(r.order_id)=0;


--Which orders consist of only a single product purchased by the customer?
--This helps analyze customer behavior for smaller or single-item purchases.
--7 - orders table can have multiple rows for a particular order_id when customers buys more than 1 product in an order.
--write a query to find order ids where there is only 1 product bought by the customer.

select order_id
from orders 
group by order_id
having count(1)=1;


--What are the total sales for each category in 2019 and 2020?
--This helps compare category performance across the two years and identify trends or shifts in demand.
--8 - write a query to print below 3 columns
--category, total_sales_2019(sales in year 2019), total_sales_2020(sales in year 2020)

select category,
sum(case when datepart(year,order_date)=2019 then sales end) as total_sales_2019,
sum(case when datepart(year,order_date)=2020 then sales end) as total_sales_2020
from orders 
group by category;


--Which are the top 5 cities in the West region with the highest average shipping delays (measured by the number of days between order date and ship date)?
--This helps identify cities with potential shipping inefficiencies.
--9 - write a query print top 5 cities in west region by average no of days between order date and ship date.

select top 5 city, avg(datediff(day,order_date,ship_date) ) as avg_days
from orders
where region='West'
group by city
order by avg_days desc;


--Which customers have placed more orders than the average customer?
-This helps identify and target high-value, loyal customers for premium offers or special treatment.
--10 - write a query to find premium customers from orders data. Premium customers are those who have done more orders than average no of orders per customer.

with num_of_order_per_customer as 
(select customer_id, count(distinct order_id) as total_order
from Orders
group by customer_id)
select * 
from num_of_order_per_customer
where total_order > (select AVG(total_order) as avg_order
from num_of_order_per_customer);


--What are the highest-selling products (by units sold) in each category, and their total sales?
--This helps identify top-performing products in each category for inventory and marketing focus.
--11 - write a query to print product id and total sales of highest selling products (by no of units sold) in each category

with product_quantity as (
select category,product_id,sum(quantity) as total_quantity
from orders 
group by category,product_id),
cat_max_quantity as (
select category,max(total_quantity) as max_quantity 
from product_quantity 
group by category
)
select *
from product_quantity pq
inner join cat_max_quantity cmq 
on pq.category=cmq.category
where pq.total_quantity  = cmq.max_quantity;


--Which are the top 3 and bottom 3 products by sales in each region?
--This helps evaluate product performance across regions, highlighting opportunities for improvement or promotion.
--12 - write a query to find top 3 and bottom 3 products by sales in each region.

with selected as (
select product_id, region, sum(sales) as total_sales
from Orders
group by product_id, region
),
ranking as (
select *,
rank() over (partition by region order by total_sales desc) as ranks_desc,
rank() over (partition by region order by total_sales asc) as ranks_asc
from selected
)
select product_id, region, total_sales,
case 
	when ranks_desc <= 3 then 'Top 3'
	else 'Bottom 3'
	end as Top_bottom
from ranking
where ranks_desc <=3 OR ranks_asc <=3;


--Which subcategory experienced the highest month-over-month sales growth in January 2020?
--This helps identify rapidly growing subcategories for potential scaling or increased marketing focus.
--13 - Among all the sub categories..which sub category had highest month over month growth by sales in Jan 2020.

with selected as (
select sub_category ,datepart(YEAR, order_date) as yrs, DATEPART(MONTH,order_date) as mnth,  sum(sales) as total_sale
from Orders
group by sub_category ,datepart(YEAR, order_date), DATEPART(MONTH,order_date) 
--order by datepart(YEAR, order_date), DATEPART(MONTH,order_date)
),
growth as (
select *,
lag(total_sale) over (partition by sub_category order by yrs, mnth) as previous_sales
from selected)
select sub_category, yrs, mnth, total_sale,previous_sales, (total_sale-previous_sales)/previous_sales as mom_growth
from growth
where yrs = '2020' AND mnth = '1'
order by mom_growth desc;


--Which are the top 3 products in each category with the highest year-over-year sales growth in 2020?
--This helps highlight products with strong growth, guiding inventory and promotional strategies.
--14 - write a query to print top 3 products in each category by year over year sales growth in year 2020.

with selected as (
select product_id, category, DATEPART(year,order_date) as yr, sum(sales) as total_sale 
from Orders
group by product_id, category, DATEPART(year,order_date) 
),
growth as (
select *,
lag(total_sale) over (partition by product_id order by yr) as pys
from selected ),
yr_growth as (
select * , (total_sale-pys)/pys as year_growth
from growth ),
final as (
select *,
DENSE_RANK() over (partition by category order by year_growth desc) as rnk
from yr_growth
where yr = '2020')
select * 
from final
where rnk <=3;


--Which are the top 3 products in each category based on the highest rolling 3-month total sales for January 2020?
--This helps identify high-performing products over a recent period, aiding in inventory planning and sales strategy.
--15 - write a sql to find top 3 products in each category by highest rolling 3 months total sales for Jan 2020.

with selected as (
select *,
sum(total_sale) over (partition by category,product_id order by yr,mnth rows between 2 preceding and current row ) as rolling_sum
from (select product_id, category, datepart(YEAR, order_date) as yr, datepart(month, order_date) as mnth, sum(sales) as total_sale
from Orders
group by product_id, category, datepart(YEAR, order_date), datepart(month, order_date)) as r),
rnking as (select *,
DENSE_RANK() over (partition by category order by rolling_sum desc) as rnk
from selected
where yr = '2020' AND mnth = '01')
select *
from rnking
where rnk <=3;


--Which products have shown consistent month-over-month sales growth, with no declines?
--This helps identify reliable products with stable demand, useful for forecasting and inventory management.
--16 - write a query to find products for which month over month sales has never declined.
with mom as (
select *,
lag(total_sales,1,0) over (partition by product_id order by yr,mnth) as pre_month_sale
from ( select product_id, DATEPART(year, order_date) as yr, DATEPART(MONTH, order_date) as mnth, sum(sales) as total_sales
from Orders
group by product_id, DATEPART(year, order_date), DATEPART(MONTH, order_date)) as seleced)
select distinct product_id
from mom 
where product_id NOT IN (select product_id
from mom 
where total_sales < pre_month_sale 
group by product_id);


--Which months show sales for each category that exceed the combined sales of the previous two months?
--This helps identify months with exceptional performance, possibly indicating successful promotions or demand spikes.
--17 - write a query to find month wise sales for each category for months where sales is more than the combined sales of previous 2 months for that category.

with combined as (select *,
sum(total_sale) over(partition by category order by yr,mnth rows between 2 preceding AND 1 preceding) as combined_month
from (select category, 
DATEPART(year, order_date) as yr, 
DATEPART(month, order_date) as mnth, sum(sales) as total_sale
from Orders
group by category, DATEPART(year, order_date), DATEPART(month, order_date)) as a)
select *
from combined
where total_sale > combined_month;


--How many business days (excluding weekends) are there between the order date and ship date?
--This helps measure shipping efficiency by calculating the exact time taken for order processing and delivery.
--18 - write a query to get number of business days between order_date and ship_date (exclude weekends). 
--Assume that all order date and ship date are on weekdays only

select order_id,order_date,ship_date ,
datediff(day,order_date,ship_date)-2*datediff(week,order_date,ship_date) as no_of_business_days
from 
orders;


--What are the total sales and total sales of returned orders for each category?
--This helps assess the financial impact of returns on each product category, aiding in inventory and quality control decisions.
--19 - write a query to print 3 columns : category, total_sales and (total sales of returned orders)

select o.category,sum(o.sales) as total_sales,
sum(case when r.order_id is not null then sales end) as return_orders_sales
from orders o
left join returns r on o.order_id=r.order_id
group by category;


/* Request-1
 The list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
 */ 

SELECT distinct market
FROM dim_customer 
where region = "APAC" and customer="Atliq Exclusive";

/* Request-2
 The percentage of unique product_code increase from 2021 vs 2020 
 */
 with cte1 as
 (select count(distinct(product_code)) as Unique_products_2020
 from fact_sales_monthly f
 where fiscal_year=2020),
 
 cte2 as  
 (select count(distinct(product_code)) as Unique_products_2021
 from fact_sales_monthly f
 where fiscal_year=2021)
 
 select *, round((unique_products_2021-Unique_products_2020)*100/unique_products_2021,2) as pct_change
 from cte1 
 cross join cte2;
 
 /* Request-3
 Provide a report with all the unique product counts for each segment and sort them in 
 descending order of product counts. 
 */
 
 select segment,count(Distinct(product_code)) as Product_count
 from dim_product
 group by segment
 order by product_count desc;
 
 /* Request-4
 follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference
 */
 
 with cte1  as 
 ( select p.segment, count(distinct(f.product_code)) as product_count_2020
 from fact_sales_monthly f
 join dim_product p
 on f.product_code=p.product_code
 where fiscal_year=2020
 group by segment 
 order by product_count_2020 desc),
 cte2 as 
  ( select p.segment, count(distinct(f.product_code)) as product_count_2021
 from fact_sales_monthly f
 join dim_product p
 on f.product_code=p.product_code
 where fiscal_year=2021
 group by segment 
 order by product_count_2021 desc)
 select segment,product_count_2020,product_count_2021,
round(product_count_2021-product_count_2020) as difference
from cte1
join cte2
using(segment)
order by Difference desc;

/* Request-5
Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost
*/

select 
     p.product_code,
     p.product,
     m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
using(product_code)
where manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost) or
	   manufacturing_cost=(select min(manufacturing_cost)from fact_manufacturing_cost)
order by manufacturing_cost;

/* Report-6
 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct
 for the fiscal year 2021 and in the Indian market. 
-- The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage
*/

select d.customer_code,
	   c.customer,
       concat(round(avg(d.pre_invoice_discount_pct)*100,2),"%") as Avg_discount_Percentage
       from dim_customer c
       join fact_pre_invoice_deductions d 
       using(customer_code)
       where fiscal_year=2021 and market="India"
       group by customer_code
       order by AVG(pre_invoice_discount_pct) desc
       limit 5;


/* Report-7
 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount
*/

Select 
      monthname(s.date) as Month_name,year(s.date)as year,
	  round(sum(g.gross_price * s.sold_quantity)/1000000,1) as gross_sales_amount_million
      from fact_sales_monthly s
      join fact_gross_price g
      using(product_code)
      join dim_customer c
      using(customer_code)
      where c.customer="Atliq Exclusive"
      group by month_name,year
      order by year;

/* Request-8
In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity,
-- Quarter 
-- total_sold_quantity
*/

with cte as (
select *,
case 
     when month(s.date) in (9,10,11) then "Q1"
     when month(s.date) in (12,1,2) then "Q2"
     when month(s.date) in (3,4,5) then "Q3"
     else "Q4"
end as Quarters
from fact_sales_monthly s
where fiscal_year=2020
)
select monthname(date) as month_name,Quarters,
round(sum(sold_quantity),2) as Total_sold_quantity
from cte
group by quarters
order by  Total_sold_quantity desc;

/*Request-9
Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
-- The final output contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage
*/

with cte as (
select c.channel,sum(g.gross_price*s.sold_quantity) as total_sales
from fact_sales_monthly s
join fact_gross_price g
using(product_code)
join dim_customer c
using(customer_code)
where s.fiscal_year=2021
group by c.channel
order by total_sales desc)

select 
      channel,
      concat(round(total_sales/1000000,2),'M') as gross_sales__mln,
      concat(round(total_sales/(sum(total_sales) over())*100,2),'%') as percentage
      from cte;

/* Request 10
 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these fields, 
-- division 
-- product_code
*/

with cte1 as 
(
   select
       p.division as division,
       p.product_code as product_code,
       p.product as product,
       p.variant as variant,
       sum(s.sold_quantity) as Total_sold_quantity
from fact_sales_monthly s
join dim_product p
using(product_code)
where fiscal_year=2021
group by p.division,p.product_code,p.product
order by Total_sold_quantity DESC),

cte2 as (
select division,product_code,product,total_sold_quantity,variant,
        dense_rank() over(partition by division order by total_sold_quantity desc)
        as rank_order 
from cte1)
select *from cte2
where rank_order<=3;

--Meesho’s Order Analytics Using SQL--

select * from meesho_data;


--Data Cleaning Process

--1.Determining Duplicate Data 
select count(*) 
from meesho_data 
having count(*)>1;
--2.Renaming coloumn name
alter table meesho_data
rename column supplier_listed_price to Price;
--3.Removing unused column
alter table meesho_data
drop column sizes;
alter table meesho_data
drop column supplier_discounted_price;



-- Overall Trend and KPI Reporting

select
    count(order_no) as total_orders,

    -- Delivered Orders
    sum(case when regexp_like(lower(reason_for_credit_entry), 'delivered') then 1 else 0 end) as delivered_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'delivered') then 1 else 0 end) * 100.0 / count(order_no), 2) as delivered_order_ptg,

    -- Cancelled Orders
    sum(case when regexp_like(lower(reason_for_credit_entry), 'cancelled') then 1 else 0 end) as cancelled_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'cancelled') then 1 else 0 end) * 100.0 / count(order_no), 2) as cancelled_order_ptg,

    -- RTO Orders
    sum(case when regexp_like(lower(reason_for_credit_entry), 'rto') then 1 else 0 end) as rto_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'rto') then 1 else 0 end) * 100.0 / count(order_no), 2) as rto_order_ptg,

    -- Pending Orders
    sum(case when regexp_like(lower(reason_for_credit_entry), 'pending') then 1 else 0 end) as pending_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'pending') then 1 else 0 end) * 100.0 / count(order_no), 2) as pending_order_ptg,

    -- Ready to Ship
    sum(case when regexp_like(lower(reason_for_credit_entry), 'ready_to_ship') then 1 else 0 end) as ready_to_ship_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'ready_to_ship') then 1 else 0 end) * 100.0 / count(order_no), 2) as ready_to_ship_ptg,

    -- Shipped Orders
    sum(case when regexp_like(lower(reason_for_credit_entry), 'shipped') then 1 else 0 end) as shipped_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'shipped') then 1 else 0 end) * 100.0 / count(order_no), 2) as shipped_order_ptg,
from meesho_data;
-- Trend and KPI Reporting Monthly
select
    trunc(order_date, 'MM') as month_start,
    count(order_no) as total_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'delivered') then 1 else 0 end) * 100.0 / count(order_no), 2) as delivered_order_ptg,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'cancelled') then 1 else 0 end) * 100.0 / count(order_no), 2) as cancelled_order_ptg,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'rto') then 1 else 0 end) * 100.0 / count(order_no), 2) as rto_order_ptg,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'pending') then 1 else 0 end) * 100.0 / count(order_no), 2) as pending_order_ptg,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'ready_to_ship') then 1 else 0 end) * 100.0 / count(order_no), 2) as ready_to_ship_ptg,
    round(sum(case when regexp_like(lower(reason_for_credit_entry), 'shipped') then 1 else 0 end) * 100.0 / count(order_no), 2) as shipped_order_ptg
from meesho_data
group by trunc(order_date, 'MM')
order by month_start;

--RTO Analysis (Return to Origin)--Overall, by State, and by Product
--1.Return to Origin(RTO) Rate
with rto_flag as (
    select order_no,customer_state,product_name,
        case when regexp_like(reason_for_credit_entry, 'RTO') then 1 else 0 end as is_rto
    from meesho_data
)
select *
from (
    select 'Overall' as category, 'All' as category_value,
           count(order_no) as Total_orders,
           sum(is_rto) as RTO_Count,
           round(sum(is_rto)*100.0/count(*),2) as RTO_rate
    from rto_flag
    union all
    select 'State', customer_state,count(order_no),sum(is_rto),
           round(sum(is_rto)*100.0/count(*),2)
    from rto_flag
    group by customer_state
    union all
    select 'Product', product_name,count(order_no),sum(is_rto),
    round(sum(is_rto)*100.0/count(*),2)
    from rto_flag
    group by product_name
) t
order by category, RTO_rate desc;

--Delivery and Canvellation performance Analysis--

--1.Cancellations by State and Product
select customer_state,
    product_name,
    count(*) as cancelled_Orders
from meesho_data
where regexp_like (reason_for_credit_entry, 'CANCELLED')
group by customer_state,
    product_name
order by cancelled_Orders desc;

--2.SKU Performance Analysis

select * 
from (select sku, product_name,
    count(*) as total_orders,
    sum(case when regexp_like(lower(reason_for_credit_entry),'delivered') 
    then 1 else 0 end) as delivered_orders,
    sum(case when regexp_like(lower(reason_for_credit_entry),'rto') 
    then 1 else 0 end) as rto_orders,
    sum(case when regexp_like(lower(reason_for_credit_entry),'cancelled') 
    then 1 else 0 end) as cancelled_orders,
    round(sum(case when regexp_like(lower(reason_for_credit_entry),'delivered') 
    then 1 else 0 end)*100.0/count(*),2) as fulfillment_rate,
    round(sum(case when regexp_like(reason_for_credit_entry,'RTO|CANCELLED') 
    then 1 else 0 end)*100.0/count(*),2) as failure_rate
from meesho_data
group by sku, product_name
order by fulfillment_rate asc)
where rownum<=10;


--State based Performance--

--1. Top Perfoming State

select *
from
(select
    customer_state,
    sum(quantity) as Total_Quantity
from meesho_data
group by customer_state
order by Total_Quantity desc
)
where rownum<=5;
t
--2. Least Perfoming State

select *
from
(select
    customer_state,
    sum(quantity) as Total_Quantity
from meesho_data
group by customer_state
order by Total_Quantity asc
)
where rownum<=5;

--3.No of orders placed in each state in the last 30 days

select
    customer_state,
    count(order_no) as order_count
from meesho_data
where order_date>=trunc(sysdate)-30
group by customer_state
order by order_count desc;
    

--Product Based Performance

--1 Top 3 selling products each day for last week

select *
from (
    select
        order_date,
        product_name,
        sum(quantity * price) as daily_sales,
        rank() over (partition by order_date 
        order by sum(quantity * price) desc) as rnk
    from meesho_data
    where order_date>=trunc(sysdate)-7
    group by order_date, product_name
) day_sales_rank
where rnk <= 3;


--Customer's orders Segmentation by revenue

with orders as (
    select 
        order_no,
        sum(quantity * price) as revenue
    from meesho_data
    group by order_no
),
aov as (
    select avg(revenue) as aov
    from orders
),
segmented as(select
    o.order_no,
    o.revenue,
    case
        when o.revenue > a.aov then 'Gold'
        else 'Silver'
    end as customer_segmentation
from orders o
cross join aov a)
select
    customer_segmentation,
    sum(revenue) as total_revenue,
    count(order_no) as total_orders
from segmented
group by customer_segmentation;



--Stored Procedure

--1.Top 10 Most Recent Cancelled Orders in Meesho
create or replace procedure sp_recent_cancel_orders_rc (
    p_cursor out sys_refcursor
) as
begin
    open p_cursor for
        select *
        from (
            select order_no,
                   customer_state,
                   product_name,
                   order_date
            from meesho_data
            where regexp_like(lower(reason_for_credit_entry), 'cancelled')
            order by order_date desc
        )
        where rownum <= 10;
end;
/
variable rc refcursor;
exec sp_recent_cancel_orders_rc(:rc);
print rc;




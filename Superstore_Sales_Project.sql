
select *
from dbo.Superstore$

alter table dbo.Superstore$
drop column Row_ID

alter table dbo.Superstore$ alter column Order_Date date
alter table dbo.Superstore$ alter column Ship_Date date

-- Number of customers
select count(distinct Customer_Name)
from dbo.Superstore$

-- Customer info: id, most sales, most orders, most products
select Customer_ID, Customer_Name, count(distinct Order_ID) Total_Orders, sum(Quantity) Total_Products, sum(Sales) Total_Spent
from dbo.Superstore$
group by Customer_ID, Customer_Name
order by Total_Spent desc

-- Discount price by city
select Product_Name, City, 
CASE
	WHEN Discount = 0 THEN Sales/Quantity 
	ELSE Sales/Quantity/(1-Discount)
END as Original_Product_Price,
Sales/Quantity Discount_Product_Price
from dbo.Superstore$
order by Original_Product_Price, Discount_Product_Price

-- Add column "Product_Discount": yes or no
--alter table dbo.Superstore$ drop column if exists Product_Discount

if not exists (
select *
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'dbo.Superstore$' AND COLUMN_NAME = 'Product_Discount')
BEGIN
alter table dbo.Superstore$ add Product_Discount as
	(CASE 
		WHEN Discount = 0 THEN 'No'
		ELSE 'Yes'
	END)
END

-- Products discount, sales & profit by city
select Product_Name, State, City, 
CASE
	WHEN Discount = 0 THEN Sales/Quantity 
	ELSE Sales/Quantity/(1-Discount)
END as Original_Product_Price,
Sales/Quantity as Discount_Product_Price, Product_Discount, Discount, Quantity, Sales, Profit
from dbo.Superstore$
--where Product_Discount = 'Yes'
order by Profit

-- Sales & profit by city & year
select YEAR(Order_Date) Order_Year, State, City, sum(Quantity) Total_Products, sum(Sales) Total_Sales, sum(Profit) Total_Profit
from dbo.Superstore$
group by State, City, YEAR(Order_Date)
order by Order_Year, Total_Profit desc

-- Total sales & profit by category
select Category, sum(Quantity) Total_Products, sum(Sales) Total_Sales, sum(Profit) Total_Profit
from dbo.Superstore$
group by Category
order by Total_Profit desc

-- Total sales & profit by sub-category
select Category, Sub_Category, sum(Quantity) Total_Products, sum(Sales) Total_Sales, sum(Profit) Total_Profit
from dbo.Superstore$
group by Category, Sub_Category
order by Total_Profit desc

-- Products & sales by year
select YEAR(Order_Date) Order_Year, Product_Name, sum(Quantity) as Total_Products, sum(Sales) Total_Sales
from dbo.Superstore$
group by Product_Name, YEAR(Order_Date)
order by Order_Year, Total_Sales desc

-- Total products, sales & profit by segment & shipping mode
select total_products.Segment, Ship_Mode, Total_Products_By_Segment, sum(Quantity) as Total_Products_By_Ship_Mode,
sum(Quantity)/Total_Products_By_Segment*100 as Quantity_Percent, sum(Sales) Total_Sales, sum(Profit) Total_Profit
from
(select Segment, sum(Quantity) as Total_Products_By_Segment
from dbo.Superstore$
group by Segment) total_products
join dbo.Superstore$ store on total_products.Segment = store.Segment
group by total_products.Segment, Ship_Mode, Total_Products_By_Segment
order by Total_Products_By_Segment desc, Total_Products_By_Ship_Mode desc

-- Products, sales & profit by year & month
with CTE_Sum_Sales as (
select YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, sum(Sales) over (partition by YEAR(Order_Date) order by MONTH(Order_Date)) Sum_Total_Sales
from dbo.Superstore$)
select ss.Order_Year, ss.Order_Month, Total_Products, Total_Sales, Sum_Total_Sales, Total_Profit
from CTE_Sum_Sales ss
join
(select YEAR(Order_Date) Order_Year, MONTH(Order_Date) Order_Month, sum(Quantity) Total_Products, sum(Sales) Total_Sales, sum (Profit) Total_Profit
from dbo.Superstore$
group by YEAR(Order_Date), MONTH(Order_Date)) store 
on ss.Order_Year = store.Order_Year and ss.Order_Month = store.Order_Month
group by ss.Order_Year, ss.Order_Month, Total_Products, Total_Sales, Sum_Total_Sales, Total_Profit
order by ss.Order_Year, ss.Order_Month
	use Portfolio_;

	select table_name from  INFORMATION_SCHEMA.TABLES;
	-- the datsets are loaded succesfully
	select * from region_info;
	select * from property_sales;

	--- now let us start the data celaning progess..
	---------------------------------------------------------------------------------------------------------------------------
	-- check for the duplicates 

	with duplicate as
	(select *, ROW_NUMBER() over (partition by Sale_ID, Address,Region_Code, Property_Type,Sale_date order by Sale_ID) as row_count 
	from property_sales)
	select * from duplicate where row_count>1;

	with  region_duplicate as
	(select * , row_number() over (partition by Region_code,Region_Name order by Region_code) as row_cnt from region_info)
	select* from region_duplicate;

	-- noduplicates pn both tables so lets move forwards ..

	---------------------------------------------------------------------------------------------------------------------------
	-- lets check the data_types as well of both tables ;

	SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'property_sales';
	SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'region_info';
	-- lets format the date in correct way 
	alter table property_sales
	alter column Sale_date date ;
	select* from property_sales;

	alter table region_info
	alter column Avg_Property_Price decimal (10,2) ;
	select* from region_info;

	-- now we have formated the date as well 
	---------------------------------------------------------------------------------------------------------------------------
	-- lets check for the null values and missing values

	select count(distinct Sale_ID) from property_sales;

	select * from property_sales a left outer join property_sales b
	on a.Region_Code=b.Region_Code where a.Region_Code <> b.Region_Code;

	-- no missings lets move
	-----------------------------------------------------------------------------------------------------------------------------
	-- now let me create on working table on which we will do the analysis without using the real database tables //
	with work_CTE as
	( select property_sales.*, region_info.Region_Name,region_info.Avg_Income,region_info.Crime_Rate,region_info.Population,region_info.Avg_Property_Price from property_sales full outer join region_info on  property_sales.Region_Code= region_info.Region_Code)
	select * into working_table from
	work_CTE;

	select * from working_table;
	SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'working_table';

	-- drop table working_table;
	-----------------------------------------------------------------------------------------------------------------------------
	-- let me convert the data types as well so that i can do some calculations or can use the aggregate functiuons well
	-- sql server doesnot allow altering together in bulk so going with column wise

	alter table working_table
	alter column Sale_Price decimal(10,2); 
	alter table working_table
	alter column Land_Area_sqm decimal(10,2);
	alter table working_table
	alter column Customer_rating decimal(10,1);
	alter table working_table
	alter column Crime_Rate decimal(10,1);
	alter table working_table
	alter column Population int;

	-- we dont need Region_name as we altready have suburb column so lets drop one /
	alter table working_table drop column Region_Name;
	-----------------------------------------------------------------------------------------------------------------------------

	-- now lets go on with the final data cleaning process of the working_table;
	-- understanding table well + cleaning
	---  duplicates and nulls in our final table
	select Sale_ID from working_table where Sale_ID is null;
	select Sale_ID, count(*) as duplicate_count from working_table group by Sale_ID having count(*)>=2;

	-- Find number of unique suburbs, property types, and agents.
	select  distinct Region_code , Region_Name from working_table;
	select  Property_Type , count(*) as counts from working_table group by Property_Type;
	select distinct Agent_Name from working_table;

	-- Detect outliers — e.g., sale prices > $5 million or < $50k.
	select * from working_table where Sale_Price > 5000000 or Sale_Price < 50000;

	-- any misleading region code 
	select distinct Region_Code from working_table;

	-- any missing ratings or misleading data
	select Customer_Rating from working_table where Customer_Rating = 0 or Customer_Rating >5;

	-- lets get a new column to calculate price per sqm 
	alter table working_table
	add price_per_sqm as cast( Sale_Price/Land_Area_sqm as decimal(10,2));

	-- check the avg_property_price is same per region
	select distinct Avg_Property_Price, Suburb from working_table;

	-- Quick summary
	select 
	max(Sale_Price) as max_sale,
	min(Sale_Price) as min_price,
	stdev(Sale_Price) as mean_value,
	count(*) as total_records from working_table;

	select * from working_table;
	-----------------------------------------------------------------------------------------------------------------------------
	-- lets move with the exploratory analysis part now..
	-- What is the average sale price trend by year in Central Auckland?
	select year(Sale_Date) as sale_year, avg(Sale_Price) as AVG_Sale, Suburb from working_table group by year(Sale_Date),Suburb having Suburb ='Central Auckland' order by sale_year;

	-- Which suburbs are most expensive vs. most affordable in 2023?
	select  Suburb , avg(Sale_Price) as avg_Sale from working_table where year(Sale_Date) = 2023 group by Suburb  order by avg_Sale;

	--- How does number of bedrooms affect sale price in 2023?
	select avg(Sale_Price) as sale, Bedrooms from working_table group by Bedrooms order by sale desc;
	-- not much but 4 bedrooms seems more popoular, followed by 3 bedrooms whereas 2 bedroom stand to the lowest preference in the Auckland market.

	-- Which agents handle the highest total sales volume per year?
	select count(*) as volumes_of_sales, Agent_Name, year(Sale_Date) as years from working_table group by Agent_Name, year(Sale_Date) Order by year(Sale_Date);
	-- barfoot and thompson handeled more in 2021 , meanwhile for last 2 years Harcourts handeled more 

	-- What is the average customer rating per agent?
	select Agent_Name, avg(Customer_Rating) as avg_rating from working_table group by Agent_Name order by avg_rating;
	-- overall, harcourts has got more customer rating and Barfoot has less with value 3.96

	-- What was the cutomer satisfaction level of each agents in different year 
	select Agent_Name, avg(Customer_Rating) as avg_rating, year(Sale_Date) as years from working_table group by Agent_Name,year(Sale_Date);
	-- Harcourt did very well on 2022 within customer satisfaction with 4.09, in 223 barfoot worked well with customer satisfaction labeled as 4.03

	-- Compare average sale price per property type.
	select avg(Sale_Price) as Avg_sale, Property_Type from working_table group by Property_Type order by Avg_sale desc;
	-- House seems to be having more sale price and townhouses has less 

	-- Which region has the fastest-growing sale prices (YoY)?
	-- lets use lag function and cte as well it helps in testing the year wise difference and growth
	with yoy as 
	(select Suburb, Avg(Sale_Price) as Avg_Sale_Price, year(Sale_Date) as years from working_table group by Suburb, year(Sale_Date))
	select Suburb ,years, Avg_Sale_Price,
		LAG(Avg_Sale_Price) OVER (PARTITION BY Suburb ORDER BY years) AS Prev_Year_Price,
		Avg_Sale_Price - LAG(Avg_Sale_Price) OVER (PARTITION BY Suburb ORDER BY years) AS Growth_Amount
	FROM yoy
	ORDER BY Growth_Amount DESC;

	-- Is there a relationship between region’s Avg_Income and Sale_Price?

	WITH Stats AS (
		SELECT 
			AVG(Avg_Income) AS Mean_Income,
			AVG(Sale_Price) AS Mean_Price
		FROM working_table
	),
	Covariance AS (
		SELECT 
			SUM((Avg_Income - s.Mean_Income) * (Sale_Price - s.Mean_Price)) AS Covar,
			SUM(POWER(Avg_Income - s.Mean_Income,2)) AS VarIncome,
			SUM(POWER(Sale_Price - s.Mean_Price,2)) AS VarPrice
		FROM working_table, Stats s
	)
	SELECT CAST(Covar AS FLOAT) / SQRT(VarIncome * VarPrice) AS Income_Price_Correlation
	FROM Covariance;

	-- Which regions have high Avg_Income but low property prices → investment opportunity?
	select  Suburb, avg(Avg_Income) as avg_Income, avg(Avg_Property_Price) as avg_PP from working_table group by Suburb order by avg_PP asc;
	-- papakura 1st., South Auckland 2nd, Henderson and west auckland seril wise these are best poetential investment ... but need to check for the market change per year

	-- Which suburbs have the highest crime rate but still high prices (price resilience)?
	select avg(Crime_Rate) as crimerate, Suburb, avg(Sale_Price) as prices from working_table group by Suburb order by prices desc;
	-- West Auckland major , East Auckland second and South Auckland

	-----------------------------------------------------------------------------------------------------------------------------

	-- Advanced SQl analysis

	-- Rank suburbs by average sale price using RANK() window.

	select avg(Sale_Price) as s_p , Suburb , rank() over (order by avg(Sale_Price)) as rankings from working_table group by Suburb;

	-- Classify each property sales as Luxury / Mid-range / Affordable using CASE: Luxury → Sale_Price > 1.5× Avg_Property_Price, > 0.5 * avg_price = mid
	create view  classification_View as 
	select Suburb, Sale_Price, Avg_Property_Price,
	case when Sale_Price > 1.5* Avg_Property_Price then ' Luxury'
	when Sale_Price > 0.8 * Avg_Property_Price then 'Medium_Range'
	else 'affordable'
	end as Property_Classification from working_table; 

	select * from classification_View;

	select count(*) as counts, Property_Classification from classification_View group by Property_Classification order by counts;

	-- Identify top 3 agents with the most luxury sales.
	-- lets work using cte because we need case statement.. and based on the case we need data so 
	with agents as (select Sale_Price,
	case when Sale_Price > 1.5* Avg_Property_Price then 'Luxury'
	when Sale_Price > 0.8 * Avg_Property_Price then 'Medium_Range'
	else 'affordable'
	end as Property_Classification, Agent_Name from working_table)
	select top 3 sum(Sale_Price) as total_Sales, Agent_Name, Property_Classification from agents where Property_Classification ='Luxury' 
	group by Agent_Name, Property_Classification order by total_Sales desc;

	-- Find properties above suburb median sale price using window PERCENTILE_CONT().
	-- we have useed more cte so now lets move with sub query feature //

	select Sale_ID,Suburb, Sale_Price, Median_Price ,case when Sale_Price > Median_Price then 'Above median' else 'below median' end as price_category
	from (select Sale_ID,Suburb, Sale_Price, percentile_cont(0.5) within group (order by Sale_price) over (partition by Suburb) as Median_Price from working_table)
	as SuburbMedian where Sale_Price>Median_Price order by Sale_Price desc;

	-- Show cumulative total sales per month per region (SUM() OVER(ORDER BY Month)).
	with Cum_S as (
	SELECT 
		Suburb,
		FORMAT(Sale_Date, 'yyyy-MM') AS Sale_Month,
		SUM(Sale_Price) AS Monthly_Sales
	FROM working_table
	GROUP BY Suburb, FORMAT(Sale_Date, 'yyyy-MM'))
	select Suburb, Sale_Month , Monthly_Sales, sum(Monthly_Sales) over (partition by Suburb order by Sale_Month rows between unbounded preceding and current row) as Cumulative_Sales
	from Cum_S order by Suburb desc, Sale_Month;

	-- Calculate average price per sqm by property type and region.
	select avg(price_per_sqm) as avg_per_sqm, Property_Type, Suburb from working_table group by Property_Type,Suburb order by Suburb; 

	-- Identify sales with high sales but below-average customer ratings (potential issue).

	WITH AgentPerformance AS (
		SELECT 
			Agent_Name,
			YEAR(Sale_Date) AS Sale_Year,
			SUM(Sale_Price) AS Total_Sales,
			AVG(Customer_Rating) AS Avg_Rating
		FROM working_table
		GROUP BY Agent_Name, YEAR(Sale_Date)
	)
	, OverallAverages AS (
		SELECT 
			AVG(Total_Sales) AS Overall_Avg_Sales,
			AVG(Avg_Rating) AS Overall_Avg_Rating
		FROM AgentPerformance
	)
	select  
		A.Agent_Name,
		A.Sale_Year,
		A.Total_Sales,
		A.Avg_Rating
	FROM AgentPerformance A
	CROSS JOIN OverallAverages O
	WHERE 
		A.Total_Sales > O.Overall_Avg_Sales   -- high sales
		AND A.Avg_Rating < O.Overall_Avg_Rating  -- below-average rating
	ORDER BY A.Total_Sales DESC;

	select * from working_table;

	--------------------------------------------------------------------------------------
	-- Growth of sales per year over year
	WITH PriceTrend AS (
		SELECT
			Suburb,
			YEAR(Sale_Date) AS Sale_Year,
			AVG(Sale_Price) AS Avg_Price
		FROM working_table
		GROUP BY Suburb, YEAR(Sale_Date)
	),
	Growth AS (
		SELECT
			Suburb,
			Sale_Year,
			Avg_Price,
			LAG(Avg_Price) OVER (PARTITION BY Suburb ORDER BY Sale_Year) AS Prev_Price
		FROM PriceTrend
	)
	SELECT 
		Suburb,
		Sale_Year,
		ROUND(((Avg_Price - Prev_Price) / Prev_Price) * 100, 2) AS YoY_Growth_Percentage
	FROM Growth
	WHERE Prev_Price IS NOT NULL
	ORDER BY YoY_Growth_Percentage DESC;

-----------------------------------------------------------------------------------------------------------------------------

-- lets create automated cleaning for working_table so that the table is cleaned itself ..
CREATE PROCEDURE sp_CleanPropertyData
AS
BEGIN
    -- Remove duplicate sale IDs
    WITH cte_duplicates AS (
        SELECT Sale_ID, ROW_NUMBER() OVER (PARTITION BY Sale_ID ORDER BY Sale_ID) AS rn
        FROM working_table
    )
    DELETE FROM cte_duplicates
    WHERE rn > 1;

    -- Trim whitespace in string columns
    UPDATE working_table
    SET 
        Address = LTRIM(RTRIM(Address)),
        Suburb = LTRIM(RTRIM(Suburb)),
        Region_Code = LTRIM(RTRIM(Region_Code)),
        Property_Type = LTRIM(RTRIM(Property_Type)),
        Agent_Name = LTRIM(RTRIM(Agent_Name));

    -- Replace NULL bedroom/bathroom count with median
    UPDATE working_table
    SET Bedrooms = (
        SELECT TOP 1 Bedrooms FROM working_table
        WHERE Bedrooms IS NOT NULL
        ORDER BY Bedrooms
    )
    WHERE Bedrooms IS NULL;

    UPDATE working_table
    SET Bathrooms = (
        SELECT TOP 1 Bathrooms FROM working_table
        WHERE Bathrooms IS NOT NULL
        ORDER BY Bathrooms
    )
    WHERE Bathrooms IS NULL;

    -- Set missing ratings to default 3
    UPDATE working_table
    SET Customer_Rating = 3
    WHERE Customer_Rating IS NULL;

    PRINT 'Data cleaning completed successfully.';
END;

exec sp_CleanPropertyData
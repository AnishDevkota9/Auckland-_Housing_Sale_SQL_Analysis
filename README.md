# Auckland-_Housing_Sale_SQL_Analysis
This is a small analysis in SQL server done with the sample auckland realestate data.


Project Overview
This SQL Server project analyzes Auckland's real estate market by combining property sales data with regional socio-economic data. It includes data cleaning, transformation, merging, and advanced data analysis to extract important business insights.

Objectives
• Import and validate datasets
• Perform data quality checks and data type corrections
• Remove duplicates and detect missing values
• Create an analytical working table through a join
• Engineer new calculated features (price per sqm)
• Run advanced SQL queries to answer business questions
• Automate cleaning using a stored procedure

Datasets
• property_sales: Contains sales, property attributes, agent, and customer ratings
• region_info: Contains region code, average income, crime rate, population, and avg property prices
• working_table: Final cleaned and merged dataset for analysis

Data Cleaning and Transformation Steps

Checked duplicates using window functions

Removed inconsistent records

Converted incorrect data types (numeric and date)

Checked outliers in sale price

Removed unnecessary columns to reduce redundancy

Created a new metric: price_per_sqm

Generated a working table using FULL OUTER JOIN

Built a stored procedure to automate data preparation

Advanced SQL Analysis Conducted
• Yearly average sale price trends
• Most expensive and most affordable suburbs
• Bedrooms vs sale price comparison
• Agent performance by sales volume and customer rating
• YoY price growth using window functions
• Correlation between income and sale price
• Regions with high income but low prices (investment potential)
• Areas with high crime but strong price resilience
• Price classification using CASE statement
• Median price benchmark and outlier detection
• Cumulative monthly sales per suburb
• Price per sqm comparisons

Stored Procedure
A stored procedure was created to automate:
• Cleaning and standardizing the data
• Rebuilding the working table
• Making the dataset ready for analysis any time

This allows the database to be refreshed when new data arrives, without rewriting the cleaning queries.

Key Findings
• Houses have the highest valuation compared to other property types
• Harcourts shows the strongest customer satisfaction scores
• 4-bedroom properties are the strongest market performer
• Papakura and South Auckland show best investment opportunities
• West and East Auckland maintain high prices despite higher crime indicators

Skills Demonstrated
• SQL Server (T-SQL)
• Window functions
• Joins and subqueries
• Data cleaning and transformation
• ETL automation using Stored Procedures
• Business-driven data analytics

Future Enhancements
• Create a Power BI dashboard
• Automate stored procedure with SQL Server Agent scheduling
• Export and integrate results into Python or ML models

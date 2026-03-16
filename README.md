# sql-sales-analysis-project
SQL Server project analyzing sales and customer trends

## Tools
SQL Server

## Dataset
Online Retail Dataset

## Project Steps
1. Data cleaning
2. Removing duplicates
3. Handling null values
4. Standardizing date formats
5. Sales analysis

## SQL Concepts Used
CTE
Window Functions
GROUP BY
Aggregate Functions

## Sample Query
SELECT StockCode,
SUM(Quantity * Price) AS Revenue
FROM online_retail
GROUP BY StockCode
ORDER BY Revenue DESC;

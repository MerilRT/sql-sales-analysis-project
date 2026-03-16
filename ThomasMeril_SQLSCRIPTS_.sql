
USE T1

SELECT * FROM [dbo].[online_retail_II]

SELECT COUNT(*)
FROM  [dbo].[online_retail_II]
--1067371
----------------------------------------------------------
--###CHECKING NULL VALUES
----------------------------------------------------------
SELECT COUNT(*)-COUNT(Description)
FROM  [dbo].[online_retail_II]  
--4382 nulls /

SELECT COUNT(*)-COUNT(Quantity)
FROM  [dbo].[online_retail_II]  
--0

SELECT COUNT(*)-COUNT(InvoiceDate)
FROM  [dbo].[online_retail_II] 
--0

SELECT COUNT(*)-COUNT(Price)
FROM  [dbo].[online_retail_II]
--0
SELECT COUNT(*)-COUNT(Customer_ID)
FROM  [dbo].[online_retail_II]
--243007

SELECT COUNT(*)-COUNT(Country)
FROM  [dbo].[online_retail_II]
--0

----------------------------------------------------------
--###POPULATING DESCRIPTION
----------------------------------------------------------

--step1-check
SELECT  a.StockCode, ISNULL(a.Description, b.Description)AS NULL_DESCRIPTION,
       a.Description AS MissingDescription,
       b.Description AS AvailableDescription
FROM dbo.online_retail_II AS a
JOIN dbo.online_retail_II AS b
ON a.StockCode = b.StockCode
WHERE a.Description IS NULL
AND b.Description IS NOT NULL;

--step-2alter
--NOT creating a separate table

--step3-update
UPDATE A
SET Description= ISNULL(a.Description, b.Description)
FROM dbo.online_retail_II AS a
JOIN dbo.online_retail_II AS b
ON a.StockCode = b.StockCode
WHERE a.Description IS NULL
AND b.Description IS NOT NULL;


----------------------------------------------------------
--###REMOVING DUPLICATES
----------------------------------------------------------

--step1-check

WITH CTE_DUPLI AS
(
SELECT [Invoice],
ROW_NUMBER() OVER(PARTITION BY [Invoice],
[StockCode],[Description],[Quantity], [InvoiceDate],
[Price], [Customer_ID],[Country] ORDER BY INVOICE  ) AS DUPLI
FROM [dbo].[online_retail_II]
)

SELECT INVOICE, DUPLI
FROM CTE_DUPLI
WHERE DUPLI >1


--step-2alter

WITH CTE_DUPLI AS
(
SELECT [Invoice],
ROW_NUMBER() OVER(PARTITION BY [Invoice],
[StockCode],[Description],[Quantity], [InvoiceDate], 
[Price], [Customer_ID],[Country] ORDER BY INVOICE  ) AS DUPLI
FROM [dbo].[online_retail_II]
)

DELETE 
FROM CTE_DUPLI
WHERE DUPLI>1

--step3-update
--no updation required

----------------------------------------------------------
--###CHANGE DATE FORMAT
----------------------------------------------------------

--step1-check
SELECT INVOICE, INVOICEDATE, CONVERT(DATE, INVOICEDATE) AS CONVERT_DATE
FROM [dbo].[online_retail_II]

--ALTER

ALTER TABLE [dbo].[online_retail_II]
ADD N_DATE DATE;

--UPDATE
UPDATE [dbo].[online_retail_II]
SET N_DATE= CONVERT(DATE, INVOICEDATE)

--ALTER

ALTER TABLE [dbo].[online_retail_II]
DROP COLUMN [InvoiceDate]

----------------------------------------------------------
--###CREATE CALCULATED FIELDS
----------------------------------------------------------
ALTER TABLE [dbo].[online_retail_II]
ADD TOTAL_SALES DECIMAL(10,2)

UPDATE  [dbo].[online_retail_II]
SET TOTAL_SALES= QUANTITY* PRICE

SELECT * FROM [dbo].[online_retail_II]

----------------------------------------------------------
--###REGIONAL SALES
----------------------------------------------------------

SELECT COUNTRY, SUM(TOTAL_SALES) AS REGION_SALES
FROM [dbo].[online_retail_II]
WHERE QUANTITY>0
GROUP BY COUNTRY
ORDER BY REGION_SALES DESC


----------------------------------------------------------
--###TIME-BASED TRENDS
----------------------------------------------------------

SELECT MONTH_T, MONTH(N_DATE) month_num ,  SUM(sum(TOTAL_SALES)) OVER(ORDER BY MONTH_T)AS month_sum
FROM (SELECT N_DATE,TOTAL_SALES, DATENAME(MONTH,N_DATE)AS MONTH_T
FROM  [dbo].[online_retail_II]
 )T
 GROUP BY MONTH_T, MONTH(N_DATE)
 ORDER BY MONTH(N_DATE)

 ----------------------------------------------------------
--###PRODUCT PERFORMANCE
----------------------------------------------------------

WITH CTE_PRODCUTPERFORMANCE AS
(
SELECT STOCKCODE, sum(total_sales) sales_total, count(*) as stock_count
FROM (SELECT STOCKCODE, TOTAL_SALES, QUANTITY
FROM [dbo].[online_retail_II]) T
WHERE QUANTITY>0
group by STOCKCODE
)
SELECT *, dense_rank() over(order by sales_total desc) as performance_ranks
FROM CTE_PRODCUTPERFORMANCE
WHERE SALES_TOTAL> (SELECT AVG(SALES_TOTAL) FROM CTE_PRODCUTPERFORMANCE)

 ----------------------------------------------------------
--###CUSTOMER BEHAVIOUR ANALYSIS
----------------------------------------------------------

WITH CUSTOMER_BEHAVIOUR AS
(
SELECT CUSTOMER_ID, COUNT(*) NUM_PURCHASE, SUM(TOTAL_SALES) AS SALES_CUSTOMER
FROM[dbo].[online_retail_II]
WHERE QUANTITY>0 AND CUSTOMER_ID IS NOT NULL
GROUP BY CUSTOMER_ID 
)

,PURCHASE_RANK AS
(
SELECT CUSTOMER_ID, DENSE_RANK() OVER(ORDER BY NUM_PURCHASE DESC) AS PURCHASE_RNK
FROM CUSTOMER_BEHAVIOUR
)


SELECT a.* ,b.PURCHASE_RNK, (CASE
WHEN PURCHASE_RNK BETWEEN 1 AND 228 THEN 'HIGH PURCHASE CUSTOMER'
WHEN PURCHASE_RNK BETWEEN 229 AND  THEN 'MEDIUM PURCHASE CUSTOMER'
ELSE 'LOW PURCHASE CUSTOMER'
END) AS CUSTOMER_BEHAVIOUR
FROM CUSTOMER_BEHAVIOUR AS A 
JOIN PURCHASE_RANK AS B
ON A.CUSTOMER_ID= B.CUSTOMER_ID
order by  PURCHASE_RNK


 ----------------------------------------------------------
--###MONTH ON MONTH SALES
--((Current Period Value - Previous Period Value) / Previous Period Value) * 100
----------------------------------------------------------

WITH MONTH_CTE AS
(
SELECT LAG(SUM_SALES) OVER(ORDER BY N_YEAR,  N_MONTH ) AS SUM_PRV, N_MONTH, N_YEAR, SUM_SALES
FROM (SELECT MONTH(N_DATE) AS N_MONTH, YEAR(N_DATE) AS N_YEAR, SUM(TOTAL_SALES) SUM_SALES
FROM [dbo].[online_retail_II]
WHERE Customer_ID IS NOT NULL AND QUANTITY >0 
GROUP BY MONTH(N_DATE), YEAR(N_DATE) )T
)


SELECT N_MONTH,N_YEAR,SUM_SALES, ( ((SUM_SALES- SUM_PRV)/NULLIF(SUM_PRV,0))*100 )AS MONTH_ON_MONTH_SALES
FROM MONTH_CTE 
WHERE SUM_PRV>0


 ----------------------------------------------------------
--###TOP PERFORMING PRODUCTS
----------------------------------------------------------
WITH CTE_PRODCUTPERFORMANCE AS
(
SELECT STOCKCODE, sum(total_sales) sales_total, count(*) as stock_count, COUNTRY, DESCRIPTION
FROM (SELECT STOCKCODE, TOTAL_SALES, QUANTITY, COUNTRY, DESCRIPTION
FROM [dbo].[online_retail_II]) T
WHERE QUANTITY>0
group by STOCKCODE, COUNTRY, DESCRIPTION
)
SELECT *, dense_rank() over(order by sales_total desc) as performance_ranks
FROM CTE_PRODCUTPERFORMANCE
WHERE SALES_TOTAL> (SELECT AVG(SALES_TOTAL) FROM CTE_PRODCUTPERFORMANCE)

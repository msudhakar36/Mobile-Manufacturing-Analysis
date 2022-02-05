---  use db_SQLCaseStudies

--Q1. LIST ALL THE STATES IN WHICH WE HAVE CUSTOMERS WHO HAVE BOUGHT CELLPHONES FROM YEAR 2005 TILL TODAY.



SELECT DISTINCT T2.State
 FROM DBO.FACT_TRANSACTIONS AS T1
LEFT JOIN DBO.DIM_LOCATION AS T2  ON T1.IDLocation = T2.IDLocation
WHERE DATEPART (YEAR,T1.Date ) >='2005'


--Q2 . WHAT STATE IN US BUYING MORE SAMSUMG CELL PHONE

Select TOP 1  State, 
COUNT(Manufacturer_Name) AS MANU_COUNT
 FROM DBO.FACT_TRANSACTIONS AS T1
LEFT JOIN DBO.DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
LEFT JOIN DBO.DIM_LOCATION AS T3 ON T1.IDLocation = T3.IDLocation
LEFT JOIN DBO.DIM_MANUFACTURER AS T4 ON T2.IDManufacturer = T4.IDManufacturer
GROUP BY Manufacturer_Name, COUNTRY , State
ORDER BY Country desc, MANU_COUNT desc



--Q3.SHOW THE NO OF TRANSACTION FOR EACH MODEL PER ZIP CODE PER STATE


Select DISTINCT  T2.Model_Name, T3.State , ZipCode,
COUNT(Model_Name)AS NO_OF_TRANSACTION
 FROM DBO.FACT_TRANSACTIONS AS T1
LEFT JOIN DBO.DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
LEFT JOIN DBO.DIM_LOCATION AS T3 ON T1.IDLocation = T3.IDLocation
LEFT JOIN DBO.DIM_MANUFACTURER AS T4 ON T2.IDManufacturer = T4.IDManufacturer
GROUP BY Model_Name , state , ZipCode


--Q4. SHOW THE CHEAPEST CELL PHONE


SELECT DISTINCT TOP 1 T4.Manufacturer_Name ,T2.Model_Name ,T2.Unit_price 
 FROM DBO.FACT_TRANSACTIONS AS T1
LEFT JOIN DBO.DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
LEFT JOIN DBO.DIM_LOCATION AS T3 ON T1.IDLocation = T3.IDLocation
LEFT JOIN DBO.DIM_MANUFACTURER AS T4 ON T2.IDManufacturer = T4.IDManufacturer
ORDER BY Unit_price ASC



--Q5 FIND OUT AVERAGE PRICE FOR EACH MODEL IN TOP 5 MANUFACTURERS IN TERM OF SALES QUANTITY AND ORDER BY AVERAGE PRICE

SELECT FORMAT (AVG(T1.TOTALPRICE),'#,0.00') AS AVERAGE_PRICE, T2.MODEL_NAME
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_MODEL AS T2 ON T1.IDMODEL= T2.IDMODEL
WHERE T2.IDMANUFACTURER IN (SELECT TOP 5 T5.IDMANUFACTURER
FROM FACT_TRANSACTIONS T4
LEFT JOIN DIM_MODEL AS T5 ON T4.IDMODEL= T5.IDMODEL
GROUP BY T5.IDMANUFACTURER
ORDER BY SUM(T4.TOTALPRICE) DESC,SUM(T4.QUANTITY) DESC)
GROUP BY T2.MODEL_NAME
ORDER BY AVG(T1.TOTALPRICE) DESC



--Q6. LIST THE NAMES OF THE CUSTOMER AND THE AVERAGE AMOUNT SPENT IN 2009 WHERE THE AVERAGE IS HIGHER THAN 500



Select Customer_Name,
AVG (TOTALPRICE) AS AVERAGE_PRICE
 FROM DBO.FACT_TRANSACTIONS 
 LEFT JOIN DBO.DIM_CUSTOMER ON DBO.FACT_TRANSACTIONS.IDCustomer = DBO.DIM_CUSTOMER.IDCustomer
 WHERE YEAR (DATE ) = '2009'
 GROUP BY Customer_Name
 HAVING AVG (TOTALPRICE) > '500'
 ORDER BY AVERAGE_PRICE



--Q7 . LIST IF THERE IS ANY MODEL THAT WAS IN THE TOP 5 IN TERM OF QUANTITY SIMULTANEOUSLY IN 2008 , 2009 AND 2010

SELECT DISTINCT T1.IDModel , T2.Model_Name 
FROM DBO.FACT_TRANSACTIONS AS T1
LEFT JOIN DBO.DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
WHERE T1.IDModel IN (SELECT TOP 5 T3.IDModel  FROM DBO.FACT_TRANSACTIONS AS T3
WHERE DATEPART (YEAR, T3.DATE ) = '2008'GROUP BY T3.IDModel ORDER BY SUM (T3.QUANTITY) DESC)
AND T1.IDModel IN (SELECT TOP 5 T4.IDModel  FROM DBO.FACT_TRANSACTIONS AS T4
WHERE DATEPART (YEAR, T4.DATE ) = '2009'GROUP BY T4.IDModel ORDER BY SUM (T4.QUANTITY) DESC)
AND T1.IDModel IN (SELECT TOP 5 T5.IDModel  FROM DBO.FACT_TRANSACTIONS AS T5
WHERE DATEPART (YEAR, T5.DATE ) = '2010'GROUP BY T5.IDModel ORDER BY SUM (T5.QUANTITY) DESC)



--Q8.SHOW THE MANUFACTURER WITH THE 2ND TOP SALES IN THE YEAR OF 2009 AND THE MANUFACTURER WITH 2N TOP SALES IN THE YEAR 2010


WITH cte AS
(
SELECT Manufacturer_name, DATEPART(Year,date) as yr,
DENSE_RANK() OVER (PARTITION BY DATEPART(Year,date) ORDER BY SUM(TotalPrice) DESC) AS Rank 
    FROM DBO.FACT_TRANSACTIONS T1
    LEFT JOIN DBO.DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
    LEFT JOIN DBO.DIM_MANUFACTURER AS T3 ON T3.IDManufacturer = T2.IDManufacturer
    group by Manufacturer_name,DATEPART(Year,date) 
),
cte2 AS(
SELECT Manufacturer_Name, yr
FROM cte WHERE rank = 2
AND yr IN ('2009','2010')
)
SELECT c.Manufacturer_Name AS Manufacturer_Name_2009
,t.Manufacturer_Name AS Manufacturer_Name_2010
FROM cte2 AS c, cte2 AS t
WHERE c.yr < t.yr;



--Q9. SHOW THE MANUFACTURER SOLD CELLPHONE IN 2010 BUT DIDN'T IN 2009


SELECT DISTINCT T3.MANUFACTURER_NAME
FROM FACT_TRANSACTIONS T1
LEFT JOIN DIM_MODEL AS T2 ON T1.IDMODEL= T2.IDMODEL
LEFT JOIN DIM_MANUFACTURER AS T3 ON T2.IDMANUFACTURER= T3.IDMANUFACTURER
WHERE DATEPART(YEAR,T1.DATE) ='2010'
AND T3.MANUFACTURER_NAME NOT IN (SELECT T6.MANUFACTURER_NAME
FROM FACT_TRANSACTIONS T4
LEFT JOIN DIM_MODEL AS T5 ON T4.IDMODEL= T5.IDMODEL
LEFT JOIN DIM_MANUFACTURER AS T6 ON T5.IDMANUFACTURER= T6.IDMANUFACTURER
WHERE DATEPART(YEAR,T4.DATE)='2009')



--Q10. FIND TOP 100 CUSTOMER AND THEIR AVERAGE SPEND , AVERAGE QUANTITY BY EACH BY EACH YEAR, 
--ALSO FIND THE PERCENTAGE OF CHANGE IN THEIR SPEND 


SELECT TOP 100 Customer_Name , 
DATEPART (YEAR ,Date) as Year,
AVG (TotalPrice) AS AVERAGE_SPEND,
AVG (Quantity) AS AVERAGE_QUANTITY,
((AVG (TotalPrice) - LAG ( AVG (TotalPrice) )OVER ( PARTITION BY Customer_Name ORDER BY  DATEPART (YEAR ,Date) ASC  ) )/ AVG (TotalPrice))* 100 [%CHANGE IN SPEND ]
FROM DBO.FACT_TRANSACTIONS
LEFT JOIN DBO.DIM_CUSTOMER ON DBO.FACT_TRANSACTIONS.IDCustomer = DBO.DIM_CUSTOMER.IDCustomer
Group by DATEPART (YEAR ,Date),Customer_Name
ORDER BY Customer_Name,Year ASC

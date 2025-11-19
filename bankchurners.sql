
Select *
From BankChurners..[Credit Card Customers]

-- Data inspection & cleaning
-- 1.1 Schema Inspection

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Credit Card Customers'
-- do not need brackets here bcs INFORMATION_SCHEMA queries require the actual name without schema qualifiers
ORDER BY ORDINAL_POSITION;


-- 1.2 Build the CLEAN version of the table

CREATE TABLE CreditCardCustomers_clean (
    CLIENTNUM BIGINT PRIMARY KEY,
    Attrition_Flag NVARCHAR(50),
    Customer_Age INT,
    Gender NVARCHAR(10),
    Dependent_count INT,
    Education_Level NVARCHAR(50),
    Marital_Status NVARCHAR(50),
    Income_Category NVARCHAR(50),
    Card_Category NVARCHAR(50),
    Months_on_book INT,
    Total_Relationship_Count INT,
    Months_Inactive_12_mon INT,
    Contacts_Count_12_mon INT,
    Credit_Limit DECIMAL(10,2),
    Total_Revolving_Bal INT,
    Avg_Open_To_Buy DECIMAL(10,2),
    Total_Amt_Chng_Q4_Q1 DECIMAL(10,3),
    Total_Trans_Amt INT,
    Total_Trans_Ct INT,
    Total_Ct_Chng_Q4_Q1 DECIMAL(10,3),
    Avg_Utilization_Ratio DECIMAL(10,3)
);


-- 1.3 Insert cleaned data into new table

INSERT INTO CreditCardCustomers_clean
SELECT
    CAST(CLIENTNUM AS BIGINT),
    Attrition_Flag,
    CAST(Customer_Age AS INT),
    Gender,
    CAST(Dependent_count AS INT),
    Education_Level,
    Marital_Status,
    Income_Category,
    Card_Category,
    CAST(Months_on_book AS INT),
    CAST(Total_Relationship_Count AS INT),
    CAST(Months_Inactive_12_mon AS INT),
    CAST(Contacts_Count_12_mon AS INT),
    CAST(Credit_Limit AS DECIMAL(10,2)),
    CAST(Total_Revolving_Bal AS INT),
    CAST(Avg_Open_To_Buy AS DECIMAL(10,2)),
    CAST(Total_Amt_Chng_Q4_Q1 AS DECIMAL(10,3)),
    CAST(Total_Trans_Amt AS INT),
    CAST(Total_Trans_Ct AS INT),
    CAST(Total_Ct_Chng_Q4_Q1 AS DECIMAL(10,3)),
    CAST(Avg_Utilization_Ratio AS DECIMAL(10,3))
FROM [Credit Card Customers];


-- Validate clean table
-- 2.1 Check row count in cleaned table

SELECT 
    (SELECT COUNT(*) FROM [Credit Card Customers]) AS original_count,
    (SELECT COUNT(*) FROM CreditCardCustomers_clean) AS cleaned_count;


-- 2.2 Check for NULLs introduced during CAST

SELECT 
    SUM(CASE WHEN CLIENTNUM IS NULL THEN 1 ELSE 0 END) AS null_CLIENTNUM,
    SUM(CASE WHEN Customer_Age IS NULL THEN 1 ELSE 0 END) AS null_Age,
    SUM(CASE WHEN Dependent_count IS NULL THEN 1 ELSE 0 END) AS null_DependentCount,
    SUM(CASE WHEN Months_on_book IS NULL THEN 1 ELSE 0 END) AS null_MonthsOnBook,
    SUM(CASE WHEN Credit_Limit IS NULL THEN 1 ELSE 0 END) AS null_CreditLimit,
    SUM(CASE WHEN Total_Trans_Amt IS NULL THEN 1 ELSE 0 END) AS null_TotalTransAmt
FROM CreditCardCustomers_clean;

-- Check for NULLs from original table

SELECT 
    SUM(CASE WHEN CLIENTNUM IS NULL THEN 1 ELSE 0 END) AS null_CLIENTNUM,
    SUM(CASE WHEN Customer_Age IS NULL THEN 1 ELSE 0 END) AS null_Age,
    SUM(CASE WHEN Dependent_count IS NULL THEN 1 ELSE 0 END) AS null_DependentCount,
    SUM(CASE WHEN Months_on_book IS NULL THEN 1 ELSE 0 END) AS null_MonthsOnBook,
    SUM(CASE WHEN Credit_Limit IS NULL THEN 1 ELSE 0 END) AS null_CreditLimit,
    SUM(CASE WHEN Total_Trans_Amt IS NULL THEN 1 ELSE 0 END) AS null_TotalTransAmt
FROM [Credit Card Customers];


-- New clean table is ready

Select *
From BankChurners..CreditCardCustomers_clean


-- 2.3 Spot check numeric distributions

SELECT 
    MIN(Customer_Age) AS min_age,
    MAX(Customer_Age) AS max_age,
    MIN(Total_Trans_Ct) AS min_trans,
    MAX(Total_Trans_Ct) AS max_trans,
    MIN(Avg_Utilization_Ratio) AS min_util,
    MAX(Avg_Utilization_Ratio) AS max_util
FROM CreditCardCustomers_clean;


-- 2.4 Check distinct values of key categorical fields

SELECT DISTINCT Attrition_Flag FROM CreditCardCustomers_clean;
SELECT DISTINCT Gender FROM CreditCardCustomers_clean;
SELECT DISTINCT Education_Level FROM CreditCardCustomers_clean;
SELECT DISTINCT Card_Category FROM CreditCardCustomers_clean;


-- Exploratory SQL Analysis (EDA)
-- 3.1 Churn rate overview from CLEAN table
-- Percentage Attrited Vs Existing Customer

SELECT 
    Attrition_Flag,
    COUNT(*) AS cnt,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM CreditCardCustomers_clean
GROUP BY Attrition_Flag;


-- Demographics churn
-- 3.2 Churn by Gender

SELECT 
    Gender,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END)
          / COUNT(*), 2) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Gender
ORDER BY churn_rate DESC;

-- 3.2.1 To show which gender have lower average credit limits → they are more likely to churn

SELECT Gender, AVG(Credit_Limit) AS avg_limit
FROM CreditCardCustomers_clean
GROUP BY Gender;

-- 3.2.2 To show which gender have lower total transaction counts → they are more likely to churn

SELECT Gender, AVG(Total_Trans_Ct) AS avg_transactions
FROM CreditCardCustomers_clean
GROUP BY Gender;


-- 3.3 Churn by Income Category

SELECT 
    Income_Category,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END)
          / COUNT(*), 2) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Income_Category
ORDER BY churn_rate DESC;

-- 3.3.1 To show income category differences by gender → lower are more likely to churn

SELECT
    Gender,
    Income_Category,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) 
          / COUNT(*), 2) AS churn_pct
FROM CreditCardCustomers_clean
GROUP BY Gender, Income_Category
ORDER BY Gender, Income_Category;

-- opt 2 Churn % within each Income Category (Gender side-by-side)

WITH summary AS (
    SELECT
        Income_Category,
        Gender,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count
    FROM CreditCardCustomers_clean
    GROUP BY Income_Category, Gender
)
SELECT
    Income_Category,
    COALESCE(
        MAX(CASE WHEN Gender = 'F' THEN churn_count * 100.0 / total_customers END),
        0
    ) AS churn_pct_female,
    COALESCE(
        MAX(CASE WHEN Gender = 'M' THEN churn_count * 100.0 / total_customers END),
        0
    ) AS churn_pct_male
FROM summary
GROUP BY Income_Category
ORDER BY Income_Category;


-- 3.4 Churn by Education Level

SELECT 
    Education_Level,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END)
          / COUNT(*), 2) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Education_Level
ORDER BY churn_rate DESC;


-- 3.5 Churn by Age Group

WITH AgeGroups AS (
    SELECT 
        CASE 
            WHEN Customer_Age < 30 THEN '20s'
            WHEN Customer_Age BETWEEN 30 AND 39 THEN '30s'
            WHEN Customer_Age BETWEEN 40 AND 49 THEN '40s'
            WHEN Customer_Age BETWEEN 50 AND 59 THEN '50s'
            WHEN Customer_Age BETWEEN 60 AND 69 THEN '60s'
            ELSE '70+'
        END AS Age_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT 
    Age_Band,
    COUNT(*) AS total,
    COALESCE(SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END), 0) AS churn_count,
    ROUND(
        100.0 * COALESCE(SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END), 0) 
        / COUNT(*),
        2
    ) AS churn_pct
FROM AgeGroups
GROUP BY Age_Band
ORDER BY Age_Band;


-- 3.6 Churn by Marital Status

SELECT 
    COALESCE(Marital_Status, 'Unknown') AS Marital_Status,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        2
    ) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY COALESCE(Marital_Status, 'Unknown')
ORDER BY churn_rate DESC;


-- Transactions & credit churn dimensions
-- 4.1 Churn by Card Category (Card Tier)

SELECT 
    Card_Category,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END)
          / COUNT(*), 2) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Card_Category
ORDER BY churn_rate DESC;


-- 4.2 Churn by Credit limit (bucket)

WITH CreditBins AS (
    SELECT
        CASE
            WHEN Credit_Limit < 3000 THEN '< 3K'
            WHEN Credit_Limit BETWEEN 3000 AND 5999 THEN '3K - 6K'
            WHEN Credit_Limit BETWEEN 6000 AND 9999 THEN '6K - 10K'
            WHEN Credit_Limit BETWEEN 10000 AND 14999 THEN '10K - 15K'
            WHEN Credit_Limit BETWEEN 15000 AND 19999 THEN '15K - 20K'
            ELSE '20K+'
        END AS Credit_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT
    Credit_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate
FROM CreditBins
GROUP BY Credit_Band
ORDER BY churn_rate DESC;


-- To show if churners have lower credit limits

SELECT AVG(Credit_Limit) AS Attrited_Customer_Credit_Limit
FROM CreditCardCustomers_clean 
WHERE Attrition_Flag = 'Attrited Customer';

-- To confirm if churners = low activity

SELECT AVG(Total_Trans_Ct) AS Attrited_Customer_Trans
FROM CreditCardCustomers_clean
WHERE Attrition_Flag = 'Attrited Customer';


-- 4.3 Transaction Behaviour

WITH TxnBins AS (
    SELECT
        CASE
            WHEN Total_Trans_Ct < 40 THEN '< 40'
            WHEN Total_Trans_Ct BETWEEN 40 AND 60 THEN '40 - 60'
            WHEN Total_Trans_Ct BETWEEN 61 AND 80 THEN '61 - 80'
            ELSE '80+'
        END AS Txn_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT
    Txn_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate
FROM TxnBins
GROUP BY Txn_Band
ORDER BY churn_rate DESC;
-- Txn_Band is simply a label (a “bin” or “segment”)
-- created for grouping customers based on their Total_Trans_Ct
-- Txn_Band = Transaction group


-- 4.4 Churn by Transaction Count
-- Total_Trans_Ct = Txn_Count_Band (band grouping)


WITH TxnCountBands AS (
    SELECT 
        CASE
            WHEN Total_Trans_Ct < 40 THEN '<40'
            WHEN Total_Trans_Ct BETWEEN 40 AND 60 THEN '40-60'
            WHEN Total_Trans_Ct BETWEEN 61 AND 80 THEN '61-80'
            ELSE '80+'
        END AS Txn_Count_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT 
    Txn_Count_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM TxnCountBands
GROUP BY Txn_Count_Band
ORDER BY churn_rate DESC;


-- 4.5 Churn by Transaction AMOUNT
-- create bands for Total_Trans_Amt = Txn_Amt_Band (grouping)

WITH TxnAmtBands AS (
    SELECT 
        CASE
            WHEN Total_Trans_Amt < 2500 THEN '<2500'
            WHEN Total_Trans_Amt BETWEEN 2500 AND 4000 THEN '2500-4000'
            WHEN Total_Trans_Amt BETWEEN 4001 AND 6000 THEN '4001-6000'
            ELSE '6000+'
        END AS Txn_Amt_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT 
    Txn_Amt_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM TxnAmtBands
GROUP BY Txn_Amt_Band
ORDER BY churn_rate DESC;


-- 4.5.1 Combined View (Count + Amount Together)
-- richer and wider analysis

SELECT
    Total_Trans_Ct,
    Total_Trans_Amt,
    Attrition_Flag
FROM CreditCardCustomers_clean
ORDER BY Total_Trans_Ct;


-- for grouped analysis

SELECT
    AVG(Total_Trans_Ct) AS avg_trans_count,
    AVG(Total_Trans_Amt) AS avg_trans_amount,
    Attrition_Flag
FROM CreditCardCustomers_clean
GROUP BY Attrition_Flag;


-- 4.6 Churn by Utilization Ratio

WITH UtilBands AS (
    SELECT
        CASE
            WHEN Avg_Utilization_Ratio < 0.10 THEN '0–10%'
            WHEN Avg_Utilization_Ratio < 0.30 THEN '10–30%'
            WHEN Avg_Utilization_Ratio < 0.60 THEN '30–60%'
            ELSE '60%+'
        END AS Util_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT
    Util_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) 
          / COUNT(*), 2) AS churn_rate
FROM UtilBands
GROUP BY Util_Band
ORDER BY Util_Band;


-- Relationship churn 
-- 5.1 Churn by Relationship Count (num of product subscribed)

SELECT
    Total_Relationship_Count AS relationship_count,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churn_count,
    ROUND(100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END)
          / COUNT(*), 2) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Total_Relationship_Count
ORDER BY relationship_count;


-- 5.2 Churn by Contact Frequency

WITH ContactBands AS (
    SELECT
        CASE
            WHEN Contacts_Count_12_mon = 0 THEN '0'
            WHEN Contacts_Count_12_mon = 1 THEN '1'
            WHEN Contacts_Count_12_mon = 2 THEN '2'
            WHEN Contacts_Count_12_mon = 3 THEN '3'
            ELSE '4+'
        END AS Contact_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT 
    Contact_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM ContactBands
GROUP BY Contact_Band
ORDER BY Contact_Band;


-- 5.3 Churn by Inactivity
-- To show does higher inactivity → higher churn?
-- Are customers becoming inactive BEFORE they churn?

WITH InactiveBands AS (
    SELECT 
        CASE
            WHEN Months_Inactive_12_mon = 0 THEN '0'
            WHEN Months_Inactive_12_mon = 1 THEN '1'
            WHEN Months_Inactive_12_mon = 2 THEN '2'
            WHEN Months_Inactive_12_mon = 3 THEN '3'
            WHEN Months_Inactive_12_mon = 4 THEN '4'
            ELSE '5+'
        END AS Inactive_Band,
        Attrition_Flag
    FROM CreditCardCustomers_clean
)
SELECT 
    Inactive_Band,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM InactiveBands
GROUP BY Inactive_Band
ORDER BY Inactive_Band;

-- Full Inactivity Churn Table

SELECT
    Months_Inactive_12_mon AS inactivity_months,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS churn_count,
    ROUND(
        100.0 * SUM(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate
FROM CreditCardCustomers_clean
GROUP BY Months_Inactive_12_mon
ORDER BY Months_Inactive_12_mon;

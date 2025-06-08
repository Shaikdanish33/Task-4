
-- Step 1: Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- Step 2: Drop existing table if it exists to start fresh
DROP TABLE IF EXISTS ecommerce_data;

-- Step 3: Create ecommerce_data table with InvoiceDate as VARCHAR initially
CREATE TABLE ecommerce_data (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate VARCHAR(50),  -- temporarily store raw date text
    UnitPrice DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(100)
);

-- Step 4: Load CSV data into the table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data.csv'
INTO TABLE ecommerce_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Step 5: Add a proper DATETIME column to convert InvoiceDate text
ALTER TABLE ecommerce_data ADD COLUMN InvoiceDateFormatted DATETIME;

-- Step 6: Convert InvoiceDate from VARCHAR to DATETIME format
UPDATE ecommerce_data
SET InvoiceDateFormatted = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i');

-- Optional Step 7 & 8: Drop old InvoiceDate column and rename new one
-- Uncomment these if you want to replace the original column
-- ALTER TABLE ecommerce_data DROP COLUMN InvoiceDate;
-- ALTER TABLE ecommerce_data CHANGE InvoiceDateFormatted InvoiceDate DATETIME;

-- Step 9: Create indexes for better performance on common query columns
CREATE INDEX idx_customer ON ecommerce_data(CustomerID);
CREATE INDEX idx_date ON ecommerce_data(InvoiceDateFormatted);

-- Step 10: Sample Queries to explore and analyze data

-- Show first 10 rows to verify import
SELECT * FROM ecommerce_data LIMIT 10;

-- Total number of transactions
SELECT COUNT(*) AS total_transactions FROM ecommerce_data;

-- Total revenue generated
SELECT ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue FROM ecommerce_data;

-- Revenue by country sorted descending
SELECT Country, ROUND(SUM(Quantity * UnitPrice), 2) AS revenue
FROM ecommerce_data
GROUP BY Country
ORDER BY revenue DESC;

-- Top 5 customers by total spending
SELECT CustomerID, ROUND(SUM(Quantity * UnitPrice), 2) AS total_spent
FROM ecommerce_data
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 5;

-- Sales aggregated by month (YYYY-MM format)
SELECT DATE_FORMAT(InvoiceDateFormatted, '%Y-%m') AS sale_month,
       ROUND(SUM(Quantity * UnitPrice), 2) AS monthly_revenue
FROM ecommerce_data
GROUP BY sale_month
ORDER BY sale_month;

-- Products with price above the average price
SELECT DISTINCT Description, UnitPrice
FROM ecommerce_data
WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM ecommerce_data);

-- Step 11: Create a reusable VIEW with cleaned transaction data
CREATE OR REPLACE VIEW v_clean_transactions AS
SELECT 
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    Quantity * UnitPrice AS total_value,
    InvoiceDateFormatted AS InvoiceDate,
    CustomerID,
    Country
FROM ecommerce_data
WHERE CustomerID IS NOT NULL;

-- Query the view to confirm
SELECT * FROM v_clean_transactions LIMIT 10;

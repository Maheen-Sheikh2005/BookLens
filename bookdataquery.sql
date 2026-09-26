-- ============================================================
-- PROJECT: Retail Bookstore Data Engineering & Analytics
-- AUTHOR: MAHEEN NISAR SHEIKH
-- DATABASE: PostgreSQL
-- ============================================================
DROP TABLE IF EXISTS stg_raw_books;

CREATE TABLE stg_raw_books (
    raw_json jsonb
);
-- 1. Create Category Dimension Table
CREATE TABLE Dim_Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);

-- 2. Create Rating Dimension Table
CREATE TABLE Dim_Rating (
    rating_id SERIAL PRIMARY KEY,
    rating_text VARCHAR(20) UNIQUE NOT NULL,
    rating_numeric INT NOT NULL
);
-- select * from Fact_Books;
-- Seed Rating Dimension mapping
INSERT INTO Dim_Rating (rating_text, rating_numeric) VALUES
('One', 1), ('Two', 2), ('Three', 3), ('Four', 4), ('Five', 5);

-- 3. Create Fact Table with Foreign Keys
CREATE TABLE Fact_Books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    price_gbp DECIMAL(10, 2) NOT NULL,
    in_stock BOOLEAN NOT NULL,
    category_id INT REFERENCES Dim_Category(category_id),
    rating_id INT REFERENCES Dim_Rating(rating_id)
);

-- 4. Populate Dim_Category dynamically from staging JSON
INSERT INTO Dim_Category (category_name)
SELECT DISTINCT value->>'Category'
FROM stg_raw_books, jsonb_array_elements(raw_json)
WHERE value->>'Category' IS NOT NULL
ON CONFLICT (category_name) DO NOTHING;


-- 5. Insert cleaned & transformed data into Fact_Books using JOINS
INSERT INTO Fact_Books (title, price_gbp, in_stock, category_id, rating_id)
SELECT 
    elem.value->>'Title' AS title,
    CAST(REGEXP_REPLACE(elem.value->>'Price', '[^0-9.]', '', 'g') AS DECIMAL(10,2)) AS price_gbp,
    CASE WHEN elem.value->>'Stock' LIKE '%In stock%' THEN TRUE ELSE FALSE END AS in_stock,
    c.category_id,
    r.rating_id
FROM stg_raw_books,
     jsonb_array_elements(raw_json) AS elem
JOIN Dim_Category c ON c.category_name = elem.value->>'Category'

JOIN Dim_Rating r ON r.rating_text = elem.value->>'Rating';


SELECT 
    b.book_id,
    b.title,
    b.price_gbp,
    c.category_name,
    r.rating_numeric AS star_rating
FROM Fact_Books b
JOIN Dim_Category c ON b.category_id = c.category_id
JOIN Dim_Rating r ON b.rating_id = r.rating_id;

-- TRUNCATE TABLE Fact_Books, Dim_Category RESTART IDENTITY;

-- ============================================================
--  EXECUTIVE BUSINESS ANALYTICS
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Category Revenue Potential & Price Extreme Mapping
-- ------------------------------------------------------------
WITH RankedBooks AS (
    SELECT 
        b.book_id,
        b.title,
        b.price_gbp,
        c.category_name,
        ROW_NUMBER() OVER(PARTITION BY c.category_id ORDER BY b.price_gbp DESC) AS desc_rank,
        ROW_NUMBER() OVER(PARTITION BY c.category_id ORDER BY b.price_gbp ASC) AS asc_rank
    FROM Fact_Books b
    JOIN Dim_Category c ON b.category_id = c.category_id
)
SELECT 
    category_name,
    COUNT(book_id) AS total_books,
    SUM(price_gbp) AS total_inventory_value,
    ROUND(AVG(price_gbp), 2) AS average_price,
    MAX(CASE WHEN desc_rank = 1 THEN title END) AS most_expensive_book,
    MAX(CASE WHEN desc_rank = 1 THEN price_gbp END) AS max_price,
    MAX(CASE WHEN asc_rank = 1 THEN title END) AS cheapest_book,
    MIN(CASE WHEN asc_rank = 1 THEN price_gbp END) AS min_price
FROM RankedBooks
GROUP BY category_name
HAVING COUNT(book_id) >= 3
ORDER BY total_inventory_value DESC;
-- ------------------------------------------------------------
WITH RankedBooks AS (
    SELECT 
        b.book_id,
        b.title,
        b.price_gbp,
        c.category_name,
        -- Rank highest price as 1
        ROW_NUMBER() OVER(PARTITION BY c.category_id ORDER BY b.price_gbp DESC) AS desc_rank,
        -- Rank lowest price as 1
        ROW_NUMBER() OVER(PARTITION BY c.category_id ORDER BY b.price_gbp ASC) AS asc_rank
    FROM Fact_Books b
    JOIN Dim_Category c ON b.category_id = c.category_id
)
SELECT 
    category_name,
    COUNT(book_id) AS total_books,
    SUM(price_gbp) AS total_inventory_value,
    ROUND(AVG(price_gbp), 2) AS average_price,
    
    -- Pick title of highest priced book (where desc_rank = 1)
    MAX(CASE WHEN desc_rank = 1 THEN title END) AS most_expensive_book,
    MAX(CASE WHEN desc_rank = 1 THEN price_gbp END) AS max_price,
    
    -- Pick title of lowest priced book (where asc_rank = 1)
    MAX(CASE WHEN asc_rank = 1 THEN title END) AS cheapest_book,
    MIN(CASE WHEN asc_rank = 1 THEN price_gbp END) AS min_price

FROM RankedBooks
GROUP BY category_name
HAVING COUNT(book_id) >= 3
ORDER BY total_inventory_value DESC;


-- ------------------------------------------------------------
-- Query 2: Premium Pricing vs. Low-Rating Outlier Detection
-- ------------------------------------------------------------
SELECT 
    b.title,
    c.category_name,
    b.price_gbp,
    r.rating_numeric,
    -- Dynamic baseline difference calculation
    ROUND(b.price_gbp - (SELECT AVG(price_gbp) FROM Fact_Books), 2) AS price_above_avg
FROM Fact_Books b
JOIN Dim_Category c ON b.category_id = c.category_id
JOIN Dim_Rating r ON b.rating_id = r.rating_id
WHERE r.rating_numeric <= 2 
  AND b.price_gbp > (SELECT AVG(price_gbp) FROM Fact_Books)
ORDER BY b.price_gbp DESC;

-- ------------------------------------------------------------
-- Query 3: Rating Distribution, Price Spread & Catalog Share
-- ------------------------------------------------------------
SELECT 
    r.rating_numeric,
    r.rating_text,
    COUNT(b.book_id) AS total_books,
    ROUND(AVG(b.price_gbp), 2) AS avg_price,
    MIN(b.price_gbp) AS min_price,
    MAX(b.price_gbp) AS max_price,
    -- Percentage Share of Total Store Catalog
    ROUND((COUNT(b.book_id) * 100.0) / (SELECT COUNT(*) FROM Fact_Books), 2) AS pct_of_total_catalog
FROM Fact_Books b
JOIN Dim_Rating r ON b.rating_id = r.rating_id
GROUP BY r.rating_numeric, r.rating_text
ORDER BY r.rating_numeric ASC;

-- Simulate out-of-stock items for testing operational logic
UPDATE Fact_Books 
SET in_stock = FALSE 
WHERE book_id % 6 = 0; -- Har 6th book ko out-of-stock mark kar dega (~16% of inventory)

-- ------------------------------------------------------------
-- Query 4: Inventory Risk & Stock Availability Analysis
-- ------------------------------------------------------------
SELECT 
    c.category_name,
    COUNT(b.book_id) AS total_books,
    
    -- In-Stock Count
    COUNT(CASE WHEN b.in_stock = TRUE THEN 1 END) AS in_stock_count,
    
    --  Subtraction Logic: Total Books - In-Stock Count
    COUNT(b.book_id) - COUNT(CASE WHEN b.in_stock = TRUE THEN 1 END) AS out_of_stock_count,
    
    -- Percentage In-Stock
    ROUND(
        (COUNT(CASE WHEN b.in_stock = TRUE THEN 1 END) * 100.0) / COUNT(b.book_id), 
        2
    ) AS in_stock_pct,
    
    -- Capital Locked in Available Stock (£)
    ROUND(SUM(CASE WHEN b.in_stock = TRUE THEN b.price_gbp ELSE 0 END), 2) AS available_inventory_value

FROM Fact_Books b
JOIN Dim_Category c ON b.category_id = c.category_id
GROUP BY c.category_name
HAVING COUNT(b.book_id) >= 3
ORDER BY available_inventory_value DESC;

-- ------------------------------------------------------------
-- Query 5: Category Revenue Leakage & Lost Sales Risk
-- ------------------------------------------------------------
SELECT 
    c.category_name,
    COUNT(b.book_id) AS total_books,
    -- Total potential value (Available + Lost)
    ROUND(SUM(b.price_gbp), 2) AS total_potential_value,
    
    -- Lost Revenue Value (Out of Stock Books)
    ROUND(SUM(CASE WHEN b.in_stock = FALSE THEN b.price_gbp ELSE 0 END), 2) AS lost_revenue_value,
    
    -- Revenue Leakage Percentage Share
    ROUND(
        (SUM(CASE WHEN b.in_stock = FALSE THEN b.price_gbp ELSE 0 END) * 100.0) / SUM(b.price_gbp), 
        2
    ) AS pct_revenue_leakage

FROM Fact_Books b
JOIN Dim_Category c ON b.category_id = c.category_id
GROUP BY c.category_name
HAVING SUM(CASE WHEN b.in_stock = FALSE THEN b.price_gbp ELSE 0 END) > 0
ORDER BY pct_revenue_leakage DESC;

-- ------------------------------------------------------------
-- Query 6: Category Price Volatility & Spread Analysis
-- ------------------------------------------------------------
SELECT 
    c.category_name,
    COUNT(b.book_id) AS total_books,
    MIN(b.price_gbp) AS min_price,
    MAX(b.price_gbp) AS max_price,
    -- Price Range / Spread Calculation
    ROUND(MAX(b.price_gbp) - MIN(b.price_gbp), 2) AS price_range,
    ROUND(AVG(b.price_gbp), 2) AS avg_price,
    -- Statistical Price Volatility (Standard Deviation)
    ROUND(COALESCE(STDDEV(b.price_gbp), 0), 2) AS price_stddev
FROM Fact_Books b
JOIN Dim_Category c ON b.category_id = c.category_id
GROUP BY c.category_name
HAVING COUNT(b.book_id) >= 3
ORDER BY price_stddev DESC;

-- ------------------------------------------------------------
-- Query 7: Executive Category Performance Scorecard
-- ------------------------------------------------------------
WITH CategoryStats AS (
    SELECT 
        c.category_name,
        COUNT(b.book_id) AS total_books,
        SUM(b.price_gbp) AS total_portfolio_value,
        COUNT(CASE WHEN b.in_stock = TRUE THEN 1 END) AS in_stock_count,
        SUM(CASE WHEN b.in_stock = FALSE THEN b.price_gbp ELSE 0 END) AS lost_revenue_value
    FROM Fact_Books b
    JOIN Dim_Category c ON b.category_id = c.category_id
    GROUP BY c.category_name
)
SELECT 
    category_name,
    total_books,
    ROUND(total_portfolio_value, 2) AS total_portfolio_value,
    ROUND((in_stock_count * 100.0) / total_books, 2) AS in_stock_pct,
    ROUND(lost_revenue_value, 2) AS lost_revenue_value,
    -- Window Function: Rank categories by financial commitment
    DENSE_RANK() OVER (ORDER BY total_portfolio_value DESC) AS category_capital_rank
FROM CategoryStats
ORDER BY category_capital_rank ASC;
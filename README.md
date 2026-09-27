# BookLens — Retail Bookstore Analytics

An end-to-end bookstore analytics project using Python web scraping, PostgreSQL JSONB, dimensional modelling, and SQL.

The project extracts book catalogue data from a dummy bookstore website, transforms semi-structured data into an analytical PostgreSQL model, and uses SQL to investigate pricing, ratings, catalogue value, and stock availability.

---

## 📌 Project Overview

**BookLens** demonstrates a complete data analytics workflow starting from raw web data and ending with business-oriented SQL analysis.

Instead of using a ready-made CSV dataset, the project begins with data extraction from **Books to Scrape**, a dummy website created for web-scraping practice.

### Workflow

```text
Books to Scrape
      ↓
Python Web Scraping
(Requests + BeautifulSoup)
      ↓
Raw JSON
      ↓
PostgreSQL JSONB Staging
      ↓
Data Transformation
      ↓
Dimensional Model
      ↓
SQL Analytics
      ↓
Business Insights
```

---

## 🎯 Objectives

The project was developed to:

* Extract structured data from a web source using Python.
* Store the extracted records as JSON.
* Load semi-structured data into PostgreSQL.
* Transform JSON fields into appropriate analytical data types.
* Build a simple relational/dimensional data model.
* Use PostgreSQL to answer business-oriented analytical questions.
* Apply advanced SQL concepts such as CTEs, window functions, JSONB functions, aggregations, joins, and statistical functions.

---

## 🛠️ Tech Stack

| Technology        | Purpose                                 |
| ----------------- | --------------------------------------- |
| **Python**        | Web data extraction                     |
| **Requests**      | HTTP requests                           |
| **BeautifulSoup** | HTML parsing                            |
| **JSON**          | Raw/intermediate data storage           |
| **PostgreSQL**    | Data storage, transformation & analysis |
| **SQL**           | Data modelling and analytics            |
| **GitHub**        | Version control & documentation         |

---

## 🌐 Data Source

The project uses **Books to Scrape**, a dummy bookstore website.

The extracted attributes include:

* Book title
* Price
* Category
* Rating
* Stock availability

The source is catalogue data rather than transactional data. Therefore, this project does **not** calculate actual sales revenue, profit, customer behaviour, or units sold.

---

## 🐍 Data Extraction

The `extract_data.py` script uses **Requests** and **BeautifulSoup** to retrieve and parse the bookstore's HTML pages.

The extracted records are structured as Python objects and stored in:

```text
raw_books.json
```

The JSON file acts as the raw-data layer before the data enters PostgreSQL.

---

## 🗄️ PostgreSQL Data Pipeline

The raw JSON is loaded into PostgreSQL through `db_loader.py`.

A staging table stores the raw data using PostgreSQL's `JSONB` data type.

The data is then transformed into a simple dimensional model consisting of:

```text
Dim_Category
Dim_Rating
Fact_Books
```

### Data transformations include:

* Extracting fields from JSONB
* Converting formatted price text into `DECIMAL`
* Converting stock text into Boolean values
* Mapping textual ratings to numeric ratings
* Creating category and rating dimensions
* Connecting the fact and dimension tables using keys

---

## 📊 SQL Analysis

The project contains seven analytical queries.

### Query 1 — Category Catalogue & Price Analysis

Analyses each category using:

* Book count
* Total listed catalogue value
* Average price
* Highest-priced book
* Lowest-priced book

**SQL concepts:** CTEs, aggregation, `ROW_NUMBER()`, `PARTITION BY`.

### Query 2 — High-Priced, Low-Rated Books

Identifies books with ratings of two stars or below whose prices are above the overall catalogue average.

**SQL concepts:** subqueries, aggregation, filtering and derived metrics.

### Query 3 — Rating Distribution

Analyses the number and percentage of books at each rating level.

**SQL concepts:** `GROUP BY`, `COUNT()` and percentage calculations.

### Query 4 — Stock Availability Analysis

Analyses in-stock and unavailable books and calculates catalogue availability metrics.

A controlled stock-availability scenario is used for analytical purposes rather than representing historical inventory records.

### Query 5 — Category Availability Gap

Measures the listed-price value associated with unavailable books by category.

Because the dataset does not contain transaction data, this represents **unavailable listed value**, not confirmed lost revenue.

### Query 6 — Category Price Variability

Analyses price distribution within each category using:

* Minimum price
* Maximum price
* Average price
* Price range
* Standard deviation

**SQL concepts:** statistical functions and aggregation.

### Query 7 — Category Portfolio Scorecard

Combines category-level metrics such as:

* Book count
* Total listed value
* Stock availability
* Unavailable listed value

and uses `DENSE_RANK()` to rank categories by portfolio value.

**SQL concepts:** CTEs, multiple joins, conditional aggregation and window functions.

---

## 🔍 Key Analytical Areas

The project explores four main areas:

**Catalogue**
How books and catalogue value are distributed across categories.

**Pricing**
How prices differ between categories and individual books.

**Ratings**
How the catalogue is distributed across rating levels and how ratings relate to price.

**Availability**
How stock availability can be analysed at both catalogue and category levels.

---

## ⚠️ Assumptions & Limitations

* The source is a dummy practice website rather than a production retail system.
* The dataset does not contain orders, customers, units sold or transaction dates.
* Listed price should not be interpreted as actual revenue.
* The stockout analysis uses a controlled scenario for analytical demonstration.
* Therefore, availability-related value represents listed catalogue value rather than confirmed financial loss.

These limitations are explicitly considered when interpreting the results.

---

## 🤖 AI-Assisted Development

AI tools were used to assist with understanding and developing parts of the web-extraction implementation.

The project was reviewed and adapted during development, with the data model, transformations, SQL analysis, assumptions, and interpretation treated as part of the project work.

This also reflects the practical use of AI tools as a development aid in a modern data workflow.

---

## 📁 Repository Structure

```text
BookLens/
│
├── README.md
├── extract_data.py
├── db_loader.py
├── bookdataquery.sql
├── raw_books.json
│
└── query_results/
    ├── Query_1.csv
    ├── Query_2.csv
    ├── Query_3.csv
    ├── Query_4.csv
    ├── Query_5.csv
    ├── Query_6.csv
    └── Query_7.csv
```

---

## 🚀 Future Improvements

Potential extensions include:

* Power BI dashboard
* Historical price and stock tracking
* Transaction-level data
* Sales and revenue analysis
* Customer-level analysis
* Automated data-quality checks
* Automated data refresh

---

## 👤 Author

**Maheen Sheikh**

Data Analyst | SQL | PostgreSQL | Python | Excel | Power BI

[GitHub](https://github.com/Maheen-Sheikh2005) · [LinkedIn](https://www.linkedin.com/in/maheensheikh/)

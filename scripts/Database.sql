-- Creating the database schema
CREATE DATABASE IF NOT EXISTS wealth_management_dss;
USE wealth_management_dss;

-- Dropping table if it exists to avoid errors.
DROP TABLE IF EXISTS investment_universe;

-- Creating the table matching the Pandas DataFrame structure (23 columns)
CREATE TABLE investment_universe (
    -- PRIMARY KEY
    symbol VARCHAR(10) NOT NULL,
    
    -- TEXT FIELDS
    company_name VARCHAR(255),
    sector VARCHAR(100),
    industry VARCHAR(100),
    
    -- FINANCIAL METRICS (Decimal for precision)
    current_price DECIMAL(10, 2),
    pe_ratio DECIMAL(10, 2), -- Price/Earnings
    dividend_yield DECIMAL(10, 4),
    earnings_per_share DECIMAL(10, 2),
    week_52_high DECIMAL(10, 2),
    week_52_low DECIMAL(10, 2),
    market_cap BIGINT, -- Market Cap is too large for INT
    ebitda BIGINT,
    price_to_sales DECIMAL(10, 4),
    price_to_book DECIMAL(10, 2),
    
    -- ESG METRICS (Float/Decimal)
    total_esg_risk DECIMAL(5, 2),
    environment_risk DECIMAL(5, 2),
    governance_risk DECIMAL(5, 2),
    social_risk DECIMAL(5, 2),
    
    -- ESG CATEGORICAL/ORDINAL
    controversy_level VARCHAR(50),
    controversy_score DECIMAL(3, 1),
    esg_risk_percentile DECIMAL(5, 2),
    esg_risk_level VARCHAR(50),
    
    -- PROPRIETARY DATA
    proprietary_score INT,

    PRIMARY KEY (symbol)
);

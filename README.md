Financial Analytics Dashboard (Pytho + MySQL + Power BI)

This is a prototype for merging financial data with ESG metrics.

**Project Overview**

This project serves as a functional prototype and template for building a financial decision support system. It demonstrates how to move beyond static Excel reporting by building a full-stack data pipeline using Python, SQL, and Power BI.

The use case focuses on "Dual-Mandate Investing" screening S&P 500 stocks based on both financial value (P/E Ratio, Dividends) and ethical alignment (ESG Risk Scores). However, the architecture is agnostic and can be adapted for any domain requiring data integration and interactive reporting.

**The Architecture (How it Works)**

Instead of just dragging a CSV into a visualization tool, this project simulates a scalable data environment:

**1) Storage Layer (MySQL):** We first need to create a database, set the primary and foreign keys in order to make sure the data is loaded there. When the data is loaded into a relational database, we make sure to pay attention to the data types and schema integrity. 

<details>
<summary><b>Click to view the DB query</b></summary>

```SQL

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

```

</details>

**2) ETL Layer (Python):** Scripts extract raw data, clean inconsistent formatting (e.g., fixing inverted 52-week high/low columns), and simulate proprietary analyst scores.

<details>
<summary><b>Click to view the full ETL Python Script</b></summary>

```python

import pandas as pd
import numpy as np

# Extraction process
try:
    df_financials = pd.read_csv(r"C:\Users\your_user\your_folder\constituents-financials_csv.csv")
    df_esg = pd.read_csv(r"C:\Users\your_user\your_folder\SP 500 ESG Risk Ratings.csv")
except FileNotFoundError as e:
    print(f"Error: {e}")
    exit()

# Analysis of Financials (df_financials)
print("Analysis: Financials (df_financials)")
print("\n Info Schema and Data Types:")
df_financials.info()
print("\n Head Sample Data:")
print(df_financials.head())

# Statistical summary of numeric columns
print("\n Numeric Statistics:")
print(df_financials.describe())


# Analysis of ESG (df_esg)
print("Analysis: ESG (df_esg)")
print("\n Info Schema and Data Types:")
df_esg.info()
print("\n Head Sample Data:")
print(df_esg.head())

# checking text-based columns we need to clean
print("\n Unique 'Controversy Level' values:")
print(df_esg['Controversy Level'].unique())

print("\n Unique 'ESG Risk Percentile' values (first 10):")
print(df_esg['ESG Risk Percentile'].unique()[:10])

print("\nFinancials Nulls:")
print(df_financials.isna().sum())

print("\nESG Nulls:")
print(df_esg.isna().sum())


print("Simulating Proprietary Data")

# We are going to use symbols from the financials file to ensure a perfect match
symbols = df_financials['Symbol'].unique()

# Let's now generate a random "Proprietary Values Score" between 40 and 100
np.random.seed(42) # Use a seed for consistent, repeatable results
prop_scores = np.random.randint(40, 101, size=len(symbols))

# Simulate Proprietary Data (df_proprietary)

df_proprietary = pd.DataFrame({'Symbol': symbols, 'Proprietary Values Score': prop_scores})

print(f"Simulated {len(df_proprietary)} proprietary scores.")
print("Verifying head of simulated data:")
print(df_proprietary.head())

# Transformation (this process applies to this particular dataset.

print("Transforming Data (based on analysis)")

# T1: Fix inverted '52 Week Low' and '52 Week High' in df_financials
print("T1: Fixing inverted 52-week columns...")
df_financials.rename(columns={
    '52 Week Low': 'temp_high',
    '52 Week High': '52 Week Low'
}, inplace=True)
df_financials.rename(columns={
    'temp_high': '52 Week High'
}, inplace=True)

# T2: Handleling 'Price/Earnings' and convert to numeric
# Ensuring the 2 nulls from Block 5 are handled correctly
print("T2: Cleaning 'Price/Earnings'...")
df_financials['Price/Earnings'] = pd.to_numeric(df_financials['Price/Earnings'], errors='coerce')

# T3: Cleanning 'Controversy Level' strings in df_esg
print("T3: Cleaning 'Controversy Level'...")
df_esg['Controversy Level'] = df_esg['Controversy Level'].astype(str).str.replace(' Controversy Level', '').str.strip()

# T4: Cleanning 'ESG Risk Percentile' strings in df_esg
print("T4: Cleaning 'ESG Risk Percentile'...")
# Use regex to extract only the digits, then convert to float
df_esg['ESG Risk Percentile'] = df_esg['ESG Risk Percentile'].astype(str).str.extract(r'(\d+)').astype(float)

# T5: Field Selection (Dropping unnecessary columns)
print("T5: Dropping unneeded and redundant columns...")
# Dropping from financials:
df_financials = df_financials.drop(columns=['SEC Filings'])

# Dropping from ESG (keeping 'Industry' as we discussed):
df_esg = df_esg.drop(columns=[
    'Name',                 # Redundant with financials
    'Address',              # Useless for KPIs
    'Sector',               # Redundant with financials
    'Full Time Employees',  # Useless for KPIs
    'Description'           # Useless for KPIs
])

print("\nTransformation complete.")
print(f"VERIFY: df_financials columns: {list(df_financials.columns)}")
print(f"VERIFY: df_esg columns: {list(df_esg.columns)}")

# Verification

print("--- Verifying Transformations ---")

print("\nFinancials Numeric Stats (Post-Transform):")
# This check proves the 52-week columns are fixed.
# The mean High should now be > mean Low.
print(df_financials[['52 Week Low', '52 Week High']].describe())

print("\nFinancials Info (Post-Transform):")
# This check proves 'Price/Earnings' is now float64
df_financials.info()

print("\nESG Unique Values (Post-Transform):")
# This check proves 'Controversy Level' is clean
print(df_esg['Controversy Level'].unique())

print("\nESG Head (Post-Transform):")
# This check proves 'ESG Risk Percentile' is now a number (float64)
# and that 'Industry' was kept.
print(df_esg.head())

# Load (Merge)

print("--- Step 4: Loading (Merging) Data ---")

# L1: We will merge Financials (base) with ESG data
# Using a LEFT JOIN to keep all 505 financial records
print("Merging Financials and ESG data (LEFT JOIN)...")
df_merged = pd.merge(df_financials, df_esg, on='Symbol', how='left')

# L2: Then we will merge the result with Proprietary data
# Using a LEFT JOIN again to keep all 505 records
print("Merging result with Proprietary data (LEFT JOIN)...")
df_final = pd.merge(df_merged, df_proprietary, on='Symbol', how='left')

print(f"Merge complete. Final dataframe has {len(df_final)} rows.")
print("--- Verifying head of final merged data ---")
print(df_final.head())

# Final Analysis (with the merged data)

print("--- Final Analysis of Merged Data ---")

print("\nFinal Schema and Data Types:")
df_final.info()

print("\nFinal Null Counts (Post-Merge):")
print(df_final.isna().sum())

# Saving output files (first test of the results, not the final process).

print("Saving Output Files")
df_final.to_csv("C:\\Users\\your_user\\your_folder\\pdss_unified_dataset.csv", index=False)

# Saving the 100-record sample for the assignment submission
df_final.head(100).to_csv("C:\\Users\\angom\\East Tennessee State University\\DSS Wealth Management Firm - Documents\\Processed Data\\pdss_data_sample.csv", index=False)
print("\nSuccessfully created 'pdss_unified_dataset.csv' and 'pdss_data_sample.csv'")
print("--- ETL Process Complete ---")

# Loading to MySQL

from sqlalchemy import create_engine

# Database Connection Configuration
db_user = 'root'
db_password = 'your_password'
db_host = 'localhost'
db_port = '3306'
db_name = 'wealth_management_dss'

# Creating SQLAlchemy Engine
connection_str = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
engine = create_engine(connection_str)

print("Loading Data into MySQL Database")

# We need to rename columns to match the SQL Schema format (removing spaces/slashes)
df_sql = df_final.copy()
df_sql.columns = [
    'symbol', 'company_name', 'sector', 'current_price', 'pe_ratio', 
    'dividend_yield', 'earnings_per_share', 'week_52_high', 'week_52_low', 
    'market_cap', 'ebitda', 'price_to_sales', 'price_to_book', 'industry', 
    'total_esg_risk', 'environment_risk', 'governance_risk', 'social_risk', 
    'controversy_level', 'controversy_score', 'esg_risk_percentile', 
    'esg_risk_level', 'proprietary_score'
]

try:
    # Writting data to MySQL
    # if_exists='replace' will drop the table and recreate it every time we run the ETL
    # if_exists='append' would add duplicates if we aren't careful
    df_sql.to_sql('investment_universe', con=engine, if_exists='replace', index=False)
    print(f"Success: {len(df_sql)} rows loaded into table 'investment_universe'.")
except Exception as e:
    print(f"Error writing to database: {e}")

```
</details>

**3) Semantic Layer (Power BI):** The dashboard connects via Import Mode, allowing the final report to be a self-contained, high-performance artifact that doesn't require the end-user to have database access.


    A [Raw Data Sources] -->|Pandas Clean & Transform| B(Python ETL)
    B -->|SQLAlchemy| C[(MySQL Database)]
    C -->|Import Mode| D[Power BI Dashboard]


*image of connection*

**Dashboard Views**

**1. Desktop Experience**
   
The dashboard features a custom "Financial Terminal" design system, branded under the identity of "Apex Private Capital". It utilizes a high-contrast white and blue theme optimized for clarity and high-density information display.

Page 1 - Investment Screener: This page serves as the primary filtering engine for the investment universe.

Key Features:

Top KPI Ribbon: Displays high-level metrics such as total companies (505), industries (106), sectors (11), and the average P/E ratio (24.81) of the current selection.

Valuation Gauge: A "P/E Benchmark Analysis" gauge that visualizes the current portfolio's average P/E against the firm's target limit of 25.

Risk Distribution: A "Portfolio Yield" donut chart that breaks down the selected companies by their ESG Risk Level (Low, Medium, High, Severe).

Detailed Data Grid: A tabular view of individual tickers with conditional formatting (red text) highlighting companies that exceed valuation thresholds.

Page 2 - Risk vs. Reward: This page provides a visual trade-off analysis between financial value and ethical risk.

Key Features:

Scatter Plot Matrix: The "Risk-Adjusted Opportunity Map" plots the Average P/E Ratio (X-Axis) against the Average Total ESG Risk (Y-Axis).

Quadrant Analysis: Automated reference lines (Max P/E: 25.00, High ESG Risk: 30.00) divide the chart into four actionable zones. The bottom-left quadrant represents the ideal "investable" zone (Low Cost, Low Risk).

Cluster Identification: Bubbles are color-coded by Sector and sized by Market Cap, allowing for instant identification of sector-specific risk clusters.

Page 3 - Financial Detail View: This page offers a deep fundamental analysis of capital allocation and market valuation.

Key Features:

Correlation Analysis: A scatter plot comparing "PE Ratio vs. Price to Book" to identify deep-value opportunities (low earnings multiples combined with low book value multiples).

Capital Decomposition: A "Market Cap by Sector" funnel chart that visualizes the distribution of capital across the S&P 500, clearly showing the dominance of Information Technology.

Hierarchical Breakdown: A decomposition tree allows users to drill down from Total Market Cap into specific Sectors, Industries, and individual Companies to see exactly where value is concentrated.

Fundamental Heatmap: A matrix table comparing average P/E, Price-to-Book, Dividend Yield, and EPS across sectors, using conditional formatting (green/red backgrounds) to highlight undervalued and overvalued sectors.

**2. Mobile Experience**

The report includes a fully optimized Mobile Layout for on-the-go decision making. The navigation and visuals were reflowed to fit vertical screens without losing data fidelity.

<p float="left">
<img src="image_4c7d3f.png" width="300" />
<img src="image_4c7d78.png" width="300" />
<img src="image_4c7d9a.png" width="300" />
</p>

**Technical Implementation Details**

Data Transformation (Python)

We encountered real-world dirty data. The Python scripts handle:

Regex Parsing: Stripping verbose text (e.g., "Severe Controversy Level" $\to$ "Severe").

Logic Correction: Algorithmic swapping of columns where Low values were greater than High values.

Data Simulation: Generating "Proprietary Scores" to test how internal data merges with public market data.

DAX Measures

1. ESG Display:
   
```
ESG Display = 
VAR Score = SELECTEDVALUE('wealth_management_dss investment_universe'[total_esg_risk])
RETURN
IF(ISBLANK(Score), "Not Rated", FORMAT(Score, "0.0"))
```

2.Formatting PE Color:
```
   Formatting PE Color = 
VAR CurrentPE = SELECTEDVALUE('wealth_management_dss investment_universe'[pe_ratio])
VAR SectorAvg = [Sector Avg PE]
RETURN
IF(
    NOT(ISBLANK(CurrentPE)) && CurrentPE > SectorAvg, 
    "#FF0000", -- Red Hex Code
    "#FFFFFF"  -- Black Hex Code
)
```

3. Is Investable:
```
 Is Investable = 
VAR MaxPE = 25
VAR SectorAvg = [Sector Avg PE]
VAR CurrentPE = SELECTEDVALUE('wealth_management_dss investment_universe'[pe_ratio])

RETURN 
IF(
    (CurrentPE < MaxPE || CurrentPE <= SectorAvg) && 
    NOT(ISBLANK(CurrentPE)), 
    1, 
    0
)
```

4. Max PE Ratio:
```
Max_PE_Ratio = 50
```

5. Target PE Ratio:
```
Target_PE_Ratio = 25
```

5. Sector AVG PE:
```
Sector Avg PE = 
CALCULATE(
    AVERAGE('wealth_management_dss investment_universe'[pe_ratio]),
    ALLEXCEPT('wealth_management_dss investment_universe', 'wealth_management_dss investment_universe'[sector])
)
```

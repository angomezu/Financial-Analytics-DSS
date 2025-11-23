Financial Analytics Dashboard (Pytho + MySQL + Power BI)

This is a prototype for merging financial data with ESG metrics.

**Project Overview**

This project serves as a functional prototype and template for building a financial decision support system. It demonstrates how to move beyond static Excel reporting by building a full-stack data pipeline using Python, SQL, and Power BI.

The use case focuses on "Dual-Mandate Investing" screening S&P 500 stocks based on both financial value (P/E Ratio, Dividends) and ethical alignment (ESG Risk Scores). However, the architecture is agnostic and can be adapted for any domain requiring data integration and interactive reporting.

**The Architecture (How it Works)**

Instead of just dragging a CSV into a visualization tool, this project simulates a scalable data environment:

ETL Layer (Python): Scripts extract raw data, clean inconsistent formatting (e.g., fixing inverted 52-week high/low columns), and simulate proprietary analyst scores.

<details>
<summary><b>Click to view the full ETL Python Script</b></summary>

import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import sys

# --- STEP 1: EXTRACT ---
print("Extraction")
try:
    # Update paths to your local environment
    base_path = r"C:\Users\youruser\DSS Wealth Management Firm - Documents\Raw Data"
    
    df_financials = pd.read_csv(f"{base_path}\\constituents-financials_csv.csv")
    df_esg = pd.read_csv(f"{base_path}\\SP 500 ESG Risk Ratings.csv")
    print("Extraction successful.")
except FileNotFoundError as e:
    print(f"Error: {e}")
    sys.exit()

# --- STEP 2: SIMULATE PROPRIETARY DATA ---
print("Simulating Internal Data")
symbols = df_financials['Symbol'].unique()
np.random.seed(42) # Deterministic seed
prop_scores = np.random.randint(40, 101, size=len(symbols))
df_proprietary = pd.DataFrame({'Symbol': symbols, 'Proprietary Values Score': prop_scores})
print(f"Simulated {len(df_proprietary)} proprietary scores.")

# --- STEP 3: TRANSFORM (in this case we onyl detected---
print("Transformation")

# T1: Fix inverted 52-week columns
df_financials.rename(columns={
    '52 Week Low': 'temp_high',
    '52 Week High': '52 Week Low'
}, inplace=True)
df_financials.rename(columns={'temp_high': '52 Week High'}, inplace=True)

# T2: Clean Price/Earnings
df_financials['Price/Earnings'] = pd.to_numeric(df_financials['Price/Earnings'], errors='coerce')

# T3: Clean Controversy Level
df_esg['Controversy Level'] = df_esg['Controversy Level'].astype(str).str.replace(' Controversy Level', '').str.strip()

# T4: Clean ESG Risk Percentile
df_esg['ESG Risk Percentile'] = df_esg['ESG Risk Percentile'].astype(str).str.extract(r'(\d+)').astype(float)

# T5: Drop Redundant/Useless Columns
df_financials = df_financials.drop(columns=['SEC Filings'])
df_esg = df_esg.drop(columns=[
    'Name', 'Address', 'Sector', 'Full Time Employees', 'Description'
])

# --- STEP 4: MERGE ---
print("--- Step 4: Merging ---")
df_merged = pd.merge(df_financials, df_esg, on='Symbol', how='left')
df_final = pd.merge(df_merged, df_proprietary, on='Symbol', how='left')
print(f"Merge complete. Final dataset shape: {df_final.shape}")

# --- STEP 5: LOAD TO DATABASE (MySQL) ---
print("--- Step 5a: Loading to MySQL ---")

# Database Configuration
# NOTE: Use environment variables in production
DB_USER = 'root'
DB_PASSWORD = 'your_password' 
DB_HOST = 'localhost'
DB_PORT = '3306'
DB_NAME = 'wealth_management_dss'

connection_str = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

try:
    engine = create_engine(connection_str)
    
    # Prepare DataFrame for SQL (snake_case columns)
    df_sql = df_final.copy()
    df_sql.columns = [
        'symbol', 'company_name', 'sector', 'current_price', 'pe_ratio', 
        'dividend_yield', 'earnings_per_share', 'week_52_high', 'week_52_low', 
        'market_cap', 'ebitda', 'price_to_sales', 'price_to_book', 'industry', 
        'total_esg_risk', 'environment_risk', 'governance_risk', 'social_risk', 
        'controversy_level', 'controversy_score', 'esg_risk_percentile', 
        'esg_risk_level', 'proprietary_score'
    ]
    
    df_sql.to_sql('investment_universe', con=engine, if_exists='replace', index=False)
    print(f"Success: {len(df_sql)} rows loaded into MySQL table 'investment_universe'.")

except Exception as e:
    print(f"Database Error: {e}")

print("--- ETL Process Complete ---")


</details>



Storage Layer (MySQL): Data is loaded into a relational database to enforce data types and schema integrity.

Semantic Layer (Power BI): The dashboard connects via Import Mode, allowing the final report to be a self-contained, high-performance artifact that doesn't require the end-user to have database access.

graph LR
    A [Raw Data Sources] -->|Pandas Clean & Transform| B(Python ETL)
    B -->|SQLAlchemy| C[(MySQL Database)]
    C -->|Import Mode| D[Power BI Dashboard]


**Dashboard Views**

1. Desktop Experience

The dashboard features a custom "Financial Terminal" design system (white/blue theme) focused on high-density information.

The Screener: A funnel to filter the 500+ companies down to a viable shortlist using dynamic benchmarks.

Risk Matrix: A scatter plot visualizing the trade-off between Financial Reward (X-Axis) and Ethical Risk (Y-Axis).

Deep Dive: Hierarchical decomposition trees and funnel charts for fundamental analysis.

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

Example: Dynamic Benchmarking
This measure calculates the average P/E ratio of a sector ignoring the user's specific company selection, allowing for relative comparison.

Sector Avg PE = 
CALCULATE(
    AVERAGE('investment_universe'[pe_ratio]),
    ALLEXCEPT('investment_universe', 'investment_universe'[sector])
)

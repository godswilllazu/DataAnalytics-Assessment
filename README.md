# DataAnalytics-Assessment

# QUESTION 1 
This query is designed to extract insights on customers who have both **savings** and **investment** accounts, specifically:
- The number of savings and investment accounts per user
- The total amount deposited by each user
- Only users with at least one savings and one investment account are included
- Results are sorted in descending order of total deposits

---

## Query Breakdown

### 1. Selecting Key Fields
```sql
SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
```
- Retrieves the unique identifier (`id`) and full name of each user from the `users_customuser` table.

---

### 2. Counting Savings and Investment Accounts
```sql
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) AS savings_count,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) AS investment_count,
```
- Uses conditional aggregation to count the number of distinct **savings** and **investment** accounts each customer has.
- `is_regular_savings = 1` identifies a savings plan.
- `is_a_fund = 1` identifies an investment plan.

---

### 3. Summing Total Deposits
```sql
    SUM(p.amount/100) AS total_deposit
```
- Computes the total amount deposited by the customer across all plans.
- The `amount` is assumed to be in **kobo**, not naira, so i converted to naira by dividing by 100 

---

### 4. Table Joins
```sql
FROM users_customuser u
JOIN savings_savingsaccount s ON u.id = s.owner_id
JOIN plans_plan p ON s.plan_id = p.id
```
- Joins the `users_customuser`, `savings_savingsaccount`, and `plans_plan` tables using appropriate foreign keys.

---

### 5. Filtering Criteria
```sql
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) > 0
    AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) > 0
```
- Ensures only customers who have **both a funded savings plan and a funded investment plan** are returned.

---

### 6. Sorting the Output
```sql
ORDER BY total_deposit DESC;
```
- Sorts the resulting records by **total deposits**, highest first.

---

## Challenges Faced

- **Ambiguous joins**: Ensuring the joins between `users_customuser`, `savings_savingsaccount`, and `plans_plan` correctly matched user-to-plan relationships. This was resolved by closely following foreign key mappings (`owner_id`, `plan_id`).
- **Duplicate counts**: Initially encountered overcounting due to repeated rows. This was fixed using `COUNT(DISTINCT s.id)` to count unique savings accounts per condition.
- **Currency granularity**: The `amount` field is stored in kobo, which might cause confusion if not clarified during reporting. A note was added to indicate the units.

---
---
# QUESTION 2
This SQL script segments customers into transaction frequency categories—High, Medium, and Low—based on their average number of monthly transactions. It uses a multi-step CTE (Common Table Expression) approach for clarity and modular processing.

---

## Query Breakdown

### 1. Monthly Transaction Count Per Customer
```sql
WITH customer_monthly_tx AS (
    SELECT
        s.owner_id,  -- ID of the customer who made the transaction
        YEAR(s.transaction_date) AS year,   -- Year of the transaction
        MONTH(s.transaction_date) AS month, -- Month of the transaction
        COUNT(*) AS monthly_tx_count        -- Number of transactions in that month
    FROM 
        savings_savingsaccount s
    GROUP BY 
        s.owner_id, YEAR(s.transaction_date), MONTH(s.transaction_date)  -- Group by customer and month
),

```
- Calculate the total number of transactions each customer makes every month.

- Extracts YEAR and MONTH from the transaction_date

- Groups data by owner_id, year, and month

- Uses COUNT(*) to get the monthly transaction count

---
### 2. Average Monthly Transactions Per Customer
```sql
customer_avg_tx AS (
    SELECT
        owner_id,
        AVG(monthly_tx_count) AS avg_tx_per_month  -- Average monthly transaction frequency
    FROM 
        customer_monthly_tx
    GROUP BY 
        owner_id
),
```
- Compute the average number of transactions per month for each customer using the result of Step 1.

- Aggregates monthly counts using AVG(monthly_tx_count)

---

### 3: Categorize Customers by Frequency
```sql
categorized_customers AS (
    SELECT 
        owner_id,
        avg_tx_per_month,
        CASE 
            WHEN avg_tx_per_month >= 10 THEN 'High Frequency'        -- 10 or more transactions/month
            WHEN avg_tx_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency' -- Between 3 and 9
            ELSE 'Low Frequency'                                     -- 2 or fewer
        END AS frequency_category
    FROM 
        customer_avg_tx
)
```
This bit of code groups customers based on how often they make transactions each month. It looks at their average monthly transactions and then sorts them into three buckets:
- If they do 10 or more transactions a month, they’re tagged as High Frequency customers.

- If they do between 3 and 9, they get called Medium Frequency.

- And if it’s fewer than 3, they’re Low Frequency.

### 4: Aggregate Results
```sql
SELECT 
    frequency_category,                       -- Frequency segment
    COUNT(*) AS customer_count,               -- Number of customers in each category
    ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month  -- Average monthly tx for category
FROM 
    categorized_customers
GROUP BY 
    frequency_category
ORDER BY 
    customer_count DESC;
```
This query provides a summary of customer segments based on transaction frequency. It groups customers into three categories — High, Medium, and Low Frequency — and calculates key metrics for each group:

- The number of customers in each frequency category.

- The average number of transactions per month within each group, rounded to one decimal place.

- The results are then ordered by the number of customers in descending order, allowing us to quickly identify which segment contains the largest portion of our user base and understand their average activity level. This summary can be useful for tailoring engagement strategies or prioritizing customer support efforts based on user behavior..

🧱 Challenges & Resolutions
`
- Handling Date Granularity
  Challenge: Extracting meaningful time segments (monthly) from raw transaction_date.
  
  Solution: Used YEAR() and MONTH() SQL functions to ensure clean aggregation.

- Choosing Categorization Thresholds
Challenge: Setting logical and interpretable ranges for frequency categories.

  Solution:
  
  Used practical thresholds based on common monthly behaviors.
  
  Verified categorization logic with sample data.

- Chaining CTEs Effectively
  Challenge: Maintaining readability and minimizing nested subqueries.

Solution: Broke down the logic into modular, well-named CTE blocks to ensure clarity and ease of debugging.

# Question 3
---

### Select Key Details:
```sql

SELECT
    p.id AS plan_id,                  -- Unique identifier for the plan
    s.owner_id,                       -- Customer ID (owner of the account)

    -- Determine the account type based on the plan configuration
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'     -- If regular savings, label as 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'           -- If it's a fund, label as 'Investment'
    END AS type,
```
- plan_id: The unique ID of the account plan.

- owner_id: The ID of the customer who owns the account.

- type: A label indicating whether the account is a "Savings" or "Investment" plan. This is determined by checking the account configuration flags:

- If is_regular_savings = 1, it's labeled as "Savings".

- If is_a_fund = 1, it's labeled as "Investment".

### Activity Metrics:

```sql
MAX(s.transaction_date) AS last_transaction_date,    -- The most recent transaction date for the account
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days  -- Number of days since last transaction

```
- last_transaction_date: The most recent transaction made on the account.

- inactivity_days: The number of days since the last transaction, calculated as the difference between today's date (CURDATE()) and the last_transaction_date.
  
 ### Filters:
```sql
WHERE 
    s.new_balance > 0                 -- Only include accounts that are currently active (non-zero balance)
    AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)  -- Include only Savings or Investment plans (ignore others)
```
- Only includes accounts that currently have a non-zero balance (new_balance > 0).

- Filters for only Savings or Investment plans, ignoring other account types.

### Grouping:
```sql
GROUP BY 
    p.id, s.owner_id, type            -- Group by plan ID, customer, and type to aggregate transactions

HAVING 
    inactivity_days > 365             -- Filter: Only show accounts with no transaction in over 1 year

ORDER BY 
    inactivity_days DESC;             -- Show most inactive accounts first
  ```  


- Groups the results by plan_id, owner_id, and type to ensure the aggregation (like MAX(transaction_date)) is done at the individual customer-account level.

- Post-aggregation Filter:

- Applies a HAVING clause to exclude accounts with recent activity, keeping only those that have been inactive for more than 365 days.

### Ordering:

- Sorts the result by inactivity_days in descending order, so the most inactive accounts appear first.

## Challenges Faced

 - Initially, I wrote the monthly grouping without explicitly extracting both the YEAR and MONTH from the transaction date. This led to incorrect grouping when the same month across different years was collapsed into one (e.g., Jan 2023 and Jan 2024 were treated as the same).

To resolve this, I added both YEAR(s.transaction_date) and MONTH(s.transaction_date) in the GROUP BY clause. This ensured that each month-year combination was treated distinctly, giving an accurate per-month count.

- Running this query on a large dataset raised performance concerns, especially with multiple nested CTEs and aggregations.
To improve performance, I ensured the savings_savingsaccount table had indexes on transaction_date and owner_id. In future iterations, I may also materialize intermediate tables or use window functions if needed.

`
# Question 4

### Step 1: Summarize Transaction Data per Customer
```sql
WITH txn_summary AS (
    SELECT
        s.owner_id,                                        -- Customer ID (owner of the account)
        COUNT(*) AS total_transactions,                    -- Total number of transactions
        AVG(s.confirmed_amount) AS avg_txn_value           -- Average transaction amount (in kobo)
    FROM 
        savings_savingsaccount s
    WHERE 
        s.confirmed_amount > 0                             -- Only consider positive (inflow) transactions
    GROUP BY 
        s.owner_id
)

```
 What this does:

- Collects transaction history for each customer.

- Filters to only include positive transaction amounts.

- For each customer (owner_id), calculates:

- total_transactions: How many transactions they’ve made.

- avg_txn_value: Their average transaction size (in kobo).
  
### Step 2: Calculate Tenure (How Long the Customer Has Been with Us
```sql
, tenure_data AS (
    SELECT 
        u.id AS customer_id,                               -- Customer ID
        CONCAT(u.first_name, ' ', u.last_name) AS name,    -- Full customer name
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months  -- Months since joining
    FROM 
        users_customuser u
)

```
- Pulls customer information from the users table.

- Calculates how long they’ve been a customer using TIMESTAMPDIFF in months.
 
### Step 3: Combine the Two and Estimate Customer Lifetime Value (CLV)
```sql
SELECT 
    t.customer_id,                                         -- Customer ID
    t.name,                                                -- Full name
    t.tenure_months,                                       -- How long they've been a customer
    x.total_transactions,                                  -- Number of transactions they've made

    ROUND(
        (x.total_transactions / NULLIF(t.tenure_months, 0)) * 12 * (0.001 * x.avg_txn_value / 100), 2
    ) AS estimated_clv                                     -- Estimated lifetime value

```
- Joins txn_summary and tenure_data using customer ID.

- Uses this formula to estimate Customer Lifetime Value (CLV):
- 
```sql
CLV ≈ (transactions per month) × 12 months × profit per transaction
```
#### Assumes 0.1% profit per transaction, so:

```sql
0.001 * x.avg_txn_value / 100
```
- Uses NULLIF(t.tenure_months, 0) to avoid division by zero.
'
### Final Output and Sorting
```sql
FROM 
    tenure_data t
JOIN 
    txn_summary x ON t.customer_id = x.owner_id

ORDER BY 
    estimated_clv DESC;
```
- Returns a ranked list of customers by estimated CLV, with the highest-value customers first.

## Challenges Faced

1. Division by Zero for New Customers
One of the first issues I faced was that some customers had just joined — meaning their tenure was 0 months. When I tried to calculate transactions per month using tenure, the query broke due to a division by zero error.

How I fixed it: I used NULLIF(t.tenure_months, 0) to prevent SQL from dividing by zero. This way, if tenure is zero, it returns NULL instead of crashing.

2. Skewed Averages Due to Zero or Negative Transactions
Initially, my average transaction values were inconsistent, and in some cases, CLV came out as zero. I realized that the dataset included transactions with a value of 0 or even negative amounts (e.g., reversals or adjustments), which distorted the results.

My fix: I added a filter to only include positive transactions using WHERE s.confirmed_amount > 0. That made sure I was only working with real inflow transactions that contribute to CLV.

3. Customers Missing From One of the Tables
At first, I was using a LEFT JOIN to combine user data with transaction summaries. But I started seeing customers with incomplete data — for example, names without transactions or vice versa.

What I did: I switched to an INNER JOIN between tenure_data and txn_summary. This made sure only customers who had both transaction history and tenure data appeared in the final result.

4. CLV Was Calculated in Kobo Instead of Naira
Another subtle issue was that the confirmed transaction amounts were stored in kobo. So when I calculated CLV, the values looked unusually large.

How I resolved it: I scaled the values properly by adjusting the formula: 0.001 * avg_txn_value / 100 — this accounted for the fact that 100 kobo = 1 naira, and ensured that the final CLV values were realistic and business-ready.


## Author
Azubuike Godswill


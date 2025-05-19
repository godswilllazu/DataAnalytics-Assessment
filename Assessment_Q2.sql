-- Step 1: Calculate monthly transaction count for each customer
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

-- Step 2: Calculate average transactions per month per customer
customer_avg_tx AS (
    SELECT
        owner_id,
        AVG(monthly_tx_count) AS avg_tx_per_month  -- Average monthly transaction frequency
    FROM 
        customer_monthly_tx
    GROUP BY 
        owner_id
),

-- Step 3: Categorize customers by their transaction frequency
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

-- Step 4: Aggregate the categorized results for reporting
SELECT 
    frequency_category,                       -- Frequency segment
    COUNT(*) AS customer_count,               -- Number of customers in each category
    ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month  -- Average monthly tx for category
FROM 
    categorized_customers
GROUP BY 
    frequency_category
ORDER BY 
    customer_count DESC;            -- Show most common categories first

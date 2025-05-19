WITH customer_monthly_tx AS (
    SELECT
        s.owner_id,
        YEAR(s.transaction_date) AS year,
        MONTH(s.transaction_date) AS month,
        COUNT(*) AS monthly_tx_count
    FROM 
        savings_savingsaccount s
    GROUP BY 
        s.owner_id, YEAR(s.transaction_date), MONTH(s.transaction_date)
),

customer_avg_tx AS (
    SELECT
        owner_id,
        AVG(monthly_tx_count) AS avg_tx_per_month
    FROM 
        customer_monthly_tx
    GROUP BY 
        owner_id
),

categorized_customers AS (
    SELECT 
        owner_id,
        avg_tx_per_month,
        CASE 
            WHEN avg_tx_per_month >= 10 THEN 'High Frequency'
            WHEN avg_tx_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM 
        customer_avg_tx
)

SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month
FROM 
    categorized_customers
GROUP BY 
    frequency_category
ORDER BY 
    customer_count DESC;

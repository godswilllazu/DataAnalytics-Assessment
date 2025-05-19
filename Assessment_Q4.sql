-- First CTE: Summarize transaction data for each customer
WITH txn_summary AS (
    SELECT
        s.owner_id,                                        -- Customer ID (owner of the account)
        COUNT(*) AS total_transactions,                    -- Total number of transactions
        AVG(s.confirmed_amount) AS avg_txn_value           -- Average transaction amount (in kobo)
    FROM 
        savings_savingsaccount s
    WHERE 
        s.confirmed_amount > 0                             -- Only consider transactions with positive inflow
    GROUP BY 
        s.owner_id
),

-- Second CTE: Calculate account tenure (in months) for each customer
tenure_data AS (
    SELECT 
        u.id AS customer_id,                               -- Customer ID
        CONCAT(u.first_name, ' ', u.last_name) AS name,    -- Full name of the customer
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months  -- Months since account signup
    FROM 
        users_customuser u
)

-- Final result: Calculate CLV using transaction and tenure data
SELECT 
    t.customer_id,                                         -- Customer ID
    t.name,                                                -- Customer name
    t.tenure_months,                                       -- Account tenure in months
    x.total_transactions,                                  -- Total number of transactions

    -- Estimated CLV formula:
    -- (transactions per month) * 12 months * average profit per transaction
    -- Profit per transaction is assumed to be 0.1% of transaction value
    ROUND(
        (x.total_transactions / NULLIF(t.tenure_months, 0)) * 12 * (0.1 * x.avg_txn_value / 100), 2
    ) AS estimated_clv

FROM 
    tenure_data t
JOIN 
    txn_summary x ON t.customer_id = x.owner_id           -- Join tenure and transaction data
ORDER BY 
    estimated_clv DESC;                                   -- Sort by highest estimated CLV

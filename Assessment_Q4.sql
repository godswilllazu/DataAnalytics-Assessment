WITH txn_summary AS (
    SELECT
        s.owner_id,
        COUNT(*) AS total_transactions,
        AVG(s.confirmed_amount) AS avg_txn_value
    FROM 
        savings_savingsaccount s
    WHERE 
        s.confirmed_amount > 0
    GROUP BY 
        s.owner_id
),

tenure_data AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months
    FROM 
        users_customuser u
)

SELECT 
    t.customer_id,
    t.name,
    t.tenure_months,
    x.total_transactions,
    ROUND(
        (x.total_transactions / NULLIF(t.tenure_months, 0)) * 12 * (0.1 * x.avg_txn_value / 100), 2
    ) AS estimated_clv
FROM 
    tenure_data t
JOIN 
    txn_summary x ON t.customer_id = x.owner_id
ORDER BY 
    estimated_clv DESC;

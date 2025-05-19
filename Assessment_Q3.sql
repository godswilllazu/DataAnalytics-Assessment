SELECT
    p.id AS plan_id,
    s.owner_id,
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM 
    savings_savingsaccount s
JOIN 
    plans_plan p ON s.plan_id = p.id
WHERE 
    s.new_balance > 0
    AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)
GROUP BY 
    p.id, s.owner_id, type
HAVING 
    inactivity_days > 365
ORDER BY 
    inactivity_days DESC;

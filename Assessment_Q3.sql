SELECT
    p.id AS plan_id,                  -- Unique identifier for the plan
    s.owner_id,                       -- Customer ID (owner of the account)

    -- Determine the account type based on the plan configuration
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'     -- If regular savings, label as 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'           -- If it's a fund, label as 'Investment'
    END AS type,

    MAX(s.transaction_date) AS last_transaction_date,    -- The most recent transaction date for the account
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days  -- Number of days since last transaction

FROM 
    savings_savingsaccount s          -- Source table containing all account transactions

JOIN 
    plans_plan p ON s.plan_id = p.id  -- Join the plans table to get account type info

WHERE 
    s.new_balance > 0                 -- Only include accounts that are currently active (non-zero balance)
    AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)  -- Include only Savings or Investment plans (ignore others)

GROUP BY 
    p.id, s.owner_id, type            -- Group by plan ID, customer, and type to aggregate transactions

HAVING 
    inactivity_days > 365             -- Filter: Only show accounts with no transaction in over 1 year

ORDER BY 
    inactivity_days DESC;             -- Show most inactive accounts first

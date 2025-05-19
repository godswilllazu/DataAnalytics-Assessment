SELECT 
    u.id AS owner_id,  -- Unique ID of the customer from users_customuser table
    -- Customers full name
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    -- Count of distinct savings accounts (plans marked as regular savings)
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) AS savings_count,
    
    -- Count of distinct investment accounts (plans marked as funds)
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) AS investment_count,
    
    -- Total amount deposited across all plans for the user ( in naira)
    SUM(p.amount/100) AS total_deposit

FROM 
    users_customuser u  -- Main users table

-- Join savings accounts to users using owner_id foreign key
JOIN 
    savings_savingsaccount s ON u.id = s.owner_id

-- Join plans to savings accounts using plan_id foreign key
JOIN 
    plans_plan p ON s.plan_id = p.id

-- Group results by each user
GROUP BY 
    u.id

-- Filter to return only users who have both:
-- 1. At least one funded savings plan
-- 2. At least one funded investment plan
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.id END) > 0
    AND COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.id END) > 0

-- Sort users by the total deposit amount in descending order
ORDER BY 
    total_deposit DESC;

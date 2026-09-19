use agriculture;

SELECT market_id, commodity_id, price_date, modal_price
FROM price_records
WHERE price_date BETWEEN '2024-01-01' AND '2024-12-31'
  AND modal_price > 2000;

-- Multi-condition WHERE with join to get readable names
SELECT m.market_name, c.commodity_name, pr.price_date, pr.modal_price
FROM price_records pr
JOIN markets m ON m.market_id = pr.market_id
JOIN commodities c ON c.commodity_id = pr.commodity_id
WHERE c.commodity_name = 'Tomato'
  AND pr.modal_price BETWEEN 1000 AND 3000;
  
  
SELECT c.commodity_name,
       COUNT(*)            AS record_count,
       AVG(pr.modal_price)  AS avg_modal_price,
       MIN(pr.min_price)    AS lowest_price,
       MAX(pr.max_price)    AS highest_price
FROM price_records pr
JOIN commodities c ON c.commodity_id = pr.commodity_id
GROUP BY c.commodity_name
HAVING AVG(pr.modal_price) > 1500
ORDER BY avg_modal_price DESC;


SELECT mk.market_name, COUNT(DISTINCT pr.commodity_id) AS commodity_variety
FROM price_records pr
JOIN markets mk ON mk.market_id = pr.market_id
GROUP BY mk.market_name
HAVING COUNT(DISTINCT pr.commodity_id) > 5;

SELECT
    s.state_name,
    d.district_name,
    mk.market_name,
    c.commodity_name,
    v.variety_name,
    g.grade_name,
    pr.price_date,
    pr.min_price,
    pr.max_price,
    pr.modal_price
FROM price_records pr
JOIN markets     mk ON mk.market_id     = pr.market_id
JOIN districts   d  ON d.district_id    = mk.district_id
JOIN states       s  ON s.state_id       = d.state_id
JOIN commodities c  ON c.commodity_id   = pr.commodity_id
JOIN varieties   v  ON v.variety_id     = pr.variety_id
JOIN grades      g  ON g.grade_id       = pr.grade_id
WHERE pr.price_date = '2024-06-15';

SELECT c.commodity_name, COUNT(pr.record_id) AS records_in_range
FROM commodities c
LEFT JOIN price_records pr
    ON pr.commodity_id = c.commodity_id
   AND pr.price_date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY c.commodity_name;


SELECT c.commodity_name, AVG(pr.modal_price) AS avg_price
FROM price_records pr
JOIN commodities c ON c.commodity_id = pr.commodity_id
GROUP BY c.commodity_name
HAVING AVG(pr.modal_price) > (
    SELECT AVG(modal_price) FROM price_records
);

SELECT pr.*
FROM (
    SELECT pr.*,
           ROW_NUMBER() OVER (PARTITION BY market_id ORDER BY price_date DESC) AS rn
    FROM price_records pr
) pr
WHERE rn = 1;

SELECT commodity_id, market_id, avg_price
FROM (
    SELECT commodity_id, market_id, AVG(modal_price) AS avg_price,
           RANK() OVER (PARTITION BY commodity_id ORDER BY AVG(modal_price) DESC) AS rnk
    FROM price_records
    GROUP BY commodity_id, market_id
) ranked
WHERE rnk = 1;

SELECT
    c.commodity_name,
    mk.market_name,
    pr.price_date,
    pr.modal_price,
    RANK()       OVER (PARTITION BY pr.commodity_id, pr.price_date ORDER BY pr.modal_price DESC) AS price_rank,
    DENSE_RANK() OVER (PARTITION BY pr.commodity_id, pr.price_date ORDER BY pr.modal_price DESC) AS price_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY pr.commodity_id, pr.price_date ORDER BY pr.modal_price DESC) AS price_row_num
FROM price_records pr
JOIN commodities c ON c.commodity_id = pr.commodity_id
JOIN markets     mk ON mk.market_id  = pr.market_id;

WITH ranked AS (
    SELECT 
        pr.commodity_id,
        pr.price_date,
        pr.modal_price,
        ROW_NUMBER() OVER (PARTITION BY pr.commodity_id ORDER BY pr.price_date) AS rn
    FROM price_records pr
)
SELECT 
    c.commodity_name,
    curr.price_date,
    curr.modal_price,
    prev.modal_price AS prev_day_price,
    next.modal_price AS next_day_price
FROM ranked curr
JOIN commodities c ON c.commodity_id = curr.commodity_id
LEFT JOIN ranked prev 
    ON prev.commodity_id = curr.commodity_id AND prev.rn = curr.rn - 1
LEFT JOIN ranked next 
    ON next.commodity_id = curr.commodity_id AND next.rn = curr.rn + 1
ORDER BY c.commodity_name, curr.price_date;
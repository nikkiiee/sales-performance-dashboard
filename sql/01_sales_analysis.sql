-- Query 1: Inspect the sales data
SELECT *
FROM public.sales
LIMIT 10;


-- Query 2: Calculate the main KPIs
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct,
    SUM(quantity) AS units_sold
FROM public.sales;


-- Query 3: Analyze category performance
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM public.sales
GROUP BY category
ORDER BY total_sales DESC;


-- Query 4: Analyze regional performance
SELECT
    region,
    COUNT(DISTINCT order_id) AS unique_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM public.sales
GROUP BY region
ORDER BY total_profit DESC;


-- Query 5: Monthly sales and profit trends

SELECT
    DATE_TRUNC('month', order_date)::DATE AS sales_month,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS unique_orders
FROM public.sales
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month;


-- Query 6A:

SELECT
    product_id,
    product_name,
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM public.sales
GROUP BY
    product_id,
    product_name,
    category
ORDER BY total_profit DESC
LIMIT 10;

-- Query 6B:

SELECT
    product_id,
    product_name,
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM public.sales
GROUP BY
    product_id,
    product_name,
    category
ORDER BY total_profit ASC
LIMIT 10;


-- Query 7: Sales and profit by discount level

SELECT
    discount,
    COUNT(*) AS transaction_rows,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(
        SUM(profit) / NULLIF(SUM(sales), 0) * 100,
        2
    ) AS profit_margin_pct
FROM public.sales
GROUP BY discount
ORDER BY discount;



-- Query 8: Category profitability by discount level

WITH discount_analysis AS (
    SELECT
        category,
        discount,
        COUNT(*) AS transaction_rows,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM public.sales
    GROUP BY category, discount
)
SELECT
    category,
    discount,
    transaction_rows,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit,
    ROUND(
        total_profit / NULLIF(total_sales, 0) * 100,
        2
    ) AS profit_margin_pct
FROM discount_analysis
ORDER BY category, discount;



-- Query 9: Rank products by total profit

WITH product_profit AS (
    SELECT
        product_id,
        product_name,
        category,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit
    FROM public.sales
    GROUP BY product_id, product_name, category
),
ranked_products AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY total_profit DESC
        ) AS profit_rank
    FROM product_profit
)
SELECT
    profit_rank,
    product_id,
    product_name,
    category,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(total_profit, 2) AS total_profit
FROM ranked_products
WHERE profit_rank <= 10
ORDER BY profit_rank;



-- Query 10: Month-over-month sales growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS sales_month,
        SUM(sales) AS total_sales
    FROM public.sales
    GROUP BY DATE_TRUNC('month', order_date)
),
sales_with_previous_month AS (
    SELECT
        sales_month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(total_sales, 2) AS total_sales,
    ROUND(previous_month_sales, 2) AS previous_month_sales,
    ROUND(
        (total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS sales_growth_pct
FROM sales_with_previous_month
ORDER BY sales_month;

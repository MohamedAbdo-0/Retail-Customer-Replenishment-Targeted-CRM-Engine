CREATE OR REPLACE TABLE stg_transaction AS
SELECT
    CAST(household_key AS INTEGER) AS household_key,
    CAST(BASKET_ID AS BIGINT) AS basket_id,
    CAST(DAY AS INTEGER) AS day_idx,
    CAST(PRODUCT_ID AS INTEGER) AS product_id,
    CAST(QUANTITY AS INTEGER) AS quantity,
    CAST(SALES_VALUE AS DOUBLE) AS sales_value,
    CAST(STORE_ID AS INTEGER) AS store_id,
    CAST(RETAIL_DISC AS DOUBLE) AS retail_disc,
    CAST(TRANS_TIME AS INTEGER) AS trans_time,
    CAST(WEEK_NO AS INTEGER) AS week_no,
    CAST(COUPON_DISC AS DOUBLE) AS coupon_disc,
    CAST(COUPON_MATCH_DISC AS DOUBLE) AS coupon_match_disc
FROM
    read_csv_auto('transaction_data.csv');

CREATE OR REPLACE TABLE stg_product AS
SELECT
    CAST(PRODUCT_ID AS INTEGER) AS product_id,
    CAST(MANUFACTURER AS VARCHAR) AS manufacturer,
    CAST(DEPARTMENT AS VARCHAR) AS department,
    CAST(BRAND AS VARCHAR) AS brand,
    CAST(COMMODITY_DESC AS VARCHAR) AS commodity_desc,
    CAST(SUB_COMMODITY_DESC AS VARCHAR) AS sub_commodity_desc,
    CAST(CURR_SIZE_OF_PRODUCT AS VARCHAR) AS curr_size_of_product
FROM
    read_csv_auto('product.csv');

CREATE OR REPLACE TABLE stg_demographic AS
SELECT
    CAST(household_key AS INTEGER) AS household_key,
    CAST(AGE_DESC AS VARCHAR) AS age_desc,
    CAST(MARITAL_STATUS_CODE AS VARCHAR) AS marital_status_code,
    CAST(INCOME_DESC AS VARCHAR) AS income_desc,
    CAST(HOMEOWNER_DESC AS VARCHAR) AS homeowner_desc,
    CAST(HH_COMP_DESC AS VARCHAR) AS hh_comp_desc,
    CAST(HOUSEHOLD_SIZE_DESC AS VARCHAR) AS household_size_desc,
    CAST(KID_CATEGORY_DESC AS VARCHAR) AS kid_category_desc
FROM
    read_csv_auto('hh_demographic.csv');

CREATE OR REPLACE TABLE stg_campaign_desc AS
SELECT
    CAST(CAMPAIGN AS INTEGER) AS campaign,
    CAST(DESCRIPTION AS VARCHAR) AS description,
    CAST(START_DAY AS INTEGER) AS start_day,
    CAST(END_DAY AS INTEGER) AS end_day
FROM
    read_csv_auto('campaign_desc.csv');

CREATE OR REPLACE TABLE stg_campaign_table AS
SELECT
    CAST(household_key AS INTEGER) AS household_key,
    CAST(CAMPAIGN AS INTEGER) AS campaign,
    CAST(DESCRIPTION AS VARCHAR) AS description
FROM
    read_csv_auto('campaign_table.csv');

CREATE OR REPLACE TABLE stg_coupon AS
SELECT
    CAST(COUPON_UPC AS BIGINT) AS coupon_upc,
    CAST(PRODUCT_ID AS INTEGER) AS product_id,
    CAST(CAMPAIGN AS INTEGER) AS campaign
FROM
    read_csv_auto('coupon.csv');

CREATE OR REPLACE TABLE stg_coupon_redempt AS
SELECT
    CAST(household_key AS INTEGER) AS household_key,
    CAST(DAY AS INTEGER) AS day_idx,
    CAST(COUPON_UPC AS BIGINT) AS coupon_upc,
    CAST(CAMPAIGN AS INTEGER) AS campaign
FROM
    read_csv_auto('coupon_redempt.csv');

CREATE OR REPLACE TABLE stg_causal AS
SELECT
    CAST(PRODUCT_ID AS INTEGER) AS product_id,
    CAST(STORE_ID AS INTEGER) AS store_id,
    CAST(WEEK_NO AS INTEGER) AS week_no,
    CAST(display AS VARCHAR) AS display,
    CAST(mailer AS VARCHAR) AS mailer
FROM
    read_csv_auto('causal_data.csv');

SELECT
    COUNT(*) AS product_rows
FROM
    stg_product;

SELECT
    household_key,
    basket_id,
    day_idx,
    product_id,
    COUNT(*) AS row_count
FROM
    stg_transaction
GROUP BY
    household_key,
    basket_id,
    day_idx,
    product_id
HAVING
    COUNT(*) > 1
ORDER BY
    row_count DESC;

SELECT
    'stg_product' AS table_name,
    CAST(product_id AS VARCHAR) AS key_values,
    COUNT(*) AS duplicate_count
FROM
    stg_product
GROUP BY
    product_id
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_demographic',
    CAST(household_key AS VARCHAR),
    COUNT(*)
FROM
    stg_demographic
GROUP BY
    household_key
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_causal',
    CONCAT_WS(
        ' | ',
        CAST(product_id AS VARCHAR),
        CAST(store_id AS VARCHAR),
        CAST(week_no AS VARCHAR)
    ),
    COUNT(*)
FROM
    stg_causal
GROUP BY
    product_id,
    store_id,
    week_no
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_campaign_table',
    CONCAT_WS(
        ' | ',
        CAST(household_key AS VARCHAR),
        CAST(campaign AS VARCHAR)
    ),
    COUNT(*)
FROM
    stg_campaign_table
GROUP BY
    household_key,
    campaign
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_campaign_desc',
    CAST(campaign AS VARCHAR),
    COUNT(*)
FROM
    stg_campaign_desc
GROUP BY
    campaign
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_coupon',
    CONCAT_WS(
        ' | ',
        CAST(coupon_upc AS VARCHAR),
        CAST(product_id AS VARCHAR),
        CAST(campaign AS VARCHAR)
    ),
    COUNT(*)
FROM
    stg_coupon
GROUP BY
    coupon_upc,
    product_id,
    campaign
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'stg_coupon_redempt',
    CONCAT_WS(
        ' | ',
        CAST(household_key AS VARCHAR),
        CAST(day_idx AS VARCHAR),
        CAST(coupon_upc AS VARCHAR),
        CAST(campaign AS VARCHAR)
    ),
    COUNT(*)
FROM
    stg_coupon_redempt
GROUP BY
    household_key,
    day_idx,
    coupon_upc,
    campaign
HAVING
    COUNT(*) > 1
ORDER BY
    table_name,
    duplicate_count DESC;

SELECT
    *
FROM
    stg_causal
WHERE
    PRODUCT_ID = 244960
    AND STORE_ID = 319
    AND WEEK_NO = 68;

WITH
    duplicate_keys AS (
        SELECT
            PRODUCT_ID,
            STORE_ID,
            WEEK_NO,
            COUNT(*) AS row_count,
            COUNT(DISTINCT display) AS display_variants,
            COUNT(DISTINCT mailer) AS mailer_variants
        FROM
            stg_causal
        GROUP BY
            PRODUCT_ID,
            STORE_ID,
            WEEK_NO
        HAVING
            COUNT(*) > 1
    )
SELECT
    CASE
        WHEN display_variants = 1
        AND mailer_variants = 1 THEN 'Same display and mailer'
        ELSE 'Different display or mailer'
    END AS duplicate_type,
    COUNT(*) AS duplicate_key_groups,
    SUM(row_count) AS rows_in_groups
FROM
    duplicate_keys
GROUP BY
    duplicate_type
ORDER BY
    duplicate_type;

WITH
    duplicate_keys AS (
        SELECT
            PRODUCT_ID,
            STORE_ID,
            WEEK_NO,
            COUNT(*) AS row_count,
            COUNT(DISTINCT display) AS display_variants,
            COUNT(DISTINCT mailer) AS mailer_variants
        FROM
            stg_causal
        GROUP BY
            PRODUCT_ID,
            STORE_ID,
            WEEK_NO
        HAVING
            COUNT(*) > 1
    )
SELECT
    CASE
        WHEN display_variants > 1
        AND mailer_variants > 1 THEN 'Both display and mailer differ'
        WHEN display_variants > 1 THEN 'Display differs'
        WHEN mailer_variants > 1 THEN 'Mailer differs'
        ELSE 'Same display and mailer'
    END AS difference_type,
    COUNT(*) AS duplicate_key_groups,
    SUM(row_count) AS rows_in_groups
FROM
    duplicate_keys
GROUP BY
    difference_type
ORDER BY
    difference_type;

SELECT
    household_key,
    basket_id,
    day_idx,
    product_id,
    store_id,
    quantity,
    sales_value
FROM
    stg_transaction
WHERE
    product_id = 244960
    AND store_id = 319
    AND week_no = 68
ORDER BY
    day_idx,
    basket_id;

SELECT
    household_key,
    BASKET_ID,
    day_idx,
    STORE_ID,
    WEEK_NO,
    QUANTITY,
    SALES_VALUE
FROM
    stg_transaction
WHERE
    PRODUCT_ID = 244960
ORDER BY
    day_idx,
    STORE_ID,
    BASKET_ID
LIMIT
    50;

WITH
    dup_keys AS (
        SELECT
            product_id,
            store_id,
            week_no
        FROM
            stg_causal
        WHERE
            week_no = 68
        GROUP BY
            product_id,
            store_id,
            week_no
        HAVING
            COUNT(*) > 1
        LIMIT
            5
    )
SELECT
    c.product_id,
    c.store_id,
    c.week_no,
    c.display,
    c.mailer
FROM
    stg_causal c
    JOIN dup_keys d ON c.product_id = d.product_id
    AND c.store_id = d.store_id
    AND c.week_no = d.week_no
ORDER BY
    c.product_id,
    c.store_id,
    c.display;

SET
    threads = 2;

SET
    preserve_insertion_order = FALSE;

SELECT
    product_id,
    store_id,
    week_no,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT display) AS distinct_displays,
    COUNT(DISTINCT mailer) AS distinct_mailers
FROM
    stg_causal
WHERE
    week_no = 68
GROUP BY
    product_id,
    store_id,
    week_no
HAVING
    COUNT(*) > 1
ORDER BY
    total_rows DESC
LIMIT
    10;

SELECT
    product_id,
    store_id,
    week_no,
    display,
    mailer
FROM
    stg_causal
WHERE
    product_id = 244960
    AND store_id = 361
    AND week_no = 68;

SELECT
    table_name
FROM
    information_schema.tables
WHERE
    table_schema = 'main'
    AND table_type = 'BASE TABLE'
ORDER BY
    table_name;

SELECT
    'stg_campaign_desc' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(DESCRIPTION AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(CAMPAIGN AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(START_DAY AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(END_DAY AS VARCHAR)), '') IS NULL
    ) AS rows_with_missing_values
FROM
    stg_campaign_desc
UNION ALL
SELECT
    'stg_campaign_table',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(DESCRIPTION AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(household_key AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(CAMPAIGN AS VARCHAR)), '') IS NULL
    )
FROM
    stg_campaign_table
UNION ALL
SELECT
    'stg_causal',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(PRODUCT_ID AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(STORE_ID AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(WEEK_NO AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(display AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(mailer AS VARCHAR)), '') IS NULL
    )
FROM
    stg_causal
UNION ALL
SELECT
    'stg_coupon',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(COUPON_UPC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(PRODUCT_ID AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(CAMPAIGN AS VARCHAR)), '') IS NULL
    )
FROM
    stg_coupon
UNION ALL
SELECT
    'stg_coupon_redempt',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(household_key AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(day_idx AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(coupon_upc AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(campaign AS VARCHAR)), '') IS NULL
    )
FROM
    stg_coupon_redempt
UNION ALL
SELECT
    'stg_demographic',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(AGE_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(MARITAL_STATUS_CODE AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(INCOME_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(HOMEOWNER_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(HH_COMP_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(HOUSEHOLD_SIZE_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(KID_CATEGORY_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(household_key AS VARCHAR)), '') IS NULL
    )
FROM
    stg_demographic
UNION ALL
SELECT
    'stg_product',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(PRODUCT_ID AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(MANUFACTURER AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(DEPARTMENT AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(BRAND AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(COMMODITY_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(SUB_COMMODITY_DESC AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(CURR_SIZE_OF_PRODUCT AS VARCHAR)), '') IS NULL
    )
FROM
    stg_product
UNION ALL
SELECT
    'stg_transaction',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            NULLIF(TRIM(CAST(household_key AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(basket_id AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(day_idx AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(product_id AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(quantity AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(sales_value AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(store_id AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(retail_disc AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(trans_time AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(week_no AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(coupon_disc AS VARCHAR)), '') IS NULL
            OR NULLIF(TRIM(CAST(coupon_match_disc AS VARCHAR)), '') IS NULL
    )
FROM
    stg_transaction
ORDER BY
    table_name;

SELECT
    'PRODUCT_ID' AS column_name,
    COUNT(*) FILTER(
        WHERE
            PRODUCT_ID IS NULL
    ) AS sql_null_count,
    COUNT(*) FILTER(
        WHERE
            PRODUCT_ID IS NOT NULL
            AND TRIM(CAST(PRODUCT_ID AS VARCHAR)) = ''
    ) AS blank_or_whitespace_count,
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(PRODUCT_ID AS VARCHAR))) = 'null'
    ) AS literal_null_text_count
FROM
    stg_product
UNION ALL
SELECT
    'MANUFACTURER',
    COUNT(*) FILTER(
        WHERE
            MANUFACTURER IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            MANUFACTURER IS NOT NULL
            AND TRIM(CAST(MANUFACTURER AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(MANUFACTURER AS VARCHAR))) = 'null'
    )
FROM
    stg_product
UNION ALL
SELECT
    'DEPARTMENT',
    COUNT(*) FILTER(
        WHERE
            DEPARTMENT IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            DEPARTMENT IS NOT NULL
            AND TRIM(CAST(DEPARTMENT AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(DEPARTMENT AS VARCHAR))) = 'null'
    )
FROM
    stg_product
UNION ALL
SELECT
    'BRAND',
    COUNT(*) FILTER(
        WHERE
            BRAND IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            BRAND IS NOT NULL
            AND TRIM(CAST(BRAND AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(BRAND AS VARCHAR))) = 'null'
    )
FROM
    stg_product
UNION ALL
SELECT
    'COMMODITY_DESC',
    COUNT(*) FILTER(
        WHERE
            COMMODITY_DESC IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            COMMODITY_DESC IS NOT NULL
            AND TRIM(CAST(COMMODITY_DESC AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(COMMODITY_DESC AS VARCHAR))) = 'null'
    )
FROM
    stg_product
UNION ALL
SELECT
    'SUB_COMMODITY_DESC',
    COUNT(*) FILTER(
        WHERE
            SUB_COMMODITY_DESC IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            SUB_COMMODITY_DESC IS NOT NULL
            AND TRIM(CAST(SUB_COMMODITY_DESC AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(SUB_COMMODITY_DESC AS VARCHAR))) = 'null'
    )
FROM
    stg_product
UNION ALL
SELECT
    'CURR_SIZE_OF_PRODUCT',
    COUNT(*) FILTER(
        WHERE
            CURR_SIZE_OF_PRODUCT IS NULL
    ),
    COUNT(*) FILTER(
        WHERE
            CURR_SIZE_OF_PRODUCT IS NOT NULL
            AND TRIM(CAST(CURR_SIZE_OF_PRODUCT AS VARCHAR)) = ''
    ),
    COUNT(*) FILTER(
        WHERE
            LOWER(TRIM(CAST(CURR_SIZE_OF_PRODUCT AS VARCHAR))) = 'null'
    )
FROM
    stg_product
ORDER BY
    column_name;

SELECT
    PRODUCT_ID,
    MANUFACTURER,
    DEPARTMENT,
    BRAND,
    COMMODITY_DESC,
    SUB_COMMODITY_DESC,
    CURR_SIZE_OF_PRODUCT
FROM
    stg_product
WHERE
    TRIM(CAST(CURR_SIZE_OF_PRODUCT AS VARCHAR)) = ''
    OR TRIM(CAST(DEPARTMENT AS VARCHAR)) = ''
    OR TRIM(CAST(COMMODITY_DESC AS VARCHAR)) = ''
    OR TRIM(CAST(SUB_COMMODITY_DESC AS VARCHAR)) = ''
LIMIT
    20;

SELECT
    PRODUCT_ID,
    DEPARTMENT,
    COMMODITY_DESC,
    SUB_COMMODITY_DESC
FROM
    stg_product
WHERE
    TRIM(CAST(DEPARTMENT AS VARCHAR)) = ''
    OR TRIM(CAST(COMMODITY_DESC AS VARCHAR)) = ''
    OR TRIM(CAST(SUB_COMMODITY_DESC AS VARCHAR)) = ''
ORDER BY
    PRODUCT_ID;

SELECT
    product_id,
    department,
    COALESCE(
        NULLIF(TRIM(CAST(department AS VARCHAR)), ''),
        'Unclassified'
    ) AS department_clean
FROM
    stg_product
WHERE
    TRIM(CAST(department AS VARCHAR)) = ''
    OR department IS NULL;

SELECT
    'QUANTITY' AS column_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER(
        WHERE
            QUANTITY < 0
    ) AS negative_rows,
    COUNT(*) FILTER(
        WHERE
            QUANTITY = 0
    ) AS zero_rows,
    MIN(QUANTITY) AS min_value,
    MAX(QUANTITY) AS max_value
FROM
    stg_transaction
UNION ALL
SELECT
    'SALES_VALUE',
    COUNT(*),
    COUNT(*) FILTER(
        WHERE
            SALES_VALUE < 0
    ),
    COUNT(*) FILTER(
        WHERE
            SALES_VALUE = 0
    ),
    MIN(SALES_VALUE),
    MAX(SALES_VALUE)
FROM
    stg_transaction;

SELECT
    household_key,
    BASKET_ID,
    day_idx,
    PRODUCT_ID,
    QUANTITY,
    SALES_VALUE,
    STORE_ID,
    RETAIL_DISC,
    TRANS_TIME,
    WEEK_NO,
    COUPON_DISC,
    COUPON_MATCH_DISC
FROM
    stg_transaction
WHERE
    QUANTITY = 89638
    OR SALES_VALUE = 840
ORDER BY
    QUANTITY DESC,
    SALES_VALUE DESC;

SELECT
    PRODUCT_ID,
    MANUFACTURER,
    DEPARTMENT,
    BRAND,
    COMMODITY_DESC,
    SUB_COMMODITY_DESC,
    CURR_SIZE_OF_PRODUCT
FROM
    stg_product
WHERE
    PRODUCT_ID IN (6534178, 12484608)
ORDER BY
    PRODUCT_ID;

SELECT
    PRODUCT_ID,
    COUNT(*) AS transaction_rows,
    MIN(QUANTITY) AS min_quantity,
    MEDIAN(QUANTITY) AS median_quantity,
    MAX(QUANTITY) AS max_quantity,
    MIN(SALES_VALUE) AS min_sales_value,
    MEDIAN(SALES_VALUE) AS median_sales_value,
    MAX(SALES_VALUE) AS max_sales_value
FROM
    stg_transaction
WHERE
    PRODUCT_ID IN (6534178, 12484608)
GROUP BY
    PRODUCT_ID
ORDER BY
    PRODUCT_ID;

SELECT
    household_key,
    BASKET_ID,
    day_idx,
    PRODUCT_ID,
    QUANTITY,
    SALES_VALUE,
    STORE_ID,
    RETAIL_DISC,
    TRANS_TIME,
    WEEK_NO,
    COUPON_DISC,
    COUPON_MATCH_DISC
FROM
    stg_transaction
WHERE
    PRODUCT_ID = 12484608
ORDER BY
    SALES_VALUE DESC
LIMIT
    10;

SELECT
    household_key,
    SUM(SALES_VALUE) AS total_sales_value
FROM
    stg_transaction
GROUP BY
    household_key
ORDER BY
    total_sales_value DESC
LIMIT
    10;

WITH
    top_households AS (
        SELECT
            household_key
        FROM
            stg_transaction
        GROUP BY
            household_key
        ORDER BY
            SUM(SALES_VALUE) DESC
        LIMIT
            10
    )
SELECT
    t.household_key,
    t.STORE_ID,
    COUNT(DISTINCT t.BASKET_ID) AS basket_count,
    SUM(t.SALES_VALUE) AS store_sales_value
FROM
    stg_transaction AS t
    JOIN top_households AS h ON t.household_key = h.household_key
GROUP BY
    t.household_key,
    t.STORE_ID
ORDER BY
    t.household_key,
    store_sales_value DESC;

WITH
    top_households AS (
        SELECT
            household_key
        FROM
            stg_transaction
        GROUP BY
            household_key
        ORDER BY
            SUM(SALES_VALUE) DESC
        LIMIT
            10
    )
SELECT
    t.STORE_ID,
    SUM(t.SALES_VALUE) AS store_sales_value,
    COUNT(DISTINCT t.household_key) AS household_count,
    COUNT(DISTINCT t.BASKET_ID) AS basket_count
FROM
    stg_transaction AS t
    JOIN top_households AS h ON t.household_key = h.household_key
GROUP BY
    t.STORE_ID
ORDER BY
    store_sales_value DESC
LIMIT
    5;

SELECT
    COUNT(*) FILTER(
        WHERE
            QUANTITY = 0
    ) AS zero_quantity_rows,
    COUNT(*) FILTER(
        WHERE
            SALES_VALUE = 0
    ) AS zero_sales_rows,
    COUNT(*) FILTER(
        WHERE
            QUANTITY = 0
            AND SALES_VALUE = 0
    ) AS both_zero_rows,
    COUNT(*) FILTER(
        WHERE
            QUANTITY = 0
            AND SALES_VALUE <> 0
    ) AS zero_quantity_nonzero_sales_rows,
    COUNT(*) FILTER(
        WHERE
            QUANTITY <> 0
            AND SALES_VALUE = 0
    ) AS nonzero_quantity_zero_sales_rows
FROM
    stg_transaction;

SELECT
    household_key,
    BASKET_ID,
    day_idx,
    PRODUCT_ID,
    STORE_ID,
    QUANTITY,
    SALES_VALUE,
    RETAIL_DISC,
    COUPON_DISC,
    COUPON_MATCH_DISC
FROM
    stg_transaction
WHERE
    QUANTITY = 0
    AND SALES_VALUE <> 0
ORDER BY
    SALES_VALUE DESC;

WITH
    raw_row AS (
        SELECT
            household_key,
            BASKET_ID,
            DAY,
            PRODUCT_ID,
            STORE_ID,
            CAST(QUANTITY AS DOUBLE) AS raw_quantity,
            CAST(SALES_VALUE AS DOUBLE) AS raw_sales_value
        FROM
            read_csv_auto('transaction_data.csv')
        WHERE
            household_key = 2035
            AND BASKET_ID = 30217406304
            AND DAY = 226
            AND PRODUCT_ID = 866871
            AND STORE_ID = 298
    )
SELECT
    raw.raw_quantity,
    staged.quantity AS staged_quantity,
    raw.raw_sales_value,
    staged.sales_value AS staged_sales_value
FROM
    raw_row AS raw
    JOIN stg_transaction AS staged ON raw.household_key = staged.household_key
    AND raw.BASKET_ID = staged.basket_id
    AND raw.DAY = staged.day_idx
    AND raw.PRODUCT_ID = staged.product_id
    AND raw.STORE_ID = staged.store_id;

SELECT
    PRODUCT_ID,
    MANUFACTURER,
    DEPARTMENT,
    BRAND,
    COMMODITY_DESC,
    SUB_COMMODITY_DESC,
    CURR_SIZE_OF_PRODUCT
FROM
    stg_product
WHERE
    PRODUCT_ID = 866871;

WITH
    product_sales AS (
        SELECT
            CAST(PRODUCT_ID AS INTEGER) AS product_id,
            SUM(CAST(QUANTITY AS DOUBLE)) AS total_quantity,
            COUNT(*) AS transaction_rows,
            SUM(CAST(SALES_VALUE AS DOUBLE)) AS total_sales_value
        FROM
            read_csv_auto('transaction_data.csv')
        GROUP BY
            CAST(PRODUCT_ID AS INTEGER)
    )
SELECT
    p.product_id,
    p.department,
    p.commodity_desc,
    p.sub_commodity_desc,
    COALESCE(s.transaction_rows, 0) AS transaction_rows,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales_value, 0) AS total_sales_value
FROM
    stg_product AS p
    LEFT JOIN product_sales AS s ON p.product_id = s.product_id
WHERE
    COALESCE(s.total_quantity, 0) = 0
ORDER BY
    p.product_id;

SELECT
    p.department,
    COUNT(*) AS products_never_sold
FROM
    stg_product p
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            stg_transaction t
        WHERE
            t.product_id = p.product_id
    )
GROUP BY
    p.department
ORDER BY
    products_never_sold DESC;

WITH
    top_households AS (
        SELECT
            household_key
        FROM
            stg_transaction
        GROUP BY
            household_key
        ORDER BY
            SUM(sales_value) DESC
        LIMIT
            10
    ),
    never_sold_products AS (
        SELECT
            p.product_id
        FROM
            stg_product AS p
        WHERE
            NOT EXISTS (
                SELECT
                    1
                FROM
                    stg_transaction AS t
                WHERE
                    t.product_id = p.product_id
            )
    )
SELECT
    h.household_key,
    COUNT(DISTINCT n.product_id) AS products_checked,
    COUNT(DISTINCT t.product_id) AS products_purchased,
    CASE
        WHEN COUNT(DISTINCT t.product_id) > 0 THEN 'Yes'
        ELSE 'No'
    END AS purchased_any
FROM
    top_households AS h
    CROSS JOIN never_sold_products AS n
    LEFT JOIN stg_transaction AS t ON t.household_key = h.household_key
    AND t.product_id = n.product_id
GROUP BY
    h.household_key
ORDER BY
    h.household_key;

WITH
    product_period_counts AS (
        SELECT
            household_key,
            CAST(FLOOR((day_idx - 1) / 30.0) + 1 AS INTEGER) AS period_30d,
            product_id,
            COUNT(DISTINCT basket_id) AS purchase_occasions
        FROM
            stg_transaction
        GROUP BY
            household_key,
            period_30d,
            product_id
    )
SELECT
    household_key,
    period_30d,
    COUNT(*) AS products_bought_more_than_3_times
FROM
    product_period_counts
WHERE
    purchase_occasions > 3
GROUP BY
    household_key,
    period_30d
ORDER BY
    household_key,
    period_30d;

SELECT
    household_key,
    product_id,
    COUNT(DISTINCT basket_id) AS purchase_count
FROM
    stg_transaction
GROUP BY
    household_key,
    product_id
HAVING
    COUNT(DISTINCT basket_id) > 200
ORDER BY
    purchase_count DESC;

WITH
    household_product_counts AS (
        SELECT
            household_key,
            product_id,
            COUNT(DISTINCT basket_id) AS purchase_occasions
        FROM
            stg_transaction
        GROUP BY
            household_key,
            product_id
        HAVING
            COUNT(DISTINCT basket_id) > 200
    )
SELECT
    COUNT(DISTINCT household_key) AS household_count
FROM
    household_product_counts;

SELECT
    product_id,
    department,
    commodity_desc,
    sub_commodity_desc,
    brand,
    manufacturer,
    curr_size_of_product
FROM
    stg_product
WHERE
    product_id IN (
        1126203,
        894236,
        1120741,
        6533889,
        975938,
        1053690,
        890536
    )
ORDER BY
    product_id;

WITH
    frequent_purchases AS (
        SELECT
            *
        FROM
            (
                VALUES
                    (1510, 1126203, 246),
                    (1510, 894236, 240),
                    (2337, 1120741, 240),
                    (1023, 6533889, 236),
                    (853, 975938, 220),
                    (1998, 1053690, 202),
                    (900, 890536, 202)
            ) AS v (household_key, product_id, purchase_count)
    )
SELECT
    f.household_key,
    f.product_id,
    f.purchase_count,
    p.department,
    p.brand,
    p.commodity_desc,
    p.sub_commodity_desc,
    p.curr_size_of_product
FROM
    frequent_purchases AS f
    LEFT JOIN stg_product AS p ON f.product_id = p.product_id
ORDER BY
    f.purchase_count DESC;

SELECT
    product_id,
    COUNT(DISTINCT household_key) AS households_buying,
    COUNT(DISTINCT basket_id) AS purchase_baskets,
    SUM(sales_value) AS total_sales_value
FROM
    stg_transaction
GROUP BY
    product_id
ORDER BY
    purchase_baskets DESC
LIMIT
    20;

SELECT
    product_id,
    department,
    brand,
    commodity_desc,
    sub_commodity_desc,
    curr_size_of_product
FROM
    stg_product
WHERE
    product_id IN (1082185, 6534178, 5978656)
ORDER BY
    product_id;

SELECT
    WEEK_NO,
    COUNT(DISTINCT household_key) AS households_buying,
    COUNT(DISTINCT BASKET_ID) AS purchase_baskets,
    SUM(SALES_VALUE) AS sales_value
FROM
    stg_transaction
WHERE
    PRODUCT_ID = 1082185
GROUP BY
    WEEK_NO
ORDER BY
    WEEK_NO;

WITH
    data_end AS (
        SELECT
            MAX(day_idx) AS last_day
        FROM
            stg_transaction
    )
SELECT
    COUNT(DISTINCT t.household_key) AS households_that_bought_product
FROM
    stg_transaction AS t
    CROSS JOIN data_end AS d
WHERE
    t.product_id = 1082185
    AND t.day_idx > d.last_day - 28
    AND t.day_idx <= d.last_day;

WITH
    data_end AS (
        SELECT
            MAX(day_idx) AS last_day
        FROM
            stg_transaction
    ),
    active AS (
        SELECT DISTINCT
            t.household_key
        FROM
            stg_transaction t
            CROSS JOIN data_end d
        WHERE
            t.day_idx > d.last_day - 28
    ),
    bought AS (
        SELECT DISTINCT
            t.household_key
        FROM
            stg_transaction t
            CROSS JOIN data_end d
        WHERE
            t.product_id = 1082185
            AND t.day_idx > d.last_day - 28
    ),
    ever AS (
        SELECT DISTINCT
            household_key
        FROM
            stg_transaction
        WHERE
            product_id = 1082185
    )
SELECT
    (
        SELECT
            COUNT(DISTINCT household_key)
        FROM
            stg_transaction
    ) AS total_households,
    (
        SELECT
            COUNT(*)
        FROM
            active
    ) AS active_last_28d,
    (
        SELECT
            COUNT(*)
        FROM
            bought
    ) AS bought_last_28d,
    (
        SELECT
            COUNT(*)
        FROM
            ever
    ) AS ever_bought,
    ROUND(
        100.0 * (
            SELECT
                COUNT(*)
            FROM
                bought
        ) / (
            SELECT
                COUNT(*)
            FROM
                active
        ),
        1
    ) AS pct_of_active
FROM
    data_end;

WITH
    banana AS (
        SELECT DISTINCT
            household_key,
            day_idx
        FROM
            stg_transaction
        WHERE
            product_id = 1082185
    ),
    data_end AS (
        SELECT
            MAX(day_idx) AS last_day
        FROM
            stg_transaction
    ),
    ref_days AS (
        SELECT DISTINCT
            week_no * 7 AS ref_day
        FROM
            stg_transaction
    ),
    active_refs AS (
        SELECT DISTINCT
            t.household_key,
            r.ref_day
        FROM
            stg_transaction t
            JOIN ref_days r ON t.day_idx > r.ref_day - 28
            AND t.day_idx <= r.ref_day
            CROSS JOIN data_end d
        WHERE
            r.ref_day <= d.last_day - 28
    ),
    flagged AS (
        SELECT
            a.household_key,
            a.ref_day,
            CASE
                WHEN EXISTS (
                    SELECT
                        1
                    FROM
                        banana b
                    WHERE
                        b.household_key = a.household_key
                        AND b.day_idx > a.ref_day - 28
                        AND b.day_idx <= a.ref_day
                ) THEN 1
                ELSE 0
            END AS bought_prev_28d,
            CASE
                WHEN EXISTS (
                    SELECT
                        1
                    FROM
                        banana b
                    WHERE
                        b.household_key = a.household_key
                        AND b.day_idx > a.ref_day
                        AND b.day_idx <= a.ref_day + 28
                ) THEN 1
                ELSE 0
            END AS bought_next_28d
        FROM
            active_refs a
    )
SELECT
    bought_prev_28d,
    COUNT(*) AS reference_rows,
    ROUND(100.0 * AVG(bought_next_28d), 1) AS pct_buy_next_28d
FROM
    flagged
GROUP BY
    bought_prev_28d
ORDER BY
    bought_prev_28d;

CREATE OR REPLACE TABLE model_table AS
WITH
    banana_products AS (
        SELECT
            product_id
        FROM
            stg_product
        WHERE
            product_id IN (1082185)
    ),
    hh_baskets AS (
        SELECT
            household_key,
            basket_id,
            MIN(day_idx) AS day_idx,
            SUM(sales_value) AS basket_sales
        FROM
            stg_transaction
        GROUP BY
            household_key,
            basket_id
    ),
    hh_first AS (
        SELECT
            household_key,
            MIN(day_idx) AS first_day
        FROM
            hh_baskets
        GROUP BY
            household_key
    ),
    banana_days AS (
        SELECT DISTINCT
            t.household_key,
            t.day_idx
        FROM
            stg_transaction t
            JOIN banana_products b ON t.product_id = b.product_id
    ),
    ref_days AS (
        SELECT DISTINCT
            week_no * 7 AS ref_day
        FROM
            stg_transaction
        WHERE
            week_no * 7 >= 84
            AND week_no * 7 <= (
                SELECT
                    MAX(day_idx)
                FROM
                    stg_transaction
            ) - 28
    ),
    ref_points AS (
        SELECT DISTINCT
            b.household_key,
            r.ref_day
        FROM
            hh_baskets b
            JOIN ref_days r ON b.day_idx > r.ref_day - 28
            AND b.day_idx <= r.ref_day
    ),
    features_general AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(*) FILTER(
                WHERE
                    b.day_idx > p.ref_day - 28
            ) AS baskets_4w,
            COUNT(*) AS baskets_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx > p.ref_day - 28
                ),
                0
            ) AS spend_4w,
            COALESCE(SUM(b.basket_sales), 0) AS spend_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx <= p.ref_day - 28
                ),
                0
            ) AS spend_prev_4w,
            MAX(b.day_idx) AS last_purchase_day
        FROM
            ref_points p
            JOIN hh_baskets b ON b.household_key = p.household_key
            AND b.day_idx > p.ref_day - 56
            AND b.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    ),
    features_banana AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 28
            ) AS banana_days_4w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 56
            ) AS banana_days_8w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 84
            ) AS banana_days_12w,
            COUNT(d.day_idx) AS banana_days_before,
            MAX(d.day_idx) AS last_banana_day
        FROM
            ref_points p
            LEFT JOIN banana_days d ON d.household_key = p.household_key
            AND d.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    ),
    labels AS (
        SELECT
            p.household_key,
            p.ref_day,
            MAX(
                CASE
                    WHEN d.day_idx IS NOT NULL THEN 1
                    ELSE 0
                END
            ) AS banana_next_28d
        FROM
            ref_points p
            LEFT JOIN banana_days d ON d.household_key = p.household_key
            AND d.day_idx > p.ref_day
            AND d.day_idx <= p.ref_day + 28
        GROUP BY
            p.household_key,
            p.ref_day
    )
SELECT
    p.household_key,
    p.ref_day,
    g.baskets_4w,
    g.baskets_8w,
    g.spend_4w,
    g.spend_8w,
    COALESCE(g.spend_8w / NULLIF(g.baskets_8w, 0), 0) AS avg_basket_value_8w,
    g.spend_4w / NULLIF(g.spend_prev_4w, 0) AS spend_trend,
    p.ref_day - g.last_purchase_day AS days_since_last_purchase,
    p.ref_day - f.first_day AS tenure_days,
    bn.banana_days_4w,
    bn.banana_days_8w,
    bn.banana_days_12w,
    bn.banana_days_before,
    CASE
        WHEN bn.last_banana_day IS NULL THEN NULL
        ELSE p.ref_day - bn.last_banana_day
    END AS days_since_last_banana,
    CASE
        WHEN bn.banana_days_4w > 0 THEN 1
        ELSE 0
    END AS bought_prev_28d,
    l.banana_next_28d
FROM
    ref_points p
    JOIN features_general g ON p.household_key = g.household_key
    AND p.ref_day = g.ref_day
    JOIN features_banana bn ON p.household_key = bn.household_key
    AND p.ref_day = bn.ref_day
    JOIN labels l ON p.household_key = l.household_key
    AND p.ref_day = l.ref_day
    JOIN hh_first f ON p.household_key = f.household_key;

SELECT
    *
FROM
    model_table
LIMIT
    10;

SELECT
    COUNT(*) AS rows_total,
    COUNT(DISTINCT household_key) AS households,
    COUNT(DISTINCT ref_day) AS ref_days,
    ROUND(100.0 * AVG(banana_next_28d), 1) AS positive_pct
FROM
    model_table;

SELECT
    COUNT(*) FILTER(
        WHERE
            days_since_last_purchase < 0
    ) AS negative_recency,
    COUNT(*) FILTER(
        WHERE
            days_since_last_banana < 0
    ) AS negative_banana_recency,
    COUNT(*) - COUNT(DISTINCT (household_key, ref_day)) AS duplicate_keys
FROM
    model_table;

SELECT
    bought_prev_28d,
    COUNT(*) AS reference_rows,
    ROUND(100.0 * AVG(banana_next_28d), 1) AS pct_buy_next_28d
FROM
    model_table
GROUP BY
    bought_prev_28d
ORDER BY
    bought_prev_28d;

COPY model_table TO 'C:/Users/Albostan/.gemini/antigravity/scratch/model_table.parquet' (FORMAT PARQUET);

SELECT
    COUNT(*) AS banana_rows,
    COUNT(*) FILTER(
        WHERE
            quantity <= 0
    ) AS non_positive_quantity_rows,
    COUNT(*) FILTER(
        WHERE
            quantity <= 0
            AND sales_value > 0
    ) AS zero_or_negative_qty_positive_sales
FROM
    stg_transaction
WHERE
    product_id = 1082185;

CREATE OR REPLACE TABLE model_table AS
WITH
    banana_products AS (
        SELECT
            product_id
        FROM
            stg_product
        WHERE
            product_id IN (1082185)
    ),
    hh_baskets AS (
        SELECT
            household_key,
            basket_id,
            MIN(day_idx) AS day_idx,
            SUM(sales_value) AS basket_sales
        FROM
            stg_transaction
        GROUP BY
            household_key,
            basket_id
    ),
    hh_first AS (
        SELECT
            household_key,
            MIN(day_idx) AS first_day
        FROM
            hh_baskets
        GROUP BY
            household_key
    ),
    banana_days AS (
        SELECT DISTINCT
            t.household_key,
            t.day_idx
        FROM
            stg_transaction t
            JOIN banana_products b ON t.product_id = b.product_id
        WHERE
            t.quantity > 0
    ),
    ref_days AS (
        SELECT DISTINCT
            week_no * 7 AS ref_day
        FROM
            stg_transaction
        WHERE
            week_no * 7 >= 84
            AND week_no * 7 <= (
                SELECT
                    MAX(day_idx)
                FROM
                    stg_transaction
            ) - 28
    ),
    ref_points AS (
        SELECT DISTINCT
            b.household_key,
            r.ref_day
        FROM
            hh_baskets b
            JOIN ref_days r ON b.day_idx > r.ref_day - 28
            AND b.day_idx <= r.ref_day
    ),
    features_general AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(*) FILTER(
                WHERE
                    b.day_idx > p.ref_day - 28
            ) AS baskets_4w,
            COUNT(*) AS baskets_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx > p.ref_day - 28
                ),
                0
            ) AS spend_4w,
            COALESCE(SUM(b.basket_sales), 0) AS spend_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx <= p.ref_day - 28
                ),
                0
            ) AS spend_prev_4w,
            MAX(b.day_idx) AS last_purchase_day
        FROM
            ref_points p
            JOIN hh_baskets b ON b.household_key = p.household_key
            AND b.day_idx > p.ref_day - 56
            AND b.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    ),
    features_banana AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 28
            ) AS banana_days_4w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 56
            ) AS banana_days_8w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 84
            ) AS banana_days_12w,
            COUNT(d.day_idx) AS banana_days_before,
            MAX(d.day_idx) AS last_banana_day
        FROM
            ref_points p
            LEFT JOIN banana_days d ON d.household_key = p.household_key
            AND d.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    ),
    labels AS (
        SELECT
            p.household_key,
            p.ref_day,
            CASE
                WHEN EXISTS (
                    SELECT
                        1
                    FROM
                        banana_days d
                    WHERE
                        d.household_key = p.household_key
                        AND d.day_idx > p.ref_day
                        AND d.day_idx <= p.ref_day + 28
                ) THEN 1
                ELSE 0
            END AS banana_next_28d
        FROM
            ref_points p
    )
SELECT
    p.household_key,
    p.ref_day,
    g.baskets_4w,
    g.baskets_8w,
    g.spend_4w,
    g.spend_8w,
    COALESCE(g.spend_8w / NULLIF(g.baskets_8w, 0), 0) AS avg_basket_value_8w,
    g.spend_4w / NULLIF(g.spend_prev_4w, 0) AS spend_trend,
    p.ref_day - g.last_purchase_day AS days_since_last_purchase,
    p.ref_day - f.first_day AS tenure_days,
    bn.banana_days_4w,
    bn.banana_days_8w,
    bn.banana_days_12w,
    bn.banana_days_before,
    CASE
        WHEN bn.last_banana_day IS NULL THEN NULL
        ELSE p.ref_day - bn.last_banana_day
    END AS days_since_last_banana,
    CASE
        WHEN bn.banana_days_4w > 0 THEN 1
        ELSE 0
    END AS bought_prev_28d,
    l.banana_next_28d
FROM
    ref_points p
    JOIN features_general g ON p.household_key = g.household_key
    AND p.ref_day = g.ref_day
    JOIN features_banana bn ON p.household_key = bn.household_key
    AND p.ref_day = bn.ref_day
    JOIN labels l ON p.household_key = l.household_key
    AND p.ref_day = l.ref_day
    JOIN hh_first f ON p.household_key = f.household_key;

SELECT
    *
FROM
    model_table
LIMIT
    10;

SELECT
    COUNT(*) AS rows_total,
    COUNT(DISTINCT household_key) AS households,
    ROUND(100.0 * AVG(banana_next_28d), 1) AS positive_pct,
    COUNT(*) FILTER(
        WHERE
            banana_days_4w > banana_days_8w
            OR banana_days_8w > banana_days_12w
            OR banana_days_12w > banana_days_before
    ) AS window_violations,
    COUNT(*) FILTER(
        WHERE
            baskets_4w > baskets_8w
    ) AS basket_violations,
    COUNT(*) FILTER(
        WHERE
            bought_prev_28d = 1
            AND days_since_last_banana > 28
    ) AS recency_mismatch,
    COUNT(*) FILTER(
        WHERE
            days_since_last_purchase < 0
            OR days_since_last_banana < 0
    ) AS negative_recency,
    COUNT(*) - COUNT(DISTINCT (household_key, ref_day)) AS duplicate_keys
FROM
    model_table;

SELECT
    COUNT(*) AS label_mismatches
FROM
    model_table m
WHERE
    m.banana_next_28d <> CASE
        WHEN EXISTS (
            SELECT
                1
            FROM
                stg_transaction t
            WHERE
                t.household_key = m.household_key
                AND t.product_id = 1082185
                AND t.quantity > 0
                AND t.day_idx > m.ref_day
                AND t.day_idx <= m.ref_day + 28
        ) THEN 1
        ELSE 0
    END;

COPY model_table TO 'C:/Users/Albostan/.gemini/antigravity/scratch/model_table.parquet' (FORMAT PARQUET, OVERWRITE_OR_IGNORE);

CREATE OR REPLACE TABLE scoring_table AS
WITH
    banana_products AS (
        SELECT
            product_id
        FROM
            stg_product
        WHERE
            product_id IN (1082185)
    ),
    hh_baskets AS (
        SELECT
            household_key,
            basket_id,
            MIN(day_idx) AS day_idx,
            SUM(sales_value) AS basket_sales
        FROM
            stg_transaction
        GROUP BY
            household_key,
            basket_id
    ),
    hh_first AS (
        SELECT
            household_key,
            MIN(day_idx) AS first_day
        FROM
            hh_baskets
        GROUP BY
            household_key
    ),
    banana_days AS (
        SELECT DISTINCT
            t.household_key,
            t.day_idx
        FROM
            stg_transaction t
            JOIN banana_products b ON t.product_id = b.product_id
        WHERE
            t.quantity > 0
    ),
    r AS (
        SELECT
            MAX(day_idx) AS ref_day
        FROM
            stg_transaction
    ),
    pts AS (
        SELECT DISTINCT
            b.household_key,
            r.ref_day
        FROM
            hh_baskets b
            CROSS JOIN r
        WHERE
            b.day_idx > r.ref_day - 28
            AND b.day_idx <= r.ref_day
    ),
    g AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(*) FILTER(
                WHERE
                    b.day_idx > p.ref_day - 28
            ) AS baskets_4w,
            COUNT(*) AS baskets_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx > p.ref_day - 28
                ),
                0
            ) AS spend_4w,
            COALESCE(SUM(b.basket_sales), 0) AS spend_8w,
            COALESCE(
                SUM(b.basket_sales) FILTER(
                    WHERE
                        b.day_idx <= p.ref_day - 28
                ),
                0
            ) AS spend_prev_4w,
            MAX(b.day_idx) AS last_purchase_day
        FROM
            pts p
            JOIN hh_baskets b ON b.household_key = p.household_key
            AND b.day_idx > p.ref_day - 56
            AND b.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    ),
    bn AS (
        SELECT
            p.household_key,
            p.ref_day,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 28
            ) AS banana_days_4w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 56
            ) AS banana_days_8w,
            COUNT(d.day_idx) FILTER(
                WHERE
                    d.day_idx > p.ref_day - 84
            ) AS banana_days_12w,
            COUNT(d.day_idx) AS banana_days_before,
            MAX(d.day_idx) AS last_banana_day
        FROM
            pts p
            LEFT JOIN banana_days d ON d.household_key = p.household_key
            AND d.day_idx <= p.ref_day
        GROUP BY
            p.household_key,
            p.ref_day
    )
SELECT
    p.household_key,
    p.ref_day,
    g.baskets_4w,
    g.baskets_8w,
    g.spend_4w,
    g.spend_8w,
    COALESCE(g.spend_8w / NULLIF(g.baskets_8w, 0), 0) AS avg_basket_value_8w,
    g.spend_4w / NULLIF(g.spend_prev_4w, 0) AS spend_trend,
    p.ref_day - g.last_purchase_day AS days_since_last_purchase,
    p.ref_day - f.first_day AS tenure_days,
    bn.banana_days_4w,
    bn.banana_days_8w,
    bn.banana_days_12w,
    bn.banana_days_before,
    CASE
        WHEN bn.last_banana_day IS NULL THEN NULL
        ELSE p.ref_day - bn.last_banana_day
    END AS days_since_last_banana,
    CASE
        WHEN bn.banana_days_4w > 0 THEN 1
        ELSE 0
    END AS bought_prev_28d
FROM
    pts p
    JOIN g ON p.household_key = g.household_key
    AND p.ref_day = g.ref_day
    JOIN bn ON p.household_key = bn.household_key
    AND p.ref_day = bn.ref_day
    JOIN hh_first f ON p.household_key = f.household_key;

SELECT
    COUNT(*) AS households_scored,
    MIN(ref_day) AS ref_day,
    COUNT(*) FILTER(
        WHERE
            days_since_last_purchase < 0
    ) AS negative_recency
FROM
    scoring_table;

SELECT
    *
FROM
    scoring_table
LIMIT
    10;
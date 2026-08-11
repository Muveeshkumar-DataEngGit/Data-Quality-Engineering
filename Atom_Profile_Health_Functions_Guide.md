# SQL Functions Used in Atom_Profile_Health.sql

A comprehensive guide to every SQL function, operator, and clause used in the Atom Profile Health scoring framework, with explanations and examples.

---

## Table of Contents

1. [COALESCE](#1-coalesce)
2. [NULLIF](#2-nullif)
3. [NVL](#3-nvl)
4. [TRIM](#4-trim)
5. [UPPER](#5-upper)
6. [CONCAT / ||](#6-concat--)
7. [LENGTH](#7-length)
8. [SPLIT](#8-split)
9. [SPLIT_PART](#9-split_part)
10. [ARRAY_SIZE](#10-array_size)
11. [ARRAY_CONSTRUCT](#11-array_construct)
12. [ARRAY_COMPACT](#12-array_compact)
13. [ARRAY_TO_STRING](#13-array_to_string)
14. [REGEXP_REPLACE](#14-regexp_replace)
15. [REGEXP_LIKE / RLIKE](#15-regexp_like--rlike)
16. [LIKE](#16-like)
17. [IFF](#17-iff)
18. [CASE WHEN](#18-case-when)
19. [SUM](#19-sum)
20. [MAX](#20-max)
21. [COUNT](#21-count)
22. [ROUND](#22-round)
23. [LISTAGG](#23-listagg)
24. [ROW_NUMBER](#24-row_number)
25. [QUALIFY](#25-qualify)
26. [DATE](#26-date)
27. [VALUES Clause](#27-values-clause-table-constructor)
28. [WITH (CTEs)](#28-with-common-table-expressions--ctes)
29. [LEFT JOIN](#29-left-join)
30. [INNER JOIN](#30-inner-join)
31. [UNION ALL](#31-union-all)
32. [GROUP BY](#32-group-by)
33. [ORDER BY](#33-order-by)
34. [DISTINCT](#34-distinct)
35. [IN / NOT IN](#35-in--not-in)
36. [IS NULL / IS NOT NULL](#36-is-null--is-not-null)
37. [WITHIN GROUP (ORDER BY)](#37-within-group-order-by-)
38. [PARTITION BY](#38-partition-by-window-function-clause)

---

## 1. COALESCE

Returns the first non-NULL value from a list of expressions. Accepts any number of arguments.

**Usage in file:** Filling missing identifiers from multiple fallback sources.

```sql
COALESCE(H.SERIES_IDENTIFIER, SL.SERIES_IDENTIFIER, SSL.SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
```

**Example:**

```sql
SELECT COALESCE(NULL, NULL, 'fallback_value');
-- Result: 'fallback_value'

SELECT COALESCE('first', 'second', 'third');
-- Result: 'first'

SELECT COALESCE(phone, mobile, 'No contact') AS contact_number
FROM customers;
```

---

## 2. NULLIF

Returns NULL if the two arguments are equal; otherwise returns the first argument. Commonly used to convert empty strings or sentinel values to NULL.

**Usage in file:** Converting empty/whitespace-only strings to NULL so completeness checks treat them as missing.

```sql
NULLIF(TRIM(ATTRIBUTE_VALUE), '')
```

**Example:**

```sql
SELECT NULLIF('', '');
-- Result: NULL

SELECT NULLIF('Hello', '');
-- Result: 'Hello'

SELECT NULLIF(0, 0);
-- Result: NULL

-- Practical: treat blanks as NULL
SELECT NULLIF(TRIM(city), '') AS city FROM addresses;
```

---

## 3. NVL

Returns the second argument if the first is NULL. Equivalent to `COALESCE` with exactly two arguments. Snowflake-specific shorthand.

**Usage in file:** Providing default values for potentially NULL columns.

```sql
NVL(PARENT_MPM_NUMBER, 'NO_PARENT')
```

**Example:**

```sql
SELECT NVL(NULL, 'default');
-- Result: 'default'

SELECT NVL(phone_number, 'N/A') AS phone FROM customers;

SELECT NVL(discount_pct, 0) * price AS discount_amount FROM orders;
```

---

## 4. TRIM

Removes leading and trailing whitespace (or specified characters) from a string.

**Usage in file:** Cleaning attribute values before null/empty checks.

```sql
COALESCE(TRIM(LIBRARY_TITLE_SHORT), '') = ''
```

**Example:**

```sql
SELECT TRIM('   hello   ');
-- Result: 'hello'

SELECT TRIM('***hello***', '*');
-- Result: 'hello'

SELECT TRIM('  ' || NULL);
-- Result: NULL (TRIM of NULL is NULL)
```

---

## 5. UPPER

Converts all characters in a string to uppercase.

**Usage in file:** Normalising IP type values and title text for case-insensitive comparison.

```sql
UPPER(IP_TYPE)
UPPER(LIBRARY_TITLE_SHORT) LIKE 'THE %'
```

**Example:**

```sql
SELECT UPPER('hello world');
-- Result: 'HELLO WORLD'

SELECT * FROM titles WHERE UPPER(genre) = 'DRAMA';
```

---

## 6. CONCAT / ||

Joins two or more strings together. Snowflake supports both the `CONCAT()` function and the `||` operator.

**Usage in file:** Building tagged defect labels and composite display strings.

```sql
CONCAT('[', 'COLUMN: ', ATTRIBUTE_NAME, ', ', 'CRITICALITY: ', COALESCE(CRITICALITY,'NA'), ']')
```

**Example:**

```sql
SELECT CONCAT('Hello', ' ', 'World');
-- Result: 'Hello World'

SELECT first_name || ' ' || last_name AS full_name FROM employees;

-- CONCAT with multiple args
SELECT CONCAT('[', col_name, ':', status, ']') AS tag FROM audit_log;
```

---

## 7. LENGTH

Returns the number of characters in a string (not bytes).

**Usage in file:** Checking if title strings exceed a character limit (40 characters).

```sql
CASE WHEN LENGTH(LIBRARY_TITLE_SHORT) > 40 THEN 1 ELSE 0 END AS F_LTS_OVER_40
```

**Example:**

```sql
SELECT LENGTH('Hello');
-- Result: 5

SELECT LENGTH('');
-- Result: 0

SELECT title, LENGTH(title) AS title_len
FROM movies
WHERE LENGTH(title) > 100;
```

---

## 8. SPLIT

Splits a string on a specified delimiter and returns an ARRAY of the parts.

**Usage in file:** Splitting pipe-delimited column lists to count how many attributes are present/missing.

```sql
SPLIT(PRESENT_COLUMNS_DIS, '|')
```

**Example:**

```sql
SELECT SPLIT('a|b|c', '|');
-- Result: ["a", "b", "c"]

SELECT SPLIT('one,two,three', ',');
-- Result: ["one", "two", "three"]

-- Combined with ARRAY_SIZE to count elements
SELECT ARRAY_SIZE(SPLIT('red|green|blue', '|'));
-- Result: 3
```

---

## 9. SPLIT_PART

Extracts a specific part from a delimited string by position (1-based index).

**Usage in file:** Extracting the second segment of a profile ID path.

```sql
SPLIT_PART(P.PROFILE_ID, '/', 2) AS ATOM_SEARCH
```

**Example:**

```sql
SELECT SPLIT_PART('db/schema/table', '/', 1);
-- Result: 'db'

SELECT SPLIT_PART('db/schema/table', '/', 2);
-- Result: 'schema'

SELECT SPLIT_PART('db/schema/table', '/', 3);
-- Result: 'table'

SELECT SPLIT_PART('2024-01-15', '-', 2);
-- Result: '01'
```

---

## 10. ARRAY_SIZE

Returns the number of elements in an ARRAY.

**Usage in file:** Counting how many pipe-separated attributes are present or missing.

```sql
ARRAY_SIZE(SPLIT(PRESENT_COLUMNS_DIS, '|')) AS NUM_OF_COL_PRES,
ARRAY_SIZE(SPLIT(MISSING_COLUMNS_DIS, '|')) AS NUM_OF_COL_MISS
```

**Example:**

```sql
SELECT ARRAY_SIZE(ARRAY_CONSTRUCT(1, 2, 3));
-- Result: 3

SELECT ARRAY_SIZE(SPLIT('a|b|c|d', '|'));
-- Result: 4

SELECT ARRAY_SIZE(NULL);
-- Result: NULL
```

---

## 11. ARRAY_CONSTRUCT

Creates an ARRAY from the provided arguments. NULL values are included in the array.

**Usage in file:** Building a list of issue flags, where each element is either a label string or NULL (to be compacted later).

```sql
ARRAY_CONSTRUCT(
    IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL),
    IFF(F_TITLE_HAS_YEAR   = 1, 'TITLE:Release_Year', NULL),
    IFF(F_LTS_INCOMPLETE   = 1, 'LTS:Incomplete', NULL),
    IFF(F_LTS_OVER_40      = 1, 'LTS:Over_40', NULL)
)
```

**Example:**

```sql
SELECT ARRAY_CONSTRUCT(1, 2, 3);
-- Result: [1, 2, 3]

SELECT ARRAY_CONSTRUCT('a', NULL, 'c');
-- Result: ["a", null, "c"]

SELECT ARRAY_CONSTRUCT(name, email, phone) FROM contacts;
```

---

## 12. ARRAY_COMPACT

Removes all NULL values and JSON null values from an ARRAY, returning a new compacted ARRAY.

**Usage in file:** Stripping out NULL entries from the issue flags array so only actual issues remain.

```sql
ARRAY_COMPACT(
    ARRAY_CONSTRUCT(
        IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL),
        IFF(F_LTS_OVER_40      = 1, 'LTS:Over_40', NULL)
    )
)
-- If only the first flag fired: ["TITLE:Incomplete"]
```

**Example:**

```sql
SELECT ARRAY_COMPACT(ARRAY_CONSTRUCT(1, NULL, 3, NULL, 5));
-- Result: [1, 3, 5]

SELECT ARRAY_COMPACT(ARRAY_CONSTRUCT('a', NULL, 'c'));
-- Result: ["a", "c"]

SELECT ARRAY_COMPACT(ARRAY_CONSTRUCT(NULL, NULL));
-- Result: []
```

---

## 13. ARRAY_TO_STRING

Converts an ARRAY to a single string with a specified separator between elements.

**Usage in file:** Joining the compacted issue list into a semicolon-delimited display string.

```sql
ARRAY_TO_STRING(
    ARRAY_COMPACT(
        ARRAY_CONSTRUCT(
            IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL),
            IFF(F_LTS_OVER_40      = 1, 'LTS:Over_40', NULL)
        )
    ),
    '; '
) AS Command_Issue
-- Result example: "TITLE:Incomplete; LTS:Over_40"
```

**Example:**

```sql
SELECT ARRAY_TO_STRING(ARRAY_CONSTRUCT('red', 'green', 'blue'), ', ');
-- Result: 'red, green, blue'

SELECT ARRAY_TO_STRING(ARRAY_CONSTRUCT(1, 2, 3), ' | ');
-- Result: '1 | 2 | 3'

SELECT ARRAY_TO_STRING(ARRAY_COMPACT(ARRAY_CONSTRUCT('a', NULL, 'c')), '-');
-- Result: 'a-c'
```

---

## 14. REGEXP_REPLACE

Replaces substrings matching a regular expression pattern with a replacement string.

**Usage in file:** (1) Removing smart quotes from titles. (2) Stripping non-ASCII characters. (3) Trimming leading/trailing pipe delimiters from concatenated column lists.

```sql
-- Remove smart quotes
REGEXP_REPLACE(LIBRARY_TITLE_SHORT, '[\u2018\u2019\u201C\u201D]', '')

-- Remove non-ASCII
REGEXP_REPLACE(clean_title, '[^ -~]', '')

-- Trim leading/trailing pipes
REGEXP_REPLACE(PRESENT_COLUMNS, '^([[:space:]]*[|][[:space:]]*)+|([[:space:]]*[|][[:space:]]*)+$', '')
```

**Example:**

```sql
-- Remove all digits
SELECT REGEXP_REPLACE('abc123def456', '[0-9]', '');
-- Result: 'abcdef'

-- Replace multiple spaces with single space
SELECT REGEXP_REPLACE('hello    world', '\\s+', ' ');
-- Result: 'hello world'

-- Remove special characters
SELECT REGEXP_REPLACE('price: $100.00!', '[^a-zA-Z0-9 ]', '');
-- Result: 'price 10000'
```

---

## 15. REGEXP_LIKE / RLIKE

Returns TRUE if a string matches a regular expression pattern. `RLIKE` is an alias for `REGEXP_LIKE` in Snowflake.

**Usage in file:** (1) Detecting special characters in titles. (2) Detecting year patterns embedded in title text. (3) Detecting season/episode numbering patterns.

```sql
-- Check for disallowed special characters
REGEXP_LIKE(LIBRARY_TITLE_SHORT, $$[^[:alnum:][:space:].,:;!?#"'\\()&/\\[\\]-]$$)

-- Check if title contains a year (1900-2099)
TITLE RLIKE '(^|[^0-9])(19|20)[0-9]{2}([^0-9]|$)'

-- Check for season numbering pattern
REGEXP_LIKE(UPPER(LIBRARY_TITLE_FULL), 'S\\d')
```

**Example:**

```sql
SELECT REGEXP_LIKE('Hello123', '^[A-Za-z]+[0-9]+$');
-- Result: TRUE

SELECT 'test2024data' RLIKE '(19|20)[0-9]{2}';
-- Result: TRUE

SELECT * FROM titles WHERE RLIKE(title, '^The\\s');
```

---

## 16. LIKE

Pattern matching operator using `%` (any characters) and `_` (single character) wildcards.

**Usage in file:** Detecting leading articles ("THE", "AN", "A") at the start of titles, and checking for keywords like "EPISODE" or "SEASON".

```sql
UPPER(LIBRARY_TITLE_SHORT) LIKE 'THE %'
UPPER(LIBRARY_TITLE_SHORT) LIKE 'AN %'
UPPER(TITLE) LIKE '%EPISODE%'
UPPER(TITLE) NOT LIKE '%SEASON%'
```

**Example:**

```sql
-- Starts with 'The '
SELECT * FROM movies WHERE title LIKE 'The %';

-- Contains 'war' anywhere
SELECT * FROM movies WHERE UPPER(title) LIKE '%WAR%';

-- Exactly 5 characters
SELECT * FROM codes WHERE code LIKE '_____';

-- NOT LIKE (exclusion)
SELECT * FROM titles WHERE title NOT LIKE '%Test%';
```

---

## 17. IFF

Snowflake-specific inline conditional function. Returns the second argument if the condition is true, otherwise the third. Simpler alternative to `CASE WHEN` for two-branch logic.

**Usage in file:** (1) Scoring: assigning weight if attribute is populated. (2) Building issue flag arrays (returns label string or NULL).

```sql
-- Scoring
IFF(NULLIF(TRIM(ATTRIBUTE_VALUE), '') IS NOT NULL, weight, 0) AS EARNED_WEIGHT

-- Issue flagging
IFF(F_TITLE_INCOMPLETE = 1, 'TITLE:Incomplete', NULL)
IFF(F_LTS_OVER_40 = 1, 'LTS:Over_40', NULL)
```

**Example:**

```sql
SELECT IFF(10 > 5, 'Yes', 'No');
-- Result: 'Yes'

SELECT IFF(status = 'active', 1, 0) AS is_active FROM users;

SELECT IFF(price IS NULL, 0.00, price * qty) AS line_total FROM orders;
```

---

## 18. CASE WHEN

Multi-branch conditional expression. Evaluates conditions in order and returns the result for the first true condition. Supports both simple (`CASE expr WHEN val`) and searched (`CASE WHEN condition`) forms.

**Usage in file:** (1) Classifying IP types. (2) Computing the final health verdict. (3) Counting conditional flags (SUM + CASE pattern). (4) Assigning total possible weights per IP type.

```sql
-- IP type classification
CASE
    WHEN ATTRIBUTE_VALUE IN ('Series') THEN 'SERIES'
    WHEN ATTRIBUTE_VALUE IN ('Season') THEN 'SEASON'
    WHEN ATTRIBUTE_VALUE IN ('Episode') THEN 'EPISODE'
    ELSE 'UNKNOWN'
END

-- Health verdict
CASE
    WHEN HIERARCHY_STATUS = 'ORPHAN' THEN 'Critical'
    WHEN COMPLETENESS_SCORE < 50 THEN 'Poor'
    WHEN COMPLETENESS_SCORE < 80 THEN 'Fair'
    ELSE 'Good'
END AS OVERALL_HEALTH

-- Conditional counting
SUM(CASE WHEN LENGTH(LIBRARY_TITLE_SHORT) > 40 THEN 1 ELSE 0 END) AS Over_40_Char_limit
```

**Example:**

```sql
SELECT
    product_name,
    CASE
        WHEN quantity = 0 THEN 'Out of Stock'
        WHEN quantity < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM inventory;
```

---

## 19. SUM

Aggregate function that returns the total of a numeric expression across rows in a group.

**Usage in file:** (1) Summing earned weights and possible weights. (2) Conditional counting via `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`. (3) Summing parent link counts.

```sql
SUM(EARNED_WEIGHT) AS TOTAL_EARNED
SUM(weight) AS TOTAL_POSSIBLE
SUM(CASE WHEN LIBRARY_TITLE_FULL IS NULL THEN 1 ELSE 0 END) AS Incomplete_Titles
SUM(PARENT_COUNT) - 1 AS ADJUSTED_PARENTS
```

**Example:**

```sql
SELECT department, SUM(salary) AS total_salary
FROM employees
GROUP BY department;

-- Conditional counting
SELECT SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failure_count
FROM jobs;
```

---

## 20. MAX

Aggregate function that returns the maximum value from a set of values.

**Usage in file:** Getting the representative identifier from grouped records.

```sql
MAX(SERIES_IDENTIFIER) AS SERIES_IDENTIFIER
MAX(DATE(RELTIO_LAST_UPDATED_TS)) AS LATEST_UPDATE
```

**Example:**

```sql
SELECT department, MAX(salary) AS highest_salary FROM employees GROUP BY department;

SELECT MAX(created_at) AS most_recent FROM events;
```

---

## 21. COUNT

Aggregate function that counts rows (`COUNT(*)`) or non-NULL values (`COUNT(expr)`), with optional `DISTINCT`.

**Usage in file:** (1) Counting total records. (2) Counting populated attributes for completeness percentage. (3) Counting distinct identifiers. (4) Counting child records (fan-out).

```sql
COUNT(*) AS TOTAL_ROWS
COUNT(LIBRARY_TITLE_FULL) / COUNT(*) * 100 AS pct_populated
COUNT(DISTINCT NODE_IDENTIFIER) AS UNIQUE_NODES
COUNT(B.NODE_IDENTIFIER) AS PARENT_COUNT
```

**Example:**

```sql
SELECT COUNT(*) FROM orders;                        -- all rows
SELECT COUNT(email) FROM users;                     -- non-NULL emails
SELECT COUNT(DISTINCT country) FROM customers;      -- unique countries
```

---

## 22. ROUND

Rounds a numeric value to a specified number of decimal places.

**Usage in file:** Rounding completeness percentage scores to 1 or 2 decimal places.

```sql
ROUND(COUNT(LIBRARY_TITLE_FULL) / COUNT(*) * 100, 1) AS pct
ROUND((SUM(EARNED_WEIGHT) / SUM(weight)) * 100, 2) AS COMPLETENESS_SCORE
```

**Example:**

```sql
SELECT ROUND(3.14159, 2);    -- Result: 3.14
SELECT ROUND(123.456, 0);    -- Result: 123
SELECT ROUND(2.5, 0);        -- Result: 3
SELECT ROUND(99.999, 1);     -- Result: 100.0
```

---

## 23. LISTAGG

Aggregate function that concatenates values from multiple rows into a single delimited string.

**Usage in file:** Building pipe-separated lists of present and missing attribute names per record.

```sql
LISTAGG(IMPORTANT_COLUMS, ' | ')
    WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS,

LISTAGG(IMPORTANT_COLUMS_1, ' | ')
    WITHIN GROUP (ORDER BY IMPORTANT_COLUMS_1) AS MISSING_COLUMNS
```

**Example:**

```sql
SELECT
    department,
    LISTAGG(employee_name, ', ') WITHIN GROUP (ORDER BY employee_name) AS team
FROM employees
GROUP BY department;
-- Result: 'Engineering' | 'Alice, Bob, Charlie'

-- With DISTINCT (Snowflake supports this)
SELECT LISTAGG(DISTINCT status, '; ') WITHIN GROUP (ORDER BY status) FROM orders;
```

---

## 24. ROW_NUMBER

Window function that assigns a unique sequential integer to each row within a partition, starting at 1.

**Usage in file:** Deduplicating records by selecting the most recent row per MPM_NUMBER.

```sql
ROW_NUMBER() OVER (
    PARTITION BY SEASON_MPM_NUMBER
    ORDER BY SEASON_IDENTIFIER DESC
) AS RN
-- Then filter WHERE RN = 1
```

**Example:**

```sql
-- Get the latest order per customer
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM orders
)
WHERE rn = 1;
```

---

## 25. QUALIFY

Snowflake-specific clause that filters the result of window functions directly, without requiring a subquery. Analogous to `HAVING` for aggregates.

**Usage in file:** Keeping only the first row per partition after ROW_NUMBER ranking (implied by the deduplication pattern).

```sql
SELECT *
FROM source_table
QUALIFY ROW_NUMBER() OVER (PARTITION BY MPM_NUMBER ORDER BY updated_ts DESC) = 1
```

**Example:**

```sql
-- Latest order per customer, no subquery needed
SELECT customer_id, order_date, amount
FROM orders
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) = 1;

-- Top 3 products per category by revenue
SELECT category, product, revenue
FROM sales
QUALIFY ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) <= 3;
```

---

## 26. DATE

Converts a timestamp or string to a DATE value (year-month-day only, no time component).

**Usage in file:** Comparing profile update dates by casting timestamps to dates.

```sql
WHERE DATE(PROFILE_UPDATED_DATE) = (
    SELECT MAX(DATE(RELTIO_LAST_UPDATED_TS))
    FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE
)
```

**Example:**

```sql
SELECT DATE('2024-03-15 14:30:00');
-- Result: 2024-03-15

SELECT DATE(CURRENT_TIMESTAMP());
-- Result: today's date

SELECT * FROM events WHERE DATE(created_at) = '2024-01-01';
```

---

## 27. VALUES Clause (Table Constructor)

Creates an inline table of literal values without needing a physical table. Used inside a CTE with column aliases.

**Usage in file:** Defining the attribute applicability/weight matrix that governs which attributes are required for each IP type.

```sql
SELECT * FROM (
    VALUES
        ('Series',  'LIBRARY_TITLE_FULL',  'Mandatory', 'Critical', 10),
        ('Series',  'LIBRARY_TITLE_SHORT', 'Mandatory', 'Critical',  9),
        ('Season',  'PI_UUID',             'Mandatory', 'Critical', 10),
        ('Episode', 'MPM_NUMBER',          'Mandatory', 'Critical',  8)
) AS t(Ip_type, Attribute_name, Applicability, Criticality, weight)
```

**Example:**

```sql
SELECT * FROM (
    VALUES
        ('US', 'Dollar', 'USD'),
        ('UK', 'Pound',  'GBP'),
        ('JP', 'Yen',    'JPY')
) AS t(country, currency_name, code);
```

---

## 28. WITH (Common Table Expressions / CTEs)

Defines named temporary result sets that can be referenced in subsequent CTEs or the final SELECT. Enables step-by-step data transformation in a readable pipeline.

**Usage in file:** The entire framework is structured as a chain of CTEs: `Applicability_Matrix` -> `ATTRIBUTES_Completeness` -> `IP_TYPES` -> `ATTRIBUTES_Completeness2` -> `TOTAL_WEIGHT` -> `HIERARCHY_INFO` -> `HEIRARCHY_STATE` -> `PARENT_LINK` -> `STATUS` -> `PROFILE_SUMMARY` -> `IMPORTANT_FEATURES` -> `PROFILE_HEALTH_SUMMARY`.

```sql
WITH
Applicability_Matrix AS (SELECT ... FROM VALUES ...),
ATTRIBUTES_Completeness AS (SELECT ... UNION ALL ...),
TOTAL_WEIGHT AS (SELECT ... FROM ... JOIN Applicability_Matrix ...)
SELECT * FROM TOTAL_WEIGHT;
```

**Example:**

```sql
WITH active_users AS (
    SELECT * FROM users WHERE status = 'active'
),
user_orders AS (
    SELECT u.id, COUNT(*) AS order_count
    FROM active_users u
    JOIN orders o ON u.id = o.user_id
    GROUP BY u.id
)
SELECT * FROM user_orders WHERE order_count > 5;
```

---

## 29. LEFT JOIN

Returns all rows from the left table and matched rows from the right table. Unmatched rows produce NULL for right-side columns.

**Usage in file:** (1) Joining attribute values to the rules matrix (unmatched = missing attribute). (2) Joining hierarchy info to title tables. (3) Joining parent link data.

```sql
FROM ATTRIBUTES_Completeness2 AC
LEFT JOIN Applicability_Matrix AM
    ON AC.IP_TYPE = UPPER(AM.Ip_type)
    AND AC.ATTRIBUTE_NAME = AM.Attribute_name
```

**Example:**

```sql
SELECT c.name, o.order_id, o.total
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id;
-- Customers without orders appear with NULL order columns
```

---

## 30. INNER JOIN

Returns only rows that have matching values in both tables.

**Usage in file:** Joining the profile summary with the data source to ensure only records existing in both are included.

```sql
FROM BOLT_MSC_CDS_PROD.ATOM_BI.D_TITLE T
INNER JOIN PROFILE_SUMMARY P
    ON T.NODE_IDENTIFIER = P.NODE_IDENTIFIER
```

**Example:**

```sql
SELECT e.name, d.department_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;
-- Only employees with a valid department appear
```

---

## 31. UNION ALL

Combines result sets from multiple SELECT statements vertically. Unlike `UNION`, it keeps all duplicates (no deduplication overhead).

**Usage in file:** Unpivoting wide attribute columns into a tall (name, value) format — one SELECT per attribute column, stacked with UNION ALL.

```sql
SELECT NODE_IDENTIFIER, 'LIBRARY_TITLE_FULL' AS Attribute_name, LIBRARY_TITLE_FULL AS Attribute_value
FROM source
UNION ALL
SELECT NODE_IDENTIFIER, 'LIBRARY_TITLE_SHORT', LIBRARY_TITLE_SHORT
FROM source
UNION ALL
SELECT NODE_IDENTIFIER, 'PI_UUID', PI_UUID
FROM source
UNION ALL
SELECT NODE_IDENTIFIER, 'MPM_NUMBER', MPM_NUMBER
FROM source
-- ... repeated for each attribute
```

**Example:**

```sql
-- Stack current and archived records
SELECT id, name, 'current' AS source FROM current_users
UNION ALL
SELECT id, name, 'archive' AS source FROM archived_users;

-- UNION ALL vs UNION:
-- UNION ALL: keeps duplicates, faster
-- UNION: removes duplicates, requires sort
```

---

## 32. GROUP BY

Groups rows sharing the same values in specified columns, enabling aggregate calculations per group.

**Usage in file:** Grouping by NODE_IDENTIFIER and IP_TYPE to calculate per-record completeness scores, defect lists, and child counts.

```sql
GROUP BY NODE_IDENTIFIER, IP_TYPE, PROFILE_ID
```

**Example:**

```sql
SELECT department, COUNT(*) AS headcount, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;

-- Multiple grouping columns
SELECT year, month, SUM(revenue) AS total_revenue
FROM sales
GROUP BY year, month;
```

---

## 33. ORDER BY

Sorts the result set by one or more columns, ascending (ASC, default) or descending (DESC).

**Usage in file:** (1) Ordering within LISTAGG. (2) Ordering within ROW_NUMBER for deduplication. (3) Ordering final output.

```sql
LISTAGG(...) WITHIN GROUP (ORDER BY IMPORTANT_COLUMS)
ROW_NUMBER() OVER (PARTITION BY ... ORDER BY SEASON_IDENTIFIER DESC)
ORDER BY COUNT(Profile_Status) DESC
```

**Example:**

```sql
SELECT * FROM employees ORDER BY salary DESC;
SELECT * FROM events ORDER BY event_date ASC, priority DESC;
```

---

## 34. DISTINCT

Removes duplicate rows from the result set.

**Usage in file:** Ensuring unique combinations after joins that might produce duplicates.

```sql
SELECT DISTINCT NODE_IDENTIFIER, IP_TYPE
FROM hierarchy_source
```

**Example:**

```sql
SELECT DISTINCT city FROM customers;
SELECT DISTINCT department, job_title FROM employees;
SELECT COUNT(DISTINCT customer_id) FROM orders;
```

---

## 35. IN / NOT IN

Tests whether a value matches any value in a list or subquery.

**Usage in file:** (1) Classifying IP types into categories. (2) Filtering out non-standard IP types. (3) Checking if identifiers exist in a subquery.

```sql
-- List of values
WHEN ATTRIBUTE_VALUE IN ('Series') THEN 'SERIES'
WHEN ATTRIBUTE_VALUE IN ('Special', 'Game', 'Music', 'Feature', ...) THEN 'TITLE'

-- Exclusion
WHEN UPPER(IP_TYPE) NOT IN ('SERIES', 'SEASON', 'EPISODE', 'PODCAST', ...) THEN 'UNKNOWN'

-- Subquery
WHEN NODE_IDENTIFIER IN (SELECT SERIES_IDENTIFIER FROM ...) THEN 'EXISTS'
```

**Example:**

```sql
SELECT * FROM orders WHERE status IN ('Shipped', 'Delivered');
SELECT * FROM products WHERE category NOT IN ('Discontinued', 'Draft');
SELECT * FROM users WHERE id IN (SELECT user_id FROM active_sessions);
```

---

## 36. IS NULL / IS NOT NULL

Tests whether a value is or is not NULL. Required because `= NULL` never evaluates to TRUE in SQL.

**Usage in file:** (1) Checking if attributes are populated. (2) Filtering records with missing hierarchy data. (3) Conditional scoring.

```sql
WHEN IP_TYPE IS NULL OR MPM_NUMBER IS NULL THEN 'INCOMPLETE'
WHERE T.NODE_IDENTIFIER IS NOT NULL
```

**Example:**

```sql
SELECT * FROM customers WHERE email IS NOT NULL;
SELECT * FROM orders WHERE shipped_date IS NULL;
SELECT COUNT(*) - COUNT(phone) AS missing_phones FROM contacts;
```

---

## 37. WITHIN GROUP (ORDER BY ...)

Specifies the ordering for ordered-set aggregate functions like `LISTAGG`. Controls the order in which values are concatenated.

**Usage in file:** Ordering the concatenated attribute names alphabetically within the present/missing column lists.

```sql
LISTAGG(IMPORTANT_COLUMS, ' | ') WITHIN GROUP (ORDER BY IMPORTANT_COLUMS) AS PRESENT_COLUMNS
```

**Example:**

```sql
SELECT
    team,
    LISTAGG(player, '; ') WITHIN GROUP (ORDER BY jersey_number) AS roster
FROM players
GROUP BY team;

-- Ordering by a different column than what's aggregated
SELECT
    department,
    LISTAGG(name, ', ') WITHIN GROUP (ORDER BY hire_date) AS hire_order
FROM employees
GROUP BY department;
```

---

## 38. PARTITION BY (Window Function Clause)

Divides the result set into independent partitions for window function calculations. Each partition is processed separately.

**Usage in file:** Partitioning by SEASON_MPM_NUMBER for ROW_NUMBER deduplication to pick the best identifier per season.

```sql
ROW_NUMBER() OVER (
    PARTITION BY SEASON_MPM_NUMBER
    ORDER BY SEASON_IDENTIFIER DESC
) AS RN
```

**Example:**

```sql
-- Running total per department
SELECT
    department,
    employee_name,
    salary,
    SUM(salary) OVER (PARTITION BY department ORDER BY hire_date) AS running_total
FROM employees;

-- Rank within each category
SELECT
    category,
    product,
    revenue,
    RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS category_rank
FROM products;
```

---

## Summary Table

| # | Function/Clause | Category | Purpose in This File |
|---|----------------|----------|---------------------|
| 1 | `COALESCE` | Null handling | Fill missing identifiers from multiple sources |
| 2 | `NULLIF` | Null handling | Convert empty strings to NULL |
| 3 | `NVL` | Null handling | Default values for NULL columns |
| 4 | `TRIM` | String | Clean whitespace from values |
| 5 | `UPPER` | String | Normalise case for comparisons |
| 6 | `CONCAT` / `\|\|` | String | Build tagged labels and composite keys |
| 7 | `LENGTH` | String | Check title character limits |
| 8 | `SPLIT` | Semi-structured | Split delimited string into array |
| 9 | `SPLIT_PART` | Semi-structured | Extract nth segment from path |
| 10 | `ARRAY_SIZE` | Semi-structured | Count elements in split arrays |
| 11 | `ARRAY_CONSTRUCT` | Semi-structured | Build array of issue flags |
| 12 | `ARRAY_COMPACT` | Semi-structured | Remove NULLs from array |
| 13 | `ARRAY_TO_STRING` | Semi-structured | Join array into delimited string |
| 14 | `REGEXP_REPLACE` | Regex | Remove smart quotes, non-ASCII, trim pipes |
| 15 | `REGEXP_LIKE` / `RLIKE` | Regex | Pattern matching for special chars, years |
| 16 | `LIKE` / `NOT LIKE` | Pattern matching | Wildcard search for articles/keywords |
| 17 | `IFF` | Conditional | Inline if/else for scoring and flags |
| 18 | `CASE WHEN` | Conditional | Multi-branch classification and verdicts |
| 19 | `SUM` | Aggregate | Total weights and conditional counting |
| 20 | `MAX` | Aggregate | Pick latest/highest value per group |
| 21 | `COUNT` | Aggregate | Count records, populated attrs, children |
| 22 | `ROUND` | Numeric | Round percentage scores |
| 23 | `LISTAGG` | Aggregate | Build delimited defect lists |
| 24 | `ROW_NUMBER` | Window | Deduplicate rows per partition |
| 25 | `QUALIFY` | Filter | Filter window function results |
| 26 | `DATE` | Date/time | Cast timestamps to date for comparison |
| 27 | `VALUES` | Table constructor | Define inline rules/weight matrix |
| 28 | `WITH` (CTE) | Query structure | Step-by-step transformation pipeline |
| 29 | `LEFT JOIN` | Join | Retain all rules, surface missing attrs |
| 30 | `INNER JOIN` | Join | Match only existing records |
| 31 | `UNION ALL` | Set operation | Unpivot wide columns to tall format |
| 32 | `GROUP BY` | Aggregation | Per-record scoring |
| 33 | `ORDER BY` | Sorting | Control output and aggregation order |
| 34 | `DISTINCT` | Deduplication | Remove duplicate rows |
| 35 | `IN` / `NOT IN` | Comparison | Match/exclude against value lists |
| 36 | `IS NULL` / `IS NOT NULL` | Null check | Test attribute population |
| 37 | `WITHIN GROUP` | Ordered aggregate | Control LISTAGG concatenation order |
| 38 | `PARTITION BY` | Window | Scope window functions per group |

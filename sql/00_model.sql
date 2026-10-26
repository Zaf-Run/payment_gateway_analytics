-- Star schema built from the single flat file. The source has no merchant_id, so surrogate keys are created.
-- Status handling (ASSUMPTIONS, documented in README):
--   Success  = payment completed and settled
--   Refunded = payment completed, then refunded (full or partial is NOT known, no refund amount in source)
--   Failed   = payment did not complete
-- One row = one payment attempt. No retry identifier exists, so attempts equal unique transactions.
CREATE OR REPLACE TABLE stg AS SELECT * FROM read_csv_auto('data/raw/uae_payment_gateway_transactions.csv');

CREATE OR REPLACE TABLE dim_merchant AS
SELECT row_number() OVER (ORDER BY merchant_category, merchant_name) AS merchant_key,
       merchant_name, merchant_category
FROM (SELECT DISTINCT merchant_name, merchant_category FROM stg);

CREATE OR REPLACE TABLE dim_method AS
SELECT row_number() OVER (ORDER BY payment_method) AS method_key, payment_method
FROM (SELECT DISTINCT payment_method FROM stg);

CREATE OR REPLACE TABLE dim_region AS
SELECT row_number() OVER (ORDER BY region) AS region_key, region FROM (SELECT DISTINCT region FROM stg);

CREATE OR REPLACE TABLE dim_date AS
SELECT d::DATE AS date_key, year(d) AS year, month(d) AS month_no,
       strftime(d, '%Y-%m') AS year_month, quarter(d) AS quarter,
       dayname(d) AS weekday, isodow(d) AS weekday_no
FROM generate_series(DATE '2024-01-01', DATE '2025-12-31', INTERVAL 1 DAY) t(d);

CREATE OR REPLACE TABLE fact_payments AS
SELECT s.transaction_id,
       CAST(s.transaction_date AS DATE)  AS date_key,
       m.merchant_key, p.method_key, r.region_key,
       s.transaction_amount_aed          AS amount_aed,
       s.mdr_pct,
       s.fee_revenue_aed,
       s.transaction_status              AS status,
       s.settlement_time_hours,
       (s.transaction_status = 'Failed')::INT                      AS is_failed,
       (s.transaction_status = 'Refunded')::INT                    AS is_refunded,
       (s.transaction_status = 'Success')::INT                     AS is_success_only,
       (s.transaction_status IN ('Success','Refunded'))::INT       AS is_paid
FROM stg s
JOIN dim_merchant m ON m.merchant_name = s.merchant_name
JOIN dim_method   p ON p.payment_method = s.payment_method
JOIN dim_region   r ON r.region = s.region;

-- Slow settlement exception is limited to UPI and Digital Wallet because their medians are about 1 to 2 hours, so 24h+ is unusual for them.
-- Exception monitoring list. Rows are flagged, never removed.
SELECT 'large amount (above 99th percentile)' AS exception_type, f.transaction_id, f.date_key, dm.merchant_name, p.payment_method, f.status, f.amount_aed AS metric
FROM fact_payments f JOIN dim_merchant dm USING (merchant_key) JOIN dim_method p USING (method_key)
WHERE f.amount_aed > (SELECT quantile_cont(amount_aed, 0.99) FROM fact_payments)
UNION ALL
SELECT 'slow settlement (24h and above, completed)', f.transaction_id, f.date_key, dm.merchant_name, p.payment_method, f.status, f.settlement_time_hours
FROM fact_payments f JOIN dim_merchant dm USING (merchant_key) JOIN dim_method p USING (method_key)
WHERE f.is_paid = 1 AND f.settlement_time_hours >= 24 AND p.payment_method IN ('UPI','Digital Wallet')
UNION ALL
SELECT 'failed payment', f.transaction_id, f.date_key, dm.merchant_name, p.payment_method, f.status, f.amount_aed
FROM fact_payments f JOIN dim_merchant dm USING (merchant_key) JOIN dim_method p USING (method_key) WHERE f.is_failed = 1;

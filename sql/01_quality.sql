-- Each row is one check. Expected results are in the "expected" column.
SELECT 'row count' AS check_name, count(*)::VARCHAR AS result, '12000' AS expected FROM stg
UNION ALL SELECT 'fact rows equal staging rows', (SELECT count(*) FROM fact_payments)::VARCHAR, '12000'
UNION ALL SELECT 'duplicate transaction_id', (count(*) - count(DISTINCT transaction_id))::VARCHAR, '0' FROM stg
UNION ALL SELECT 'fully duplicated rows excluding id', (count(*) - (SELECT count(*) FROM (SELECT DISTINCT * EXCLUDE (transaction_id) FROM stg)))::VARCHAR, '0' FROM stg
UNION ALL SELECT 'null values (any column)', sum((transaction_id IS NULL)::INT + (transaction_date IS NULL)::INT + (region IS NULL)::INT + (merchant_name IS NULL)::INT + (merchant_category IS NULL)::INT + (payment_method IS NULL)::INT + (transaction_amount_aed IS NULL)::INT + (mdr_pct IS NULL)::INT + (fee_revenue_aed IS NULL)::INT + (transaction_status IS NULL)::INT + (settlement_time_hours IS NULL)::INT)::VARCHAR, '0' FROM stg
UNION ALL SELECT 'amount <= 0', count(*) FILTER (WHERE transaction_amount_aed <= 0)::VARCHAR, '0' FROM stg
UNION ALL SELECT 'settlement time < 0', count(*) FILTER (WHERE settlement_time_hours < 0)::VARCHAR, '0' FROM stg
UNION ALL SELECT 'merchants mapped to more than one category', (SELECT count(*) FROM (SELECT merchant_name FROM stg GROUP BY 1 HAVING count(DISTINCT merchant_category) > 1))::VARCHAR, '0'
UNION ALL SELECT 'dates outside 2024-01-01..2025-12-31', count(*) FILTER (WHERE transaction_date NOT BETWEEN DATE '2024-01-01' AND DATE '2025-12-31')::VARCHAR, '0' FROM stg
UNION ALL SELECT 'unknown status values', count(*) FILTER (WHERE transaction_status NOT IN ('Success','Refunded','Failed'))::VARCHAR, '0' FROM stg
UNION ALL SELECT 'fee > 0 on Failed or Refunded rows', count(*) FILTER (WHERE transaction_status <> 'Success' AND fee_revenue_aed > 0)::VARCHAR, 'info' FROM stg
UNION ALL SELECT 'Success rows where fee differs from amount x mdr by more than 5 percent', count(*) FILTER (WHERE transaction_status = 'Success' AND abs(fee_revenue_aed - transaction_amount_aed * mdr_pct / 100) > 0.05 * transaction_amount_aed * mdr_pct / 100)::VARCHAR, 'info (small amounts, minimum fee effect suspected)' FROM stg
UNION ALL SELECT 'aggregate gap, sum(fee) vs sum(amount x mdr) on Success rows, percent', round(100.0 * (sum(fee_revenue_aed) - sum(transaction_amount_aed * mdr_pct / 100)) / sum(transaction_amount_aed * mdr_pct / 100), 4)::VARCHAR, 'near 0' FROM stg WHERE transaction_status = 'Success'
UNION ALL SELECT 'amount above 99th percentile (kept, flagged)', count(*) FILTER (WHERE transaction_amount_aed > (SELECT quantile_cont(transaction_amount_aed, 0.99) FROM stg))::VARCHAR, 'info' FROM stg
UNION ALL SELECT 'settlement time at 48 hour maximum', count(*) FILTER (WHERE settlement_time_hours >= 48)::VARCHAR, 'info' FROM stg;

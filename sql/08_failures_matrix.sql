-- Where do failures occur? Counts by payment method and category.
SELECT p.payment_method, dm.merchant_category, count(*) AS attempts, sum(is_failed) AS failed,
  round(100.0 * sum(is_failed) / count(*), 2) AS failure_rate_pct
FROM fact_payments f JOIN dim_method p USING (method_key) JOIN dim_merchant dm USING (merchant_key)
GROUP BY 1, 2 HAVING sum(is_failed) > 0 ORDER BY failed DESC;

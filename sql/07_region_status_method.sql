-- Region view and a method by category failure matrix.
SELECT r.region, count(*) AS attempts, sum(is_failed) AS failed, sum(is_refunded) AS refunded,
  round(100.0 * sum(is_success_only) / count(*), 3) AS success_rate_pct,
  round(100.0 * sum(is_failed) / count(*), 3) AS failure_rate_pct,
  round(100.0 * sum(is_refunded) / sum(is_paid), 3) AS refund_rate_pct,
  round(sum(amount_aed) FILTER (WHERE is_paid = 1), 0) AS completed_value_aed,
  round(sum(fee_revenue_aed), 0) AS mdr_fee_revenue_aed
FROM fact_payments f JOIN dim_region r USING (region_key) GROUP BY 1 ORDER BY completed_value_aed DESC;

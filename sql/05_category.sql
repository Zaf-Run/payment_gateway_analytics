SELECT dm.merchant_category, count(DISTINCT dm.merchant_key) AS merchants, count(*) AS attempts,
  sum(is_paid) AS completed, sum(is_failed) AS failed, sum(is_refunded) AS refunded,
  round(100.0 * sum(is_success_only) / count(*), 3) AS success_rate_pct,
  round(100.0 * sum(is_failed) / count(*), 3) AS failure_rate_pct,
  round(100.0 * sum(is_refunded) / sum(is_paid), 3) AS refund_rate_pct,
  round(sum(amount_aed) FILTER (WHERE is_paid = 1), 0) AS completed_value_aed,
  round(avg(amount_aed), 0) AS avg_amount_aed, round(median(amount_aed), 0) AS median_amount_aed,
  round(sum(fee_revenue_aed), 0) AS mdr_fee_revenue_aed,
  round(100.0 * sum(fee_revenue_aed) / sum(amount_aed) FILTER (WHERE is_success_only = 1), 3) AS effective_take_rate_pct
FROM fact_payments f JOIN dim_merchant dm USING (merchant_key)
GROUP BY 1 ORDER BY completed_value_aed DESC;

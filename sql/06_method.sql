-- Payment method comparison. Settlement time is hours to settlement, NOT initiation to completion.
SELECT p.payment_method, count(*) AS attempts, sum(is_paid) AS completed, sum(is_failed) AS failed, sum(is_refunded) AS refunded,
  round(100.0 * sum(is_success_only) / count(*), 3) AS success_rate_pct,
  round(100.0 * sum(is_paid) / count(*), 3) AS payment_completion_rate_pct,
  round(100.0 * sum(is_refunded) / sum(is_paid), 3) AS refund_rate_pct,
  round(sum(amount_aed) FILTER (WHERE is_paid = 1), 0) AS completed_value_aed,
  round(avg(amount_aed), 0) AS avg_amount_aed,
  round(100.0 * sum(fee_revenue_aed) / sum(amount_aed) FILTER (WHERE is_success_only = 1), 3) AS effective_take_rate_pct,
  round(sum(fee_revenue_aed), 0) AS mdr_fee_revenue_aed,
  round(median(settlement_time_hours) FILTER (WHERE is_paid = 1), 2) AS median_settlement_h,
  round(quantile_cont(settlement_time_hours, 0.90) FILTER (WHERE is_paid = 1), 2) AS p90_settlement_h,
  round(quantile_cont(settlement_time_hours, 0.95) FILTER (WHERE is_paid = 1), 2) AS p95_settlement_h
FROM fact_payments f JOIN dim_method p USING (method_key)
GROUP BY 1 ORDER BY completed_value_aed DESC;

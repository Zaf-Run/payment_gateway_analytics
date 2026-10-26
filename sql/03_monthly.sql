SELECT d.year_month,
  count(*) AS attempts, sum(is_paid) AS completed, sum(is_failed) AS failed, sum(is_refunded) AS refunded,
  round(100.0 * sum(is_success_only) / count(*), 2) AS success_rate_pct,
  round(100.0 * sum(is_paid) / count(*), 2) AS payment_completion_rate_pct,
  round(100.0 * sum(is_refunded) / sum(is_paid), 2) AS refund_rate_pct,
  round(sum(amount_aed) FILTER (WHERE is_paid = 1), 0) AS completed_value_aed,
  round(sum(fee_revenue_aed), 0) AS mdr_fee_revenue_aed,
  round(median(settlement_time_hours) FILTER (WHERE is_paid = 1), 2) AS median_settlement_h
FROM fact_payments f JOIN dim_date d USING (date_key)
GROUP BY d.year_month ORDER BY d.year_month;

-- Merchant scorecard. Ranks use several dimensions, not value alone.
-- Wilson 95% interval is used because failure and refund counts per merchant are small (1 to 20).
WITH m AS (
  SELECT dm.merchant_name, dm.merchant_category,
    count(*) AS attempts, sum(is_paid) AS completed, sum(is_success_only) AS success_only, sum(is_failed) AS failed, sum(is_refunded) AS refunded,
    sum(amount_aed) FILTER (WHERE is_paid = 1) AS completed_value,
    sum(fee_revenue_aed) AS fee_revenue,
    median(settlement_time_hours) FILTER (WHERE is_paid = 1) AS median_settle
  FROM fact_payments f JOIN dim_merchant dm USING (merchant_key) GROUP BY 1, 2),
w AS (
  SELECT *,
    refunded::DOUBLE / completed AS refund_rate,
    failed::DOUBLE / attempts    AS failure_rate,
    -- Wilson upper bound for refund rate (n = completed) and failure rate (n = attempts)
    ((refunded::DOUBLE/completed + 1.96*1.96/(2*completed))
      + 1.96*sqrt((refunded::DOUBLE/completed)*(1-refunded::DOUBLE/completed)/completed + 1.96*1.96/(4*completed*completed)))
      / (1 + 1.96*1.96/completed) AS refund_upper,
    ((refunded::DOUBLE/completed + 1.96*1.96/(2*completed))
      - 1.96*sqrt((refunded::DOUBLE/completed)*(1-refunded::DOUBLE/completed)/completed + 1.96*1.96/(4*completed*completed)))
      / (1 + 1.96*1.96/completed) AS refund_lower,
    ((failed::DOUBLE/attempts + 1.96*1.96/(2*attempts))
      + 1.96*sqrt((failed::DOUBLE/attempts)*(1-failed::DOUBLE/attempts)/attempts + 1.96*1.96/(4*attempts*attempts)))
      / (1 + 1.96*1.96/attempts) AS failure_upper,
    ((failed::DOUBLE/attempts + 1.96*1.96/(2*attempts))
      - 1.96*sqrt((failed::DOUBLE/attempts)*(1-failed::DOUBLE/attempts)/attempts + 1.96*1.96/(4*attempts*attempts)))
      / (1 + 1.96*1.96/attempts) AS failure_lower
  FROM m)
SELECT merchant_name, merchant_category, attempts, completed, failed, refunded,
  round(completed_value, 0) AS completed_value_aed,
  round(fee_revenue, 0) AS mdr_fee_revenue_aed,
  round(100.0 * success_only / attempts, 2) AS success_rate_pct,
  round(100 * failure_rate, 2) AS failure_rate_pct,
  round(100 * failure_lower, 2) AS failure_ci_low, round(100 * failure_upper, 2) AS failure_ci_high,
  round(100 * refund_rate, 2) AS refund_rate_pct,
  round(100 * refund_lower, 2) AS refund_ci_low, round(100 * refund_upper, 2) AS refund_ci_high,
  round(median_settle, 2) AS median_settlement_h,
  rank() OVER (ORDER BY attempts DESC)        AS rank_volume,
  rank() OVER (ORDER BY completed_value DESC) AS rank_value,
  rank() OVER (ORDER BY fee_revenue DESC)     AS rank_fee_revenue,
  rank() OVER (ORDER BY refund_rate DESC)     AS rank_refund_rate
FROM w ORDER BY completed_value DESC;

-- Headline KPIs with explicit denominators. Success rate counts Success status only (refunded payments are not successes).
SELECT
  count(*)                                                        AS payment_attempts,
  sum(is_paid)                                                    AS completed_payments,          -- Success + Refunded
  sum(is_success_only)                                            AS success_not_refunded,
  sum(is_failed)                                                  AS failed_payments,
  sum(is_refunded)                                                AS refunded_payments,
  round(100.0 * sum(is_success_only) / count(*), 3)               AS success_rate_pct,            -- HEADLINE: Success status only / attempts
  round(100.0 * sum(is_paid) / count(*), 3)                       AS payment_completion_rate_pct, -- secondary: (Success + Refunded) / attempts
  round(100.0 * sum(is_failed) / count(*), 3)                     AS failure_rate_pct,            -- failed / attempts
  round(100.0 * sum(is_refunded) / sum(is_paid), 3)               AS refund_rate_count_pct,       -- refunded / completed
  round(sum(amount_aed), 2)                                       AS attempted_value_aed,
  round(sum(amount_aed) FILTER (WHERE is_paid = 1), 2)            AS completed_value_aed,
  round(sum(amount_aed) FILTER (WHERE is_success_only = 1), 2)    AS success_value_aed,
  round(sum(amount_aed) FILTER (WHERE is_refunded = 1), 2)        AS refunded_transaction_value_aed,
  round(sum(amount_aed) FILTER (WHERE is_failed = 1), 2)          AS failed_value_aed,
  round(100.0 * sum(amount_aed) FILTER (WHERE is_refunded = 1)
        / sum(amount_aed) FILTER (WHERE is_paid = 1), 3)          AS refund_rate_value_pct,       -- refunded value / completed value
  round(sum(fee_revenue_aed), 2)                                  AS mdr_fee_revenue_aed,
  round(100.0 * sum(fee_revenue_aed) / sum(amount_aed) FILTER (WHERE is_success_only = 1), 4) AS effective_take_rate_pct,
  round(median(settlement_time_hours) FILTER (WHERE is_paid = 1), 2) AS median_settlement_h,
  round(quantile_cont(settlement_time_hours, 0.90) FILTER (WHERE is_paid = 1), 2) AS p90_settlement_h,
  round(quantile_cont(settlement_time_hours, 0.95) FILTER (WHERE is_paid = 1), 2) AS p95_settlement_h
FROM fact_payments;

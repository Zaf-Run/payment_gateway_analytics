-- Method adjusted merchant comparison (indirect standardisation).
-- Failures occur only on some methods, so a merchant's raw rate depends on its method mix.
-- expected = sum over methods of (merchant volume in method x overall rate of that method).
-- Failure uses attempts as denominator. Refund uses completed payments (Success + Refunded) as denominator.
WITH method_rates AS (
  SELECT method_key,
         sum(is_failed)::DOUBLE / count(*)                    AS fail_rate,
         sum(is_refunded)::DOUBLE / sum(is_paid)              AS refund_rate
  FROM fact_payments GROUP BY method_key),
mm AS (
  SELECT f.merchant_key, f.method_key, count(*) AS attempts, sum(is_paid) AS completed,
         sum(is_failed) AS failed, sum(is_refunded) AS refunded
  FROM fact_payments f GROUP BY 1, 2)
SELECT dm.merchant_name, dm.merchant_category,
  sum(mm.attempts) AS attempts, sum(mm.failed) AS failed_observed,
  round(sum(mm.attempts * r.fail_rate), 2) AS failed_expected,
  round(sum(mm.failed) / nullif(sum(mm.attempts * r.fail_rate), 0), 2) AS failure_ratio,
  sum(mm.completed) AS completed, sum(mm.refunded) AS refunded_observed,
  round(sum(mm.completed * r.refund_rate), 2) AS refunded_expected,
  round(sum(mm.refunded) / nullif(sum(mm.completed * r.refund_rate), 0), 2) AS refund_ratio
FROM mm JOIN method_rates r USING (method_key) JOIN dim_merchant dm USING (merchant_key)
GROUP BY 1, 2 ORDER BY failure_ratio DESC;

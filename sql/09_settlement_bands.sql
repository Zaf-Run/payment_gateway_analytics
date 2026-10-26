-- Settlement time distribution for completed payments (hours to settlement).
SELECT CASE WHEN settlement_time_hours < 1 THEN '1 under 1h' WHEN settlement_time_hours < 6 THEN '2 1 to 6h'
            WHEN settlement_time_hours < 24 THEN '3 6 to 24h' ELSE '4 24h and above' END AS settlement_band,
  p.payment_method, count(*) AS payments
FROM fact_payments f JOIN dim_method p USING (method_key) WHERE is_paid = 1 GROUP BY 1, 2 ORDER BY 1, 2;

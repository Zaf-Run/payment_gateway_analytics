# Payment Gateway Analytics 

Merchant performance, payment success and failure, refunds, settlement time and payment method comparison, on a UAE payment gateway extract.

## 1. Dataset

File: `uae_payment_gateway_transactions.csv`

### Data dictionary

| Column | Type | Meaning | Notes |
|---|---|---|---|
| transaction_id | integer | Row identifier, 1 to 12,000 | Unique and contiguous |
| transaction_date | date | Date of payment | No time of day |
| region | text | Emirate or region (6) | Dubai, Abu Dhabi, Sharjah, Northern Emirates, Al Ain, Western Region |
| merchant_name | text | Merchant (24) | No merchant_id in source |
| merchant_category | text | Category (6) | Each merchant maps to exactly one category |
| payment_method | text | Method (5) | UPI, POS Card, Digital Wallet, Net Banking, Bank Transfer |
| transaction_amount_aed | decimal | Payment amount in AED | 78.48 to 234,987.82. Currency assumed from the column name. |
| mdr_pct | decimal | Merchant discount rate, percent | 0.20 to 2.60. Range depends on method. Rounded to 3 decimals. |
| fee_revenue_aed | decimal | Gateway fee revenue in AED | Zero on every Failed and Refunded row. |
| transaction_status | text | Success (11,653), Refunded (257), Failed (90) | Mutually exclusive |
| settlement_time_hours | decimal | Hours to settlement | 0.10 to 48.00. Present on failed rows too. |

## 2. What this dataset can and cannot support

| Spec item | Status |
|---|---|
| Merchant volume, value, success, refund, fee contribution | Supported |
| Category and region comparison | Supported |
| Payment method comparison (volume, value, success, refund, fee, settlement time) | Supported |
| Monthly trends | Supported (about 500 payments a month) |
| Refund count, rate and value | Supported as a status flag only. No refund_id, refund amount, refund date, full or partial flag. |
| Chargebacks (count, value, reasons, rates) | NOT SUPPORTED. The file has no chargeback data. Owner decision: keep this as a documented gap. No simulated chargeback table is added. |
| Failure reasons | NOT SUPPORTED. Only a Failed status exists. |
| Payment attempts and retries | NOT SUPPORTED. One row per transaction_id. Attempts are treated as equal to transactions. |
| Processing time (initiation to completion) | NOT SUPPORTED. Only settlement_time_hours exists. It is reported as settlement time and never called processing time. |
| Merchant onboarding date, merchant_id, customer | NOT AVAILABLE |
| Net revenue (after scheme or interchange costs) | NOT SUPPORTED. fee_revenue_aed is gross MDR revenue. |
| Linked payments, refunds, chargebacks tables | NOT AVAILABLE. A star schema is built from the flat file instead. |

## 3. Data model

Built in `sql/00_model.sql` with DuckDB.

```
dim_date (date_key) ----\
dim_merchant (merchant_key, name, category) --\
dim_method (method_key) ----------------------> fact_payments (transaction_id, one row per payment)
dim_region (region_key) ---------------------/
```

Surrogate merchant keys are created because the source has no merchant_id. The fact table holds amount, mdr_pct, fee, status, settlement hours and four flags: is_failed, is_refunded, is_success_only, is_paid. There are no one to many joins, so no amount or count can be multiplied.

## 4. Definitions and decisions

| Item | Decision |
|---|---|
| Payment attempt | One row. No retry marker exists. |
| Completed payment | Status Success or Refunded. A refund can only follow a completed payment. This is an assumption. It is the denominator for refund rate and settlement statistics, not for the headline success rate. |
| Failed payment | Status Failed |
| Success rate (HEADLINE, owner decision) | Status Success only divided by all attempts: 11,653 / 12,000 = 97.11%. Refunded payments are not counted as successes. |
| Payment completion rate (secondary) | (Success + Refunded) divided by all attempts: 11,910 / 12,000 = 99.25%. Shown for context only. |
| Failure rate | Failed divided by all attempts |
| Refund rate by count | Refunded divided by completed payments |
| Refund rate by value | Refunded transaction value divided by completed value. The source has no refund amount, so this is the full amount of refunded transactions and is an upper bound if any refund was partial. |
| Revenue | fee_revenue_aed as given. Not recomputed. Not equal to transaction value. |
| Effective take rate | Fee revenue divided by Success value |
| Settlement time statistics | Completed payments only. Failed rows carry a settlement time (mean 10.3 hours), which is not meaningful, so they are excluded. |
| Merchant comparison | Ranked on volume, value, fee revenue and refund rate separately. Failure and refund rates carry Wilson 95% intervals because counts per merchant are small (1 to 20 events). |
| Unusual records | Flagged, never removed. 120 payments above the 99th percentile of amount remain in all totals. |

## 5. Data quality results (`outputs/01_quality.csv`)

All integrity checks pass: no duplicate ids, no nulls, no non positive amounts, no negative times, all dates in range, only three status values, each merchant in one category.

Findings to be aware of:
- Fee revenue is zero on all 347 Failed and Refunded rows. Whether refunded fees were reversed or never charged is not known.
- Fee does not equal amount times mdr_pct exactly. In aggregate on Success rows the gap is minus 0.0012%. 116 rows differ by more than 5%, mostly small amounts, which suggests a minimum fee or rounding. fee_revenue_aed is used as supplied.
- One payment sits at the 48 hour settlement ceiling.

## 6. Results so far

All figures reproduce from `outputs/` and match the independent pandas check in `validate.py`.

| KPI | Value |
|---|---|
| Payment attempts | 12,000 |
| Success rate (headline) | 97.11% (11,653 payments with status Success) |
| Failed payments | 90 (0.75% of attempts) |
| Refunded payments | 257 (2.14% of attempts). Refund rate is 2.16% of completed payments by count and 1.43% by value. |
| Payment completion rate (secondary) | 99.25% (11,910 completed payments) |
| Completed value | AED 198.43 million |
| Refunded transaction value | AED 2.83 million |
| MDR fee revenue | AED 1.64 million |
| Effective take rate | 0.837% of Success value |
| Settlement time, completed payments | median 3.69 h, P90 35.08 h, P95 41.46 h |

Descriptive observations (not causal):
1. Failures occur only on Net Banking (57, 3.40% of its attempts) and Digital Wallet (33, 1.36%). UPI, POS Card and Bank Transfer record zero failures. Highest cells: Net Banking with Utilities (4.35%, 230 attempts) and with E-commerce (4.13%, 387).
2. Method roles differ. Bank Transfer carries 55.5% of completed value at a 0.35% take rate. POS Card carries 16.2% of completed value but earns 39.6% of fees at a 2.05% take rate. UPI is 30% of attempts and 1.9% of fees.
3. Settlement speed differs sharply. Medians: UPI 1.08 h, Digital Wallet 2.11 h, Bank Transfer 12.5 h, Net Banking 15.1 h, POS Card 30.1 h (P95 46.3 h). 2,234 of 3,325 POS Card completed payments settled in 24 hours or more.
4. Refund rates by method: Digital Wallet 2.75%, UPI 2.37%, Net Banking 2.28%, POS Card 1.84%, Bank Transfer 0.75% (7 of 936).
5. Merchant value is evenly spread. The top five merchants hold 31% of completed value. Spinneys POS leads at AED 13.97 million.
6. Healthcare has the highest category refund rate (3.43% against 1.86% to 2.25% elsewhere). NMC Health Gateway has the highest merchant refund rate (14 of 283, 5.00%). Adjusted for method mix it has 14 refunds against 5.94 expected (ratio 2.36, one sided p = 0.0033). That is below the usual 0.05 level but does not pass the stricter 0.0021 threshold for testing 24 merchants, so it is a watch item, not a proven outlier. Restaurant Aggregator Pay (18 against 11.24 expected, p = 0.038) is a weaker watch item.
7. Merchant failure rate differences (0.24% to 1.77%) are mostly sampling noise. After adjusting for method mix, Instashop Pay has 10 failures against 4.78 expected (ratio 2.09, p = 0.025), which is a watch item. No merchant passes the strict threshold on failures or refunds. The adjustment uses method only. It does not control for category, amount or region.
8. No clear time trend. Monthly attempts range from 433 to 557. Monthly refund rate ranges from 1.03% to 3.85%, which is consistent with small monthly counts.

## 7. Limitations

- Provenance and license unverified.
- The pattern of zero failures for three methods, even merchant sizes and method specific rate and settlement ranges suggest generated data. Treat findings as a demonstration of method, not as evidence about any real gateway.
- No chargebacks, failure reasons, retries, refund amounts or true processing timestamps.
- Small event counts at merchant and month level.

## 8. Reproduce

```
pip install duckdb pandas
# place the CSV at data/raw/uae_payment_gateway_transactions.csv
python run_analysis.py
python validate.py
```

## 9. Files

```
sql/00_model.sql        staging, dimensions, fact table, flags
sql/01_quality.sql      data quality checks with expected results
sql/02_kpis.sql         headline KPIs
sql/03 to 10            monthly, merchant, category, method, region, failure matrix, settlement bands, exceptions
sql/11_merchant_adjusted.sql  method adjusted failure and refund comparison
adjust.py               adds exact Poisson p values and the 0.05/24 Bonferroni flag
run_analysis.py         runs the SQL, writes outputs/
validate.py             independent pandas check
outputs/                result tables and star schema CSVs for Excel and Power BI
```


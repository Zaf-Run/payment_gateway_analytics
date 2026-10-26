"""Independent pandas check of SQL results."""
import pandas as pd, numpy as np
df = pd.read_csv("data/raw/uae_payment_gateway_transactions.csv")
st = df.transaction_status
paid = df[st.isin(["Success","Refunded"])]; suc = df[st=="Success"]; ref = df[st=="Refunded"]; fail = df[st=="Failed"]
r = {
 "attempts": len(df), "completed": len(paid), "failed": len(fail), "refunded": len(ref),
 "completion_rate_pct": 100*len(paid)/len(df), "net_success_rate_pct": 100*len(suc)/len(df),
 "failure_rate_pct": 100*len(fail)/len(df), "refund_rate_count_pct": 100*len(ref)/len(paid),
 "completed_value": paid.transaction_amount_aed.sum(), "refunded_value": ref.transaction_amount_aed.sum(),
 "refund_rate_value_pct": 100*ref.transaction_amount_aed.sum()/paid.transaction_amount_aed.sum(),
 "fee_revenue": df.fee_revenue_aed.sum(), "take_rate_pct": 100*df.fee_revenue_aed.sum()/suc.transaction_amount_aed.sum(),
 "median_settle_completed": paid.settlement_time_hours.median(), "p90": paid.settlement_time_hours.quantile(.9), "p95": paid.settlement_time_hours.quantile(.95),
}
for k,v in r.items(): print(f"{k}: {v:,.4f}")
k = pd.read_csv("outputs/02_kpis.csv").iloc[0]
pairs = [("payment_attempts","attempts"),("completed_payments","completed"),("failed_payments","failed"),("refunded_payments","refunded"),
 ("success_rate_pct","net_success_rate_pct"),("payment_completion_rate_pct","completion_rate_pct"),("failure_rate_pct","failure_rate_pct"),("refund_rate_count_pct","refund_rate_count_pct"),
 ("completed_value_aed","completed_value"),("refund_rate_value_pct","refund_rate_value_pct"),("mdr_fee_revenue_aed","fee_revenue"),
 ("effective_take_rate_pct","take_rate_pct"),("median_settlement_h","median_settle_completed"),("p90_settlement_h","p90"),("p95_settlement_h","p95")]
ok = True
for sqlk, pk in pairs:
    good = abs(float(k[sqlk]) - r[pk]) <= max(0.01, abs(r[pk])*1e-4)
    ok &= good
    if not good: print("MISMATCH", sqlk, k[sqlk], r[pk])
print("\nSQL vs pandas KPI match:", ok)
# merchant totals add up to the total, no double counting
m = pd.read_csv("outputs/04_merchant.csv"); print("merchant attempts sum:", m.attempts.sum(), " category sum:", pd.read_csv("outputs/05_category.csv").attempts.sum(), " method sum:", pd.read_csv("outputs/06_method.csv").attempts.sum(), " region sum:", pd.read_csv("outputs/07_region_status_method.csv").attempts.sum())
print("merchant completed value sum equals total:", abs(m.completed_value_aed.sum()-r["completed_value"]) < 24, "| fee sum matches:", abs(m.mdr_fee_revenue_aed.sum()-r["fee_revenue"])<30)
f = pd.read_csv("outputs/fact_payments.csv"); print("fact rows:", len(f), " unique ids:", f.transaction_id.nunique())
s = suc.copy(); s["calc"] = s.transaction_amount_aed*s.mdr_pct/100
print("aggregate fee vs amount x mdr gap %:", round(100*(s.fee_revenue_aed.sum()-s.calc.sum())/s.calc.sum(),4))

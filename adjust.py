"""Adds exact Poisson upper tail p values to the method adjusted merchant table.
p = P(X >= observed) when X ~ Poisson(expected). 24 merchants are tested per metric,
so the Bonferroni threshold is 0.05 / 24 = 0.0021. Counts are small, so treat flags as leads, not proof."""
import pandas as pd, math
def upper_tail(k, mu):
    k = int(k)
    return 1 - sum(math.exp(-mu) * mu**i / math.factorial(i) for i in range(k))
d = pd.read_csv("outputs/11_merchant_adjusted.csv")
d["failure_p_upper"] = [round(upper_tail(o, e), 4) for o, e in zip(d.failed_observed, d.failed_expected)]
d["refund_p_upper"] = [round(upper_tail(o, e), 4) for o, e in zip(d.refunded_observed, d.refunded_expected)]
t = 0.05 / len(d)
d["failure_flag"] = d.failure_p_upper < t
d["refund_flag"] = d.refund_p_upper < t
d["failure_watch"] = (d.failure_p_upper < 0.05) & ~d.failure_flag
d["refund_watch"] = (d.refund_p_upper < 0.05) & ~d.refund_flag
d.to_csv("outputs/11_merchant_adjusted.csv", index=False)
print(d[["merchant_name","failed_observed","failed_expected","failure_ratio","failure_p_upper","refunded_observed","refunded_expected","refund_ratio","refund_p_upper"]].sort_values("refund_p_upper").head(6).to_string(index=False))
print(d[["merchant_name","failed_observed","failed_expected","failure_ratio","failure_p_upper"]].sort_values("failure_p_upper").head(6).to_string(index=False))
print("Bonferroni flags:", d.failure_flag.sum(), d.refund_flag.sum(), " watch (p<0.05):", d.failure_watch.sum(), d.refund_watch.sum())

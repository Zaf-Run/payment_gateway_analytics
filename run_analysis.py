"""Run all SQL against the CSV with DuckDB and write results to /outputs. pip install duckdb"""
import duckdb, glob, os
os.makedirs("outputs", exist_ok=True); os.makedirs("data/processed", exist_ok=True)
con = duckdb.connect("data/processed/gateway.duckdb")
con.execute(open("sql/00_model.sql").read())
for t in ["fact_payments","dim_merchant","dim_method","dim_region","dim_date"]:
    con.execute(f"select * from {t}").fetchdf().to_csv(f"outputs/{t}.csv", index=False)
for f in sorted(glob.glob("sql/[0-9][0-9]_*.sql")):
    name = os.path.basename(f)[:-4]
    if name == "00_model": continue
    df = con.execute(open(f).read()).fetchdf(); df.to_csv(f"outputs/{name}.csv", index=False)
    print(name, len(df), "rows")

import subprocess; subprocess.run(['python','adjust.py'], check=True)

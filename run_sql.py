"""Runs the SQL in report_query.sql against store2.db and prints the result."""
import sqlite3

con = sqlite3.connect("store2.db")
cur = con.cursor()
cur.execute(open("report_query.sql", encoding="utf-8").read())
cols = [d[0] for d in cur.description]
print(" | ".join(cols))
for row in cur.fetchall():
    print(" | ".join(f"{v:,.2f}" if isinstance(v, float) else str(v) for v in row))
con.close()

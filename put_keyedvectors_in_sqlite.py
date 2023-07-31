import argparse
import json
import sqlite3
import tqdm

parser = argparse.ArgumentParser(
    description="Put fastText keyed vectors in SQLite database."
)
parser.add_argument(
    "--fpath_dotvec",
    type=str,
    default="wiki.da.align.vec",
    help="Path to .vec file",
    required=False,
)
parser.add_argument(
    "--fpath_database",
    type=str,
    default="fasttext.db",
    help="Path to database file; will be created if needed",
    required=False,
)
parser.add_argument(
    "--table_name",
    type=str,
    default="da",
    help="Name of table where keyed vectors will land",
    required=False,
)

args = parser.parse_args()

with open(args.fpath_dotvec, "r") as f:
    n_tokens, n_dims = [int(x) for x in f.readline().split(" ")]

with sqlite3.connect(args.fpath_database) as conn:
    cur = conn.cursor()

    cur.execute(f"DROP TABLE IF EXISTS {args.table_name};")

    colnames = "token TEXT, " + ", ".join(f"d{i+1} REAL" for i in range(n_dims))
    cur.execute(f"CREATE TABLE {args.table_name} ({colnames});")

    with open(args.fpath_dotvec, "r") as f:
        f.readline()  # skip first line

        insert_query = f"""
            INSERT INTO {args.table_name} 
            VALUES ({", ".join("?" for _ in range(n_dims+1))})
        """
        for line in tqdm.tqdm(f, total=n_tokens):
            data = tuple(line.strip("\n").split(" "))
            cur.executemany(insert_query, [data])

    cur.execute(
        f"CREATE INDEX {args.table_name}__token_idx ON {args.table_name} (token);"
    )
    conn.commit()

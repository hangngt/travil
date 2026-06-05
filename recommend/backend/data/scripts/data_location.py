from pathlib import Path
import pandas as pd
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore

# BASE DIR

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# FIREBASE KEY

FIREBASE_KEY = (
    BASE_DIR
    / "config"
    / "firebase-credentials.json"
)

# CSV PATH

CSV_PATH = (
    BASE_DIR
    / "data"
    / "raw"
    / "locations.csv"
)

# FIREBASE INIT

cred = credentials.Certificate(
    FIREBASE_KEY
)

firebase_admin.initialize_app(cred)

db = firestore.client()

# READ CSV

try:
    df = pd.read_csv(
        CSV_PATH,
        encoding="utf-8",
    )

except UnicodeDecodeError:
    df = pd.read_csv(
        CSV_PATH,
        encoding="latin1",
    )

# CHECK COLUMN

if "location" not in df.columns:
    raise Exception(
        "CSV phải có column tên là 'location'"
    )

# CLEAN DATA

df["location"] = (
    df["location"]
    .astype(str)
    .str.strip()
)

# REMOVE EMPTY
df = df[
    df["location"] != ""
]

# REMOVE DUPLICATE
df = df.drop_duplicates(
    subset=["location"]
)

# SORT A-Z
df = df.sort_values(
    by="location"
)

print(
    f"TOTAL LOCATIONS: {len(df)}"
)

# UPLOAD TO FIRESTORE

collection_ref = db.collection(
    "locations"
)

success = 0

for _, row in df.iterrows():

    location = row["location"]

    # DOCUMENT ID
    doc_id = (
        location.lower()
        .replace(" ", "_")
        .replace(",", "")
        .replace("/", "_")
    )

    data = {
        "name": location,
    }

    try:
        collection_ref.document(
            doc_id
        ).set(data)

        success += 1

        print(
            f"UPLOADED: {location}"
        )

    except Exception as e:
        print(
            f"ERROR {location}: {e}"
        )

print(f"SUCCESS: {success}")
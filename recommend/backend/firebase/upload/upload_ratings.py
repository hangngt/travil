#!/usr/bin/env python3

import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import time
from google.api_core.exceptions import ResourceExhausted

# ===================================
# PATH
# ===================================

BASE_DIR = Path(__file__).resolve().parent.parent.parent
RATINGS_CSV = BASE_DIR / "data" / "processed" / "user_item_ratings_real.csv"

# ===================================
# FIREBASE INIT
# ===================================

cred = credentials.Certificate(
    BASE_DIR / "config" / "firebase-credentials.json"
)

firebase_admin.initialize_app(cred)
db = firestore.client()

# ===================================
# SAFE COMMIT
# ===================================

def safe_commit(batch, retries=5):
    for i in range(retries):
        try:
            batch.commit()
            return
        except ResourceExhausted:
            wait = 2 ** i
            print(f"⚠️ Quota exceeded → retry in {wait}s")
            time.sleep(wait)

    raise Exception("❌ Commit failed after retries")

# ===================================
# UPLOAD USERS
# ===================================

def upload_users(user_mapping):
    print("\n====================")
    print("UPLOAD USERS")
    print("====================")

    batch = db.batch()
    ops = 0

    for original_user, user_id in user_mapping.items():

        user_ref = db.collection("users").document(user_id)

        batch.set(user_ref, {
            "display_name": original_user,
            "email": "",
            "preferences": {}
        })

        ops += 1

        if ops >= 150:
            safe_commit(batch)
            time.sleep(5)
            batch = db.batch()
            ops = 0

    if ops > 0:
        safe_commit(batch)

    print("✅ Users uploaded!")

# ===================================
# UPLOAD INTERACTIONS
# ===================================

def upload_interactions(df, user_mapping):
    print("\n====================")
    print("UPLOAD INTERACTIONS")
    print("====================")

    batch = db.batch()
    ops = 0

    for idx, row in df.iterrows():

        user_id = user_mapping[str(row["user_id"])]
        product_id = str(row["product_id"])

        interaction_ref = db.collection("interactions").document()

        batch.set(interaction_ref, {
            "user_id": user_id,
            "product_id": product_id,
            "rating": float(row["rating"])
        })

        ops += 1

        if ops >= 200:
            safe_commit(batch)
            time.sleep(3)
            batch = db.batch()
            ops = 0

    if ops > 0:
        safe_commit(batch)

    print("✅ Interactions uploaded!")

# ===================================
# MAIN FUNCTION
# ===================================

def upload_users_and_interactions():

    print("\n==============================")
    print("UPLOAD FIREBASE DATA")
    print("==============================")

    df = pd.read_csv(RATINGS_CSV)

    unique_users = df["user_id"].unique()

    user_mapping = {
        user: f"user_{i+1}"
        for i, user in enumerate(unique_users)
    }

    print(f"Total users: {len(user_mapping)}")
    print(f"Total interactions: {len(df)}")

    upload_users(user_mapping)
    upload_interactions(df, user_mapping)

    print("\n==============================")
    print("DONE!")
    print("==============================")
    print(f"Users: {len(user_mapping)}")
    print(f"Interactions: {len(df)}")

# ===================================
# RUN
# ===================================

if __name__ == "__main__":
    upload_users_and_interactions()
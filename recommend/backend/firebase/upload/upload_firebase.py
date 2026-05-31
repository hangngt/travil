
import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
from datetime import datetime
import re

# PATHS

BASE_DIR = Path(__file__).resolve().parent.parent.parent

PRODUCTS_CSV = BASE_DIR / "data" / "processed" / "products_clean.csv"
RATINGS_CSV = BASE_DIR / "data" / "processed" / "user_item_ratings_real.csv"

# FIREBASE INIT

cred = credentials.Certificate(
    BASE_DIR / "config" / "firebase-credentials.json"
)

firebase_admin.initialize_app(cred)

db = firestore.client()

# HELPERS

def parse_number(value):

    if pd.isna(value):
        return 0

    value = str(value).strip()

    if 'K' in value.upper():
        num = re.findall(r'[\d.]+', value)

        if num:
            return int(float(num[0]) * 1000)

    num = re.findall(r'\d+', value)

    return int(num[0]) if num else 0

# PRODUCTS

def upload_products():

    print("\nUploading products...")

    df = pd.read_csv(PRODUCTS_CSV)

    batch = db.batch()

    total = 0

    for _, row in df.iterrows():

        product_id = str(row["product_id"])

        doc_ref = db.collection("products").document(product_id)

        product_data = {

            "title": str(row.get("title", "")),

            "image_url": str(row.get("image_url", "")),

            "description": str(row.get("description", "")),

            "price": float(row.get("price", 0))
            if pd.notna(row.get("price"))
            else 0,

            "rating": float(row.get("rating", 4.0))
            if pd.notna(row.get("rating"))
            else 4.0,

            "booked_count": parse_number(
                row.get("booked_count", 0)
            ),

            "review_count": parse_number(
                row.get("review_count", 0)
            ),

            "location": str(row.get("location", "")),

            "lat": float(row["lat"])
            if pd.notna(row.get("lat"))
            else None,

            "lng": float(row["lng"])
            if pd.notna(row.get("lng"))
            else None,

            "combined_text": str(
                row.get("combined_text", "")
            )
        }

        batch.set(doc_ref, product_data)

        total += 1

        # Firestore limit = 500
        if total % 500 == 0:
            batch.commit()
            print(f"Uploaded {total} products...")
            batch = db.batch()

    # final commit
    batch.commit()

    print(f"Done products: {total}")



def main():

    print("=" * 50)
    print("UPLOAD TO FIRESTORE")
    print("=" * 50)

    upload_products()

   

    print("\nALL DONE!")

if __name__ == "__main__":
    main()
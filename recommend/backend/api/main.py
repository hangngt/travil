print(">>> IMPORT MAIN OK")
from fastapi import FastAPI
from ml.hybrid.hybrid_service import HybridService

app = FastAPI()

hybrid = None

print("🚀 MAIN.PY IMPORTED")   # DEBUG 1

@app.on_event("startup")
def load_model():
    global hybrid
    print("🔥 STARTUP EVENT TRIGGERED")   # DEBUG 2

    try:
        print("📦 Initializing HybridService...")  # DEBUG 3
        hybrid = HybridService()
        print("✅ HybridService loaded successfully")  # DEBUG 4
    except Exception as e:
        print("❌ ERROR IN STARTUP:", str(e))  # DEBUG 5
        raise e


@app.get("/")
def home():
    print("🏠 HOME CALLED")
    return {"message": "Travel Recommendation API"}


@app.get("/recommend")
def recommend(
    city: str = None,
    user_id: str = None,
    lat: float = None,
    lng: float = None,
):
    print(f"📍 RECOMMEND CALLED | city={city}, user_id={user_id}, lat={lat}, lng={lng}")

    try:
        results = hybrid.recommend(
            user_id=user_id,
            city_name=city,
            user_lat=lat,
            user_lng=lng,
            top_k=10
        )

        print("📊 Recommendation success, rows:", len(results))
        return results.to_dict(orient="records")

    except Exception as e:
        print("❌ ERROR IN RECOMMEND:", str(e))
        return {"error": str(e)}

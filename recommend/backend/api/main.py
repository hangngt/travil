from fastapi import FastAPI
from ml.hybrid.hybrid_service import HybridService

app = FastAPI()

# Load model khi server start
hybrid = None

@app.on_event("startup")
def load_model():
    global hybrid
    hybrid = HybridService()

@app.get("/")
def home():
    return {"message": "Travel Recommendation API"}

@app.get("/recommend")
def recommend(
    city: str = None,
    user_id: str = None,
    lat: float = None,
    lng: float = None,
):
    results = hybrid.recommend(
        user_id=user_id,
        city_name=city,
        user_lat=lat,
        user_lng=lng,
        top_k=10
    )

    return results.to_dict(orient="records")

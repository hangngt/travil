print("🔥 FILE LOADED")

from fastapi import FastAPI
from fastapi.responses import JSONResponse

print("1")
from ml.hybrid.hybrid_service import HybridService
print("2")

app = FastAPI()

hybrid = None

print("🚀 MAIN.PY IMPORTED")


# ======================
# STARTUP
# ======================
@app.on_event("startup")
def load_model():
    global hybrid
    try:
        print("🔥 STARTUP START")
        hybrid = HybridService()
        print("🔥 STARTUP DONE")
    except Exception as e:
        import traceback
        print("❌ STARTUP ERROR:", str(e))
        print(traceback.format_exc())
        hybrid = None   # KHÔNG raise để tránh kill server


# ======================
# HEALTH CHECK
# ======================
@app.get("/")
def home():
    print("🏠 HOME CALLED")
    return {
        "message": "Travel Recommendation API",
        "status": "running",
        "model_loaded": hybrid is not None
    }


# RECOMMEND API
@app.get("/recommend")
def recommend(
    city: str = None,
    user_id: str = None,
    lat: float = None,
    lng: float = None,
):
    print(f"📍 RECOMMEND CALLED | city={city}, user_id={user_id}, lat={lat}, lng={lng}")

    # ⚠️ CHECK MODEL BEFORE USE
    if hybrid is None:
        return JSONResponse(
            status_code=503,
            content={
                "error": "Model not loaded",
                "hint": "Check server logs for startup error"
            }
        )

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
        import traceback
        print("❌ ERROR IN RECOMMEND:", str(e))
        print(traceback.format_exc())

        return JSONResponse(
            status_code=500,
            content={
                "error": str(e)
            }
        )

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        print("Initializing HybridService (lazy loading enabled)...")
        from recommend.backend.ml.hybrid.hybrid_service import HybridService
        app.state.hybrid = HybridService()
        print("HybridService wrapper created (will load on first request)")
    except Exception as e:
        import traceback
        print(f"STARTUP ERROR: {str(e)}")
        print(traceback.format_exc())
        app.state.hybrid = None
    yield
    print("Server shutting down...")

app = FastAPI(lifespan=lifespan)

# THÊM HEAD HANDLER CHO HEALTH CHECK
@app.head("/")
async def head_root():
    """HEAD request handler for Render health checks"""
    return JSONResponse(content={}, status_code=200)

@app.get("/")
def home():
    hybrid = app.state.hybrid
    return {
        "message": "Travel Recommendation API",
        "status": "running",
        "model_loaded": hybrid is not None and hybrid._initialized if hybrid else False
    }

@app.get("/health")
def health():
    """Health check endpoint"""
    hybrid = app.state.hybrid
    return {
        "status": "healthy",
        "model_ready": hybrid is not None and hybrid._initialized if hybrid else False
    }

@app.get("/recommend")
def recommend(
    city: str = None,
    user_id: str = None,
    lat: float = None,
    lng: float = None,
):
    hybrid = app.state.hybrid
    print(f"RECOMMEND CALLED: city={city}, user_id={user_id}")

    if hybrid is None:
        return JSONResponse(
            status_code=503,
            content={"error": "Model not loaded", "hint": "Check server logs"}
        )

    try:
        results = hybrid.recommend(
            user_id=user_id,
            city_name=city,
            user_lat=lat,
            user_lng=lng,
            top_k=10
        )
        print(f"Recommendation success, rows: {len(results)}")
        return results.to_dict(orient="records")
    except Exception as e:
        import traceback
        print(f"ERROR: {str(e)}")
        print(traceback.format_exc())
        return JSONResponse(status_code=500, content={"error": str(e)})
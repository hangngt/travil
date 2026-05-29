
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from recommend.backend.ml.hybrid.hybrid_service import HybridService


@asynccontextmanager
async def lifespan(app: FastAPI):

    try:

        print("Loading HybridService...")

        app.state.hybrid = HybridService()

        print("HybridService loaded successfully")

    except Exception as e:

        import traceback

        print("STARTUP ERROR:", str(e))
        print(traceback.format_exc())

        app.state.hybrid = None

    yield

    print("Server shutting down...")

app = FastAPI( lifespan=lifespan)

# hybrid = None
# @app.on_event("startup")
# def load_model():
#     global hybrid
#     try:
#         hybrid = HybridService()
#     except Exception as e:
#         import traceback
#         print(" STARTUP ERROR:", str(e))
#         print(traceback.format_exc())
#         hybrid = None   # KHÔNG raise để tránh kill server



@app.get("/")
def home():

    hybrid = app.state.hybrid

    print("HOME CALLED")

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

    hybrid = app.state.hybrid

    print(
        f"RECOMMEND CALLED  "
        f"city={city}, user_id={user_id}, lat={lat}, lng={lng}"
    )

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

        print("Recommendation success, rows:", len(results))

        return results.to_dict(orient="records")

    except Exception as e:

        import traceback

        print("ERROR IN RECOMMEND:", str(e))
        print(traceback.format_exc())

        return JSONResponse(
            status_code=500,
            content={
                "error": str(e)
            }
        )
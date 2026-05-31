from fastapi import APIRouter, BackgroundTasks
from recommend.backend.ml.hybrid.hybrid_service import HybridService

from recommend.backend.task.retrain import full_retrain

router = APIRouter()
hybrid = HybridService()

@router.post("/rating")
async def add_user_rating(data: dict, background_tasks: BackgroundTasks):
    """Nhận rating mới từ Firebase / Mobile App"""
    user_id = data.get("user_id")
    product_id = data.get("product_id")
    rating = data.get("rating")
    
    if user_id and product_id and rating:
        hybrid.add_rating(user_id, product_id, rating)
        
        # Trigger retrain background nếu cần
        if hybrid.pending_ratings >= 1000:
            background_tasks.add_task(full_retrain)
    
    return {"status": "success"}

@router.get("/recommend")
def get_recommendation(
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
        top_k=12
    )
    return results.to_dict(orient="records")
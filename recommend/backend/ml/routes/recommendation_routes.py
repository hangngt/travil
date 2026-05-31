from fastapi import APIRouter, BackgroundTasks
from recommend.backend.ml.hybrid.hybrid_service import HybridService
from recommend.backend.task.retrain import full_retrain
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

# KHỞI TẠO NHƯNG SẼ LAZY LOAD - KHÔNG TẢI NGAY
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
            logger.info("Threshold reached, triggering background retrain")
            background_tasks.add_task(full_retrain)
    
    return {"status": "success"}

@router.get("/recommend")
def get_recommendation(
    city: str = None,
    user_id: str = None,
    lat: float = None,
    lng: float = None,
):
    """Get recommendations - sẽ trigger lazy loading ở lần gọi đầu tiên"""
    try:
        results = hybrid.recommend(
            user_id=user_id,
            city_name=city,
            user_lat=lat,
            user_lng=lng,
            top_k=12
        )
        
        if results.empty:
            return {"error": "No recommendations found", "city": city}
            
        return results.to_dict(orient="records")
    except Exception as e:
        logger.error(f"Recommendation error: {e}")
        return {"error": str(e), "status": "failed"}

import pandas as pd
import numpy as np
import pickle
from pathlib import Path
from typing import Optional, List, Dict
import logging
from datetime import datetime, timedelta

from recommend.backend.ml.content_base.train_tfidf import ContentService, download_file

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[2]  # Lên đến backend folder

DATA_PROCESSED = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "ml" / "model"

class HybridService:
    def __init__(self):
        self.content_service = ContentService()
        self.svd_model = None
        self.pending_ratings = 0
        self.rating_cache = {}
        
        # Cache cho recommendations
        self.recommendation_cache = {}  # {user_id: {'items': df, 'expires_at': datetime}}
        self.cache_ttl_minutes = 30  # Cache trong 30 phút

        logger.info("Loading SVD model from latest release...")
        self._load_svd_model()

    def _load_svd_model(self):
        """Load SVD model từ GitHub Releases"""
        try:
            BASE_URL = "https://github.com/hangngt/travil/releases/latest/download"
            SVD_URL = f"{BASE_URL}/svd_model.pkl"

            # Tạo folder nếu chưa có
            MODEL_DIR.mkdir(parents=True, exist_ok=True)
            
            if download_file(SVD_URL, MODEL_DIR / "svd_model.pkl"):
                with open(MODEL_DIR / "svd_model.pkl", "rb") as f:
                    self.svd_model = pickle.load(f)
                logger.info(" SVD Model loaded from latest release")
            else:
                logger.error("Failed to download SVD model")
                self.svd_model = None
                
        except Exception as e:
            logger.error(f" SVD load failed: {e}")
            self.svd_model = None

    def add_rating(self, user_id: str, product_id: int, rating: float):
        """Gọi khi nhận rating mới từ Firebase"""
        self.pending_ratings += 1
        
        if user_id not in self.rating_cache:
            self.rating_cache[user_id] = {}
        self.rating_cache[user_id][product_id] = rating

        # Xóa cache của user này vì đã có rating mới
        if user_id in self.recommendation_cache:
            del self.recommendation_cache[user_id]
            logger.info(f"Cleared cache for user {user_id} due to new rating")

        if self.pending_ratings >= 1000:
            logger.info(f" Đạt ngưỡng {self.pending_ratings} ratings → Nên retrain model")

        logger.info(f" Saved rating: {user_id} → {product_id} = {rating}")
        
    def _get_svd_scores(self, user_id: str) -> Optional[pd.DataFrame]:
        """Trả về điểm SVD đã được chuẩn hóa cho tất cả items của 1 user"""
        if self.svd_model is None:
            logger.warning("SVD model not loaded")
            return None
            
        if user_id not in self.svd_model.get('user_to_idx', {}):
            logger.warning(f"User {user_id} not found in SVD model")
            return None
        
        try:
            P = self.svd_model['P']
            Q = self.svd_model['Q']
            user_idx = self.svd_model['user_to_idx'][user_id]
            
            user_vector = P[user_idx]
            scores = np.dot(Q, user_vector)  # Dot product
            
            # Sắp xếp item_ids theo đúng thứ tự
            sorted_item_mappings = sorted(
                self.svd_model['item_to_idx'].items(), 
                key=lambda x: x[1]
            )
            item_ids = [item_id for item_id, idx in sorted_item_mappings]
            
            svd_df = pd.DataFrame({
                'product_id': item_ids,
                'raw_svd_score': scores
            })
            
            # Chuẩn hóa về [1.0, 5.0]
            min_s = svd_df['raw_svd_score'].min()
            max_s = svd_df['raw_svd_score'].max()
            
            if max_s > min_s:
                svd_df['svd_score'] = 1.0 + 4.0 * (svd_df['raw_svd_score'] - min_s) / (max_s - min_s)
            else:
                svd_df['svd_score'] = 4.0  # Fallback
                
            return svd_df[['product_id', 'svd_score']]
            
        except Exception as e:
            logger.error(f"Error computing SVD scores: {e}")
            return None

    def recommend(self, 
                  user_id: Optional[str] = None,
                  city_name: Optional[str] = None,
                  user_lat: Optional[float] = None,
                  user_lng: Optional[float] = None,
                  viewed_product_id: Optional[int] = None,
                  top_k: int = 15,
                  use_cache: bool = True) -> pd.DataFrame:
        """
        Hybrid Recommendation System
        
        Args:
            user_id: User ID for personalized recommendations
            city_name: Filter by city name
            user_lat: User latitude for GPS-based recommendations
            user_lng: User longitude for GPS-based recommendations
            viewed_product_id: Product ID for similarity-based recommendations
            top_k: Number of recommendations to return
            use_cache: Whether to use cached results
        
        Returns:
            DataFrame with recommendations
        """
        
        # Kiểm tra cache
        cache_key = f"{user_id}_{city_name}_{user_lat}_{user_lng}_{viewed_product_id}"
        if use_cache and cache_key in self.recommendation_cache:
            cached = self.recommendation_cache[cache_key]
            if datetime.now() < cached['expires_at']:
                logger.info(f"Returning cached recommendations for {cache_key}")
                return cached['items'].head(top_k)
        
        # Bước 1: Lấy candidates từ Content + Geo
        try:
            candidates = self.content_service.recommend_hybrid(
                city_name=city_name,
                user_lat=user_lat,
                user_lng=user_lng,
                viewed_product_id=viewed_product_id,
                top_k=top_k * 3  # Lấy dư để rerank
            ).copy()
        except Exception as e:
            logger.error(f"Content service failed: {e}")
            # Fallback: trả về popular places
            return self.content_service.get_popular_places(top_k)

        if candidates.empty:
            logger.warning("No candidates found, returning popular places")
            return self.content_service.get_popular_places(top_k)

        # Bước 2: Kết hợp SVD scores nếu có user_id
        if user_id and self.svd_model is not None:
            svd_df = self._get_svd_scores(user_id)
            
            if svd_df is not None and not svd_df.empty:
                # Merge SVD score
                candidates = candidates.merge(svd_df, on='product_id', how='left')
                
                # Điền giá trị mặc định cho các sản phẩm chưa có điểm SVD
                mean_svd = candidates['svd_score'].mean()
                if pd.isna(mean_svd):
                    mean_svd = 4.0  # Giá trị mặc định
                candidates['svd_score'] = candidates['svd_score'].fillna(mean_svd)
                
                # Hybrid Score: 52% Content + 48% Collaborative
                candidates['hybrid_score'] = (
                    0.52 * candidates['final_score'] +
                    0.48 * candidates['svd_score']
                )
            else:
                candidates['hybrid_score'] = candidates['final_score']
        else:
            candidates['hybrid_score'] = candidates['final_score']
        
        # Sắp xếp và chọn Top-K
        candidates = candidates.sort_values('hybrid_score', ascending=False)
        
        # Chọn cột hiển thị
        result_columns = ['product_id', 'title', 'location', 'rating', 'hybrid_score']
        if 'distance_km' in candidates.columns:
            result_columns.append('distance_km')
        
        result = candidates.head(top_k)[result_columns].round(4)
        
        # Lưu vào cache
        if use_cache:
            self.recommendation_cache[cache_key] = {
                'items': result,
                'expires_at': datetime.now() + timedelta(minutes=self.cache_ttl_minutes)
            }
        
        return result
    
    def clear_cache(self, user_id: Optional[str] = None):
        """Xóa cache recommendations"""
        if user_id:
            # Xóa cache của user cụ thể
            keys_to_delete = [k for k in self.recommendation_cache.keys() if k.startswith(user_id)]
            for key in keys_to_delete:
                del self.recommendation_cache[key]
            logger.info(f"Cleared cache for user {user_id}")
        else:
            # Xóa toàn bộ cache
            self.recommendation_cache.clear()
            logger.info("Cleared all recommendation cache")
    
    def get_model_stats(self) -> Dict:
        """Lấy thông tin về model"""
        stats = {
            'svd_loaded': self.svd_model is not None,
            'pending_ratings': self.pending_ratings,
            'cached_users': len(self.recommendation_cache),
            'content_products': len(self.content_service.df) if self.content_service.df is not None else 0
        }
        
        if self.svd_model:
            stats['svd_users'] = len(self.svd_model.get('user_to_idx', {}))
            stats['svd_items'] = len(self.svd_model.get('item_to_idx', {}))
            stats['svd_factors'] = self.svd_model.get('K', 0)
        
        return stats


#TEST 
if __name__ == "__main__":
    hybrid = HybridService()
    
    print("HYBRID RECOMMENDATION SYSTEM TEST")
    
    # Show model stats
    print("\n Model Stats:")
    stats = hybrid.get_model_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")
 
    # CASE 1: SVD + Content cho User cũ 
    print("\n CASE 1: SVD + Content cho User cũ")
    recs_svd = hybrid.recommend(
        user_id="Klook User",
        city_name="Da Nang",
        top_k=5
    )
    print(recs_svd)  
 
    # CASE 2: Content + Location Only 
    print("\n CASE 2: Content + Location (Không dùng SVD, dùng GPS)")
    recs_content = hybrid.recommend(
        city_name="Da Nang",
        user_lat=16.0544,
        user_lng=108.2022,
        top_k=5
    )
    print(recs_content)  
 
    # CASE 3: Hybrid với viewed item 
    print("\n CASE 3: Hybrid + Similar to viewed product")
    recs_hybrid = hybrid.recommend(
        user_id="Klook User",
        city_name="Da Nang",
        viewed_product_id=2,
        top_k=5
    )
    print(recs_hybrid)
    
    # Test cache
    print("\n Testing cache (should be faster):")
    import time
    start = time.time()
    recs_cached = hybrid.recommend(
        user_id="Klook User",
        city_name="Da Nang",
        top_k=5
    )
    elapsed = time.time() - start
    print(f"Time with cache: {elapsed:.4f}s")
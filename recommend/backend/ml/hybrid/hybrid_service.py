import os
import pandas as pd
import numpy as np
import pickle
from pathlib import Path
from typing import Optional, List, Dict
import logging
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[2]

DATA_PROCESSED = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "ml" / "model"


def download_file(url, output_path):
    """Download file từ URL"""
    if os.path.exists(output_path):
        logger.info(f"Using cached: {output_path.name}")
        return True

    logger.info(f"Downloading {output_path.name} ...")
    try:
        import requests
        r = requests.get(url, stream=True, timeout=120)
        r.raise_for_status()

        with open(output_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)

        logger.info(f"Downloaded: {output_path.name}")
        return True
    except Exception as e:
        logger.error(f"Download failed: {e}")
        return False


class HybridService:
    def __init__(self):
        # Khởi tạo các biến nhưng CHƯA load content service ngay
        self.content_service = None
        self.svd_model = None
        self.pending_ratings = 0
        self.rating_cache = {}
        self.recommendation_cache = {}
        self.cache_ttl_minutes = 30
        self._initialized = False

        logger.info("HybridService initialized (lazy loading enabled)")

    def _ensure_initialized(self):
        """Lazy initialization - chỉ load khi cần"""
        if self._initialized:
            return

        logger.info("Initializing HybridService components...")
        
        # Import ở đây để tránh circular import
        from recommend.backend.ml.content_base.train_tfidf import ContentService
        
        try:
            self.content_service = ContentService()
            self._load_svd_model()
            self._initialized = True
            logger.info("HybridService components loaded successfully")
        except Exception as e:
            logger.error(f"Failed to initialize HybridService: {e}")
            raise

    def _load_svd_model(self):
        """Load SVD model từ GitHub Releases"""
        try:
            import os
            BASE_URL = "https://github.com/hangngt/travil/releases/latest/download"
            SVD_URL = f"{BASE_URL}/svd_model.pkl"

            MODEL_DIR.mkdir(parents=True, exist_ok=True)

            if download_file(SVD_URL, MODEL_DIR / "svd_model.pkl"):
                with open(MODEL_DIR / "svd_model.pkl", "rb") as f:
                    self.svd_model = pickle.load(f)
                logger.info("SVD Model loaded from latest release")
            else:
                logger.error("Failed to download SVD model")
                self.svd_model = None
        except Exception as e:
            logger.error(f"SVD load failed: {e}")
            self.svd_model = None

    def add_rating(self, user_id: str, product_id: int, rating: float):
        """Gọi khi nhận rating mới từ Firebase"""
        self.pending_ratings += 1

        if user_id not in self.rating_cache:
            self.rating_cache[user_id] = {}
        self.rating_cache[user_id][product_id] = rating

        if user_id in self.recommendation_cache:
            del self.recommendation_cache[user_id]
            logger.info(f"Cleared cache for user {user_id} due to new rating")

        if self.pending_ratings >= 1000:
            logger.info(f"Đạt ngưỡng {self.pending_ratings} ratings → Nên retrain model")

        logger.info(f"Saved rating: {user_id} → {product_id} = {rating}")

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
            scores = np.dot(Q, user_vector)

            sorted_item_mappings = sorted(
                self.svd_model['item_to_idx'].items(),
                key=lambda x: x[1]
            )
            item_ids = [item_id for item_id, idx in sorted_item_mappings]

            svd_df = pd.DataFrame({
                'product_id': item_ids,
                'raw_svd_score': scores
            })

            min_s = svd_df['raw_svd_score'].min()
            max_s = svd_df['raw_svd_score'].max()

            if max_s > min_s:
                svd_df['svd_score'] = 1.0 + 4.0 * (svd_df['raw_svd_score'] - min_s) / (max_s - min_s)
            else:
                svd_df['svd_score'] = 4.0

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
        Hybrid Recommendation System với lazy loading
        """
        # Lazy initialization - chỉ load khi có request đầu tiên
        if not self._initialized:
            try:
                self._ensure_initialized()
            except Exception as e:
                logger.error(f"Cannot initialize: {e}")
                # Trả về DataFrame rỗng thay vì crash
                return pd.DataFrame()

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
                top_k=top_k * 3
            ).copy()
        except Exception as e:
            logger.error(f"Content service failed: {e}")
            return self.content_service.get_popular_places(top_k)

        if candidates.empty:
            logger.warning("No candidates found, returning popular places")
            return self.content_service.get_popular_places(top_k)

        # Bước 2: Kết hợp SVD scores nếu có user_id
        if user_id and self.svd_model is not None:
            svd_df = self._get_svd_scores(user_id)

            if svd_df is not None and not svd_df.empty:
                candidates = candidates.merge(svd_df, on='product_id', how='left')
                mean_svd = candidates['svd_score'].mean()
                if pd.isna(mean_svd):
                    mean_svd = 4.0
                candidates['svd_score'] = candidates['svd_score'].fillna(mean_svd)
                candidates['hybrid_score'] = 0.52 * candidates['final_score'] + 0.48 * candidates['svd_score']
            else:
                candidates['hybrid_score'] = candidates['final_score']
        else:
            candidates['hybrid_score'] = candidates['final_score']

        candidates = candidates.sort_values('hybrid_score', ascending=False)

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
            keys_to_delete = [k for k in self.recommendation_cache.keys() if k.startswith(user_id)]
            for key in keys_to_delete:
                del self.recommendation_cache[key]
            logger.info(f"Cleared cache for user {user_id}")
        else:
            self.recommendation_cache.clear()
            logger.info("Cleared all recommendation cache")

    def get_model_stats(self) -> Dict:
        """Lấy thông tin về model"""
        stats = {
            'initialized': self._initialized,
            'svd_loaded': self.svd_model is not None,
            'pending_ratings': self.pending_ratings,
            'cached_users': len(self.recommendation_cache),
            'content_products': len(self.content_service.df) if self.content_service and self.content_service.df is not None else 0
        }

        if self.svd_model:
            stats['svd_users'] = len(self.svd_model.get('user_to_idx', {}))
            stats['svd_items'] = len(self.svd_model.get('item_to_idx', {}))
            stats['svd_factors'] = self.svd_model.get('K', 0)

        return stats
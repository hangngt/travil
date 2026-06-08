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

os.makedirs(DATA_PROCESSED, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)


def download_file(url, output_path):
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
        self.content_service = None
        self.svd_model = None
        self.pending_ratings = 0
        self.rating_cache = {}
        self.recommendation_cache = {}
        self.cache_ttl_minutes = 30
        self._initialized = False

        logger.info("HybridService initialized (lazy loading enabled)")

    def _ensure_initialized(self):
        if self._initialized:
            return

        logger.info("Initializing HybridService components...")
        
        from recommend.backend.ml.content_base.train_tfidf import ContentService
        
        try:
            self.content_service = ContentService()
            
            # TẠM THỜI DISABLE SVD ĐỂ TIẾT KIỆM RAM
            # self._load_svd_model()
            self.svd_model = None
            logger.info("SVD model disabled to reduce memory usage (temporary)")
            
            self._initialized = True
            logger.info("HybridService components loaded successfully")
        except Exception as e:
            logger.error(f"Failed to initialize HybridService: {e}")
            raise

    def _load_svd_model(self):
        """Load SVD model - HIỆN ĐANG DISABLE"""
        try:
            BASE_URL = "https://github.com/hangngt/travil/releases/latest/download"
            SVD_URL = f"{BASE_URL}/svd_model.pkl"

            MODEL_DIR.mkdir(parents=True, exist_ok=True)

            if download_file(SVD_URL, MODEL_DIR / "svd_model.pkl"):
                with open(MODEL_DIR / "svd_model.pkl", "rb") as f:
                    self.svd_model = pickle.load(f)
                logger.info("SVD Model loaded from latest release")
            else:
                logger.warning("Failed to download SVD model")
                self.svd_model = None
        except Exception as e:
            logger.warning(f"SVD load failed (non-critical): {e}")
            self.svd_model = None

    def add_rating(self, user_id: str, product_id: int, rating: float):
        self.pending_ratings += 1

        if user_id not in self.rating_cache:
            self.rating_cache[user_id] = {}
        self.rating_cache[user_id][product_id] = rating

        if user_id in self.recommendation_cache:
            del self.recommendation_cache[user_id]

        if self.pending_ratings >= 1000:
            logger.info(f"Reached {self.pending_ratings} ratings → should retrain model")

        logger.info(f"Saved rating: {user_id} → {product_id} = {rating}")

    def _get_svd_scores(self, user_id: str) -> Optional[pd.DataFrame]:
        """SVD scores - currently disabled"""
        logger.warning("SVD model is disabled, returning None")
        return None

    def recommend(self,
                  user_id: Optional[str] = None,
                  city_name: Optional[str] = None,
                  user_lat: Optional[float] = None,
                  user_lng: Optional[float] = None,
                  viewed_product_id: Optional[int] = None,
                  top_k: int = 15,
                  use_cache: bool = True) -> pd.DataFrame:
        
        if not self._initialized:
            try:
                self._ensure_initialized()
            except Exception as e:
                logger.error(f"Cannot initialize: {e}")
                return pd.DataFrame()

        cache_key = (
            f"{user_id}_"
            f"{city_name}_"
            f"{round(user_lat,4) if user_lat else None}_"
            f"{round(user_lng,4) if user_lng else None}_"
            f"{viewed_product_id}"
        )
        if use_cache and cache_key in self.recommendation_cache:
            cached = self.recommendation_cache[cache_key]
            if datetime.now() < cached['expires_at']:
                logger.info(f"Returning cached recommendations")
                return cached['items'].head(top_k)

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
            return self.content_service.get_popular_places(top_k)

        # SVD disabled, use final_score directly
        candidates['hybrid_score'] = candidates['final_score']
        candidates = candidates.sort_values('hybrid_score', ascending=False)

        result_columns = [
            'product_id',
            'title',
            'location',
            'description',
            'rating',
            'price',
            'lat',
            'lng',
            'image_url',
            'url',
            'hybrid_score'
        ]
        if 'distance_km' in candidates.columns:
            result_columns.append('distance_km')
            
        if user_lat is not None and user_lng is not None:
            candidates = candidates.dropna(subset=['lat', 'lng'])
        result = candidates.head(top_k)[result_columns].copy()
        result = result.replace(
            [np.inf, -np.inf],
                0,
            )

        result = result.fillna(0)

        float_cols = [
            'rating',
            'price',
            'distance_km',
            'hybrid_score'
        ]

        for col in float_cols:
            if col in result.columns:
                result[col] = result[col].round(4)

        if use_cache:
            self.recommendation_cache[cache_key] = {
                'items': result,
                'expires_at': datetime.now() + timedelta(minutes=self.cache_ttl_minutes)
            }

        return result

    def clear_cache(self, user_id: Optional[str] = None):
        if user_id:
            keys_to_delete = [k for k in self.recommendation_cache.keys() if k.startswith(user_id)]
            for key in keys_to_delete:
                del self.recommendation_cache[key]
            logger.info(f"Cleared cache for user {user_id}")
        else:
            self.recommendation_cache.clear()
            logger.info("Cleared all recommendation cache")

    def get_model_stats(self) -> Dict:
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
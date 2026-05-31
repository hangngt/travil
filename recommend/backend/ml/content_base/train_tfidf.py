import pandas as pd
import numpy as np
from pathlib import Path
import joblib
import requests
import math
import os
from sklearn.preprocessing import normalize
import logging
from sklearn.feature_extraction.text import TfidfVectorizer

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[4]

DATA_PROCESSED = BASE_DIR / "recommend" / "backend" / "data" / "processed"
MODEL_DIR = BASE_DIR / "recommend" / "backend" / "ml" / "model"

os.makedirs(DATA_PROCESSED, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)


def download_file(url, output_path):
    if os.path.exists(output_path):
        logger.info(f"Using cached: {output_path.name}")
        return True

    logger.info(f"Downloading {output_path.name} ...")
    try:
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


class ContentService:
    def __init__(self):
        self.df = None
        self.tfidf_vectorizer = None
        self.item_embeddings = None
        self._loaded = False

    def _ensure_loaded(self):
        if self._loaded:
            return

        logger.info("Loading ContentService data and models...")
        
        try:
            BASE_URL = "https://github.com/hangngt/travil/releases/latest/download"
            PRODUCTS_URL = f"{BASE_URL}/products_clean.csv"
            TFIDF_URL = f"{BASE_URL}/tfidf_vectorizer.pkl"

            # CHỈ DOWNLOAD 2 FILE, KHÔNG DOWNLOAD cosine_sim.npy
            if not download_file(PRODUCTS_URL, DATA_PROCESSED / "products_clean.csv"):
                raise RuntimeError("Failed to download products_clean.csv")
            
            if not download_file(TFIDF_URL, DATA_PROCESSED / "tfidf_vectorizer.pkl"):
                raise RuntimeError("Failed to download tfidf_vectorizer.pkl")

            # Load data - chỉ lấy các cột cần thiết
            self.df = pd.read_csv(
                DATA_PROCESSED / "products_clean.csv",
                usecols=['product_id', 'title', 'location', 'rating', 
                        'booked_count', 'review_count', 'lat', 'lng', 'description']
            ).reset_index(drop=True)

            # Tạo combined text
            self.df['combined_text'] = (
                self.df['title'].fillna('') + " " + 
                self.df.get('description', '').fillna('') + " " + 
                self.df['location'].fillna('')
            )

            # Load TF-IDF vectorizer
            self.tfidf_vectorizer = joblib.load(DATA_PROCESSED / "tfidf_vectorizer.pkl")

            # Fix numeric columns
            numeric_cols = ['rating', 'booked_count', 'review_count', 'lat', 'lng']
            for col in numeric_cols:
                if col in self.df.columns:
                    self.df[col] = pd.to_numeric(self.df[col], errors='coerce')

            # Tạo item embeddings - nhưng không lưu cosine_sim riêng
            tfidf_matrix = self.tfidf_vectorizer.transform(self.df['combined_text'].fillna(''))
            self.item_embeddings = normalize(tfidf_matrix).toarray().astype(np.float32)
            
            # Giải phóng memory
            del tfidf_matrix

            self._loaded = True
            logger.info(f"ContentService loaded {len(self.df)} products (embeddings shape: {self.item_embeddings.shape})")

        except Exception as e:
            logger.error(f"Failed to load ContentService: {e}")
            raise

    # Các hàm haversine_distance, calculate_distances_vectorized giữ nguyên
    def haversine_distance(self, lat1, lon1, lat2, lon2):
        R = 6371.0
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    def calculate_distances_vectorized(self, user_lat: float, user_lng: float, lats: np.ndarray, lngs: np.ndarray):
        self._ensure_loaded()
        R = 6371.0
        user_lat_rad = np.radians(user_lat)
        user_lng_rad = np.radians(user_lng)
        lats_rad = np.radians(lats)
        lngs_rad = np.radians(lngs)
        dlat = lats_rad - user_lat_rad
        dlon = lngs_rad - user_lng_rad
        a = np.sin(dlat / 2)**2 + np.cos(user_lat_rad) * np.cos(lats_rad) * np.sin(dlon / 2)**2
        c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
        return R * c

    def filter_by_city(self, city_name: str, top_k=20):
        self._ensure_loaded()
        city_df = self.df[self.df['location'].str.contains(city_name, case=False, na=False)].copy()
        if len(city_df) == 0:
            logger.warning(f"Không tìm thấy địa điểm nào tại {city_name}")
            return pd.DataFrame()
        city_df['popularity'] = np.log1p(city_df['booked_count'].fillna(0)) + np.log1p(city_df['review_count'].fillna(0))
        city_df['score'] = city_df['rating'].fillna(4.0) * 0.6 + city_df['popularity'] * 0.4
        city_df = city_df.sort_values('score', ascending=False)
        return city_df.head(top_k)

    def get_nearby_places(self, user_lat: float, user_lng: float, radius_km=10, top_k=15):
        self._ensure_loaded()
        valid_geo_df = self.df.dropna(subset=['lat', 'lng']).copy()
        if len(valid_geo_df) == 0:
            logger.warning("Không có sản phẩm nào có tọa độ")
            return pd.DataFrame()
        valid_geo_df['distance_km'] = self.calculate_distances_vectorized(
            user_lat, user_lng,
            valid_geo_df['lat'].values,
            valid_geo_df['lng'].values
        )
        nearby = valid_geo_df[valid_geo_df['distance_km'] <= radius_km].copy()
        if len(nearby) == 0:
            logger.warning(f"Không có địa điểm nào trong bán kính {radius_km}km")
            return pd.DataFrame()
        nearby['popularity'] = np.log1p(nearby['booked_count'].fillna(0)) + np.log1p(nearby['review_count'].fillna(0))
        alpha, beta, gamma = 0.5, 0.3, 0.2
        nearby['score'] = (
            alpha * nearby['rating'].fillna(4.0) +
            beta * (nearby['popularity'] / nearby['popularity'].max() if nearby['popularity'].max() > 0 else 0) -
            gamma * (nearby['distance_km'] / radius_km)
        )
        nearby = nearby.sort_values('score', ascending=False)
        logger.info(f"Tìm thấy {len(nearby)} địa điểm trong bán kính {radius_km}km")
        return nearby.head(top_k)

    def recommend_hybrid(self,
                         city_name: str = None,
                         user_lat: float = None,
                         user_lng: float = None,
                         viewed_product_id: int = None,
                         radius_km: float = 10,
                         top_k: int = 15):
        self._ensure_loaded()
        candidates = self.df.copy()

        # LAYER 1: GEO-SPATIAL FILTERING
        if city_name:
            candidates = candidates[candidates['location'].str.contains(city_name, case=False, na=False)].copy()
            logger.info(f"Lọc theo thành phố: {city_name} → {len(candidates)} địa điểm")
        elif user_lat is not None and user_lng is not None:
            candidates = candidates.dropna(subset=['lat', 'lng']).copy()
            if len(candidates) > 0:
                candidates['distance_km'] = self.calculate_distances_vectorized(
                    user_lat, user_lng,
                    candidates['lat'].values,
                    candidates['lng'].values
                )
                candidates = candidates[candidates['distance_km'] <= radius_km].copy()
                logger.info(f"Lọc theo GPS (bán kính {radius_km}km) → {len(candidates)} địa điểm")

        if len(candidates) == 0:
            logger.warning("Không có địa điểm phù hợp, hiển thị gợi ý phổ biến nhất")
            return self.df.nlargest(top_k, 'booked_count')[['product_id', 'title', 'location', 'rating', 'booked_count']]

        # LAYER 2: CONTENT SIMILARITY
        if viewed_product_id is not None:
            target_indices = self.df[self.df['product_id'] == viewed_product_id].index
            if len(target_indices) > 0:
                target_idx = target_indices[0]
                target_vector = self.item_embeddings[target_idx]
                similarity_scores = np.dot(self.item_embeddings, target_vector)
                candidates['similarity_score'] = similarity_scores[candidates.index]
            else:
                candidates['similarity_score'] = 0.0
        else:
            candidates['similarity_score'] = 0.0

        # LAYER 3: POPULARITY
        candidates['popularity_score'] = np.log1p(candidates['booked_count'].fillna(0)) + np.log1p(candidates['review_count'].fillna(0))

        # LAYER 4: COMBINED RANKING
        alpha, beta, gamma, delta = 0.35, 0.35, 0.20, 0.10
        max_popularity = candidates['popularity_score'].max()
        max_similarity = candidates['similarity_score'].max()

        candidates['final_score'] = (
            alpha * candidates['rating'].fillna(4.0) +
            beta * (candidates['popularity_score'] / max_popularity if max_popularity > 0 else 0) +
            gamma * (candidates['similarity_score'] / max_similarity if max_similarity > 0 else 0)
        )

        if 'distance_km' in candidates.columns:
            candidates['final_score'] -= delta * (candidates['distance_km'] / radius_km)

        candidates = candidates.sort_values('final_score', ascending=False)

        result_columns = ['product_id', 'title', 'location', 'rating', 'similarity_score', 'popularity_score', 'final_score']
        if 'distance_km' in candidates.columns:
            result_columns.insert(4, 'distance_km')

        return candidates.head(top_k)[result_columns]

    def get_popular_places(self, top_k=20):
        self._ensure_loaded()
        popular = self.df.copy()
        popular['popularity'] = np.log1p(popular['booked_count'].fillna(0)) + np.log1p(popular['review_count'].fillna(0))
        popular = popular.sort_values('popularity', ascending=False)
        return popular.head(top_k)[['product_id', 'title', 'location', 'rating', 'booked_count', 'review_count']]

    def get_highly_rated(self, top_k=20, min_ratings=10):
        self._ensure_loaded()
        highly_rated = self.df[self.df['review_count'] >= min_ratings].copy()
        highly_rated = highly_rated.sort_values('rating', ascending=False)
        return highly_rated.head(top_k)[['product_id', 'title', 'location', 'rating', 'review_count']]
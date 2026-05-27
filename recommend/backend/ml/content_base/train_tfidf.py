import pandas as pd
import numpy as np
from pathlib import Path
import pickle
import math
import requests
import os
from sklearn.preprocessing import normalize

BASE_DIR = Path(__file__).resolve().parents[2]

DATA_PROCESSED = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "ml" / "model"

# tạo folder nếu chưa có
os.makedirs(DATA_PROCESSED, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)


def download_file(url, output_path):
    if not os.path.exists(output_path):
        print(f"Downloading {output_path.name} ...")

        response = requests.get(url)

        with open(output_path, "wb") as f:
            f.write(response.content)

        print(f"Saved: {output_path}")


class ContentService:
    def __init__(self):
        self.df = None
        self.tfidf_vectorizer = None
        self.cosine_sim = None
        self._load_data()

    def _load_data(self):
        # tạo TF-IDF matrix (KHÔNG dùng cosine.npy nữa)
        tfidf_matrix = self.tfidf_vectorizer.transform(self.df['title'])

        # item embeddings
        self.item_embeddings = normalize(tfidf_matrix).toarray().astype(np.float32)


        # ===== GOOGLE DRIVE DIRECT LINKS =====
        PRODUCTS_URL = "https://drive.google.com/file/d/1tB_ZRB6wBSYuyIUleUI1G5xPZJ7W2NMY/view?usp=drive_link"
        TFIDF_URL = "https://drive.google.com/file/d/1u9xvX0UaJcEhAb7PFYCigP0doTzvYLwE/view?usp=drive_link"
        COSINE_URL = "https://drive.google.com/file/d/1g2KeGp4uQMhmt-pSCyliybmiqgNiiEf6/view?usp=drive_link"

        # ===== DOWNLOAD FILES =====
        download_file(
            PRODUCTS_URL,
            DATA_PROCESSED / "products_clean.csv"
        )

        download_file(
            TFIDF_URL,
            DATA_PROCESSED / "tfidf_vectorizer.pkl"
        )

        download_file(
            COSINE_URL,
            DATA_PROCESSED / "cosine_sim.npy"
        )

        print("Loading data...")

        self.df = pd.read_csv(
            DATA_PROCESSED / "products_clean.csv"
        ).reset_index(drop=True)

        with open(
            DATA_PROCESSED / "tfidf_vectorizer.pkl",
            "rb"
        ) as f:
            self.tfidf_vectorizer = pickle.load(f)

        self.cosine_sim = np.load(
            DATA_PROCESSED / "cosine_sim.npy"
        )

        print("Data loaded successfully")

        # fix numeric columns
        numeric_cols = [
        'rating',
        'booked_count',
        'review_count',
        'lat',
        'lng'
        ]

        for col in numeric_cols:
            self.df[col] = pd.to_numeric(
                self.df[col],
                errors='coerce'
            )

        
        # Load TF-IDF & Cosine Similarity
        with open(DATA_PROCESSED / 'tfidf_vectorizer.pkl', 'rb') as f:
            self.tfidf_vectorizer = pickle.load(f)
        
        self.cosine_sim = np.load(DATA_PROCESSED / 'cosine_sim.npy')
        print(f" Loaded {len(self.df)} products for recommendation")
        print(self.df.dtypes)

    #HAVERSINE DISTANCE
    def haversine_distance(self, lat1, lon1, lat2, lon2):
        # """
        # Tính khoảng cách trên mặt cầu Trái Đất (km)
        # Công thức: d = 2r * arcsin(√(sin²(Δφ/2) + cos φ1 * cos φ2 * sin²(Δλ/2)))
        # """
        R = 6371.0  # Bán kính Trái Đất (km)
        
        # Chuyển sang radian
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        # Δφ và Δλ
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        # Công thức Haversine
        a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c
    
    def calculate_distances_vectorized(self, user_lat: float, user_lng: float, lats: np.ndarray, lngs: np.ndarray):
        # """Vectorized version cho nhiều điểm cùng lúc"""
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
        
    #CASE 1: FILTER BY CITY 
    def filter_by_city(self, city_name: str, top_k=20):
        # """
        # CASE 1 - User chọn thành phố cụ thể
        # Step 1: Filter location = city
        # Step 2: Ranking theo rating + popularity
        # Step 3: Top-K recommendation
        # """
        # Step 1: Filter theo location
        city_df = self.df[self.df['location'].str.contains(city_name, case=False, na=False)].copy()
        
        if len(city_df) == 0:
            print(f" Không tìm thấy địa điểm nào tại {city_name}")
            return pd.DataFrame()
        
        # Step 2: Tính score = rating + popularity
        # Popularity = log(1 + booked_count) + log(1 + review_count)
        city_df['popularity'] = np.log1p(city_df['booked_count'].fillna(0)) + np.log1p(city_df['review_count'].fillna(0))
        city_df['score'] = city_df['rating'].fillna(4.0) * 0.6 + city_df['popularity'] * 0.4
        
        # Step 3: Top-K
        city_df = city_df.sort_values('score', ascending=False)
        
        return city_df.head(top_k)
    
    #CASE 2: NEARBY GPS 
    def get_nearby_places(self, user_lat: float, user_lng: float, radius_km=10, top_k=15):
        """
        CASE 2 - User bật GPS
        Step 1: Lấy lat_user, lng_user
        Step 2: Tính distance tới mọi products (Haversine)
        Step 3: Lọc: distance <= radius_km (Công thức số 10)
        Step 4: Ranking theo final score
        """
        # Lọc các sản phẩm có tọa độ
        valid_geo_df = self.df.dropna(subset=['lat', 'lng']).copy()
        
        if len(valid_geo_df) == 0:
            print(" Không có sản phẩm nào có tọa độ")
            return pd.DataFrame()
        
        # Step 2: Tính khoảng cách
        valid_geo_df['distance_km'] = self.calculate_distances_vectorized(
            user_lat, user_lng,
            valid_geo_df['lat'].values,
            valid_geo_df['lng'].values
        )
        
        # Step 3: Lọc trong bán kính (d <= radius)
        nearby = valid_geo_df[valid_geo_df['distance_km'] <= radius_km].copy()
        
        if len(nearby) == 0:
            print(f" Không có địa điểm nào trong bán kính {radius_km}km")
            return pd.DataFrame()
        
        # Step 4: Ranking score (Công thức số 12)
        # Score = α·Rating + β·Popularity - γ·Distance
        # α = 0.5, β = 0.3, γ = 0.2
        nearby['popularity'] = np.log1p(nearby['booked_count'].fillna(0)) + np.log1p(nearby['review_count'].fillna(0))
        
        alpha, beta, gamma = 0.5, 0.3, 0.2
        nearby['score'] = (
            alpha * nearby['rating'].fillna(4.0) +
            beta * (nearby['popularity'] / nearby['popularity'].max() if nearby['popularity'].max() > 0 else 0) -
            gamma * (nearby['distance_km'] / radius_km)
        )
        
        nearby = nearby.sort_values('score', ascending=False)
        
        print(f" Tìm thấy {len(nearby)} địa điểm trong bán kính {radius_km}km")
        return nearby.head(top_k)
    
    # HYBRID RECOMMENDATION 
    def recommend_hybrid(self, 
                         city_name: str = None,
                         user_lat: float = None,
                         user_lng: float = None,
                         viewed_product_id: int = None,
                         radius_km: float = 10,
                         top_k: int = 15):
        # """
        # Hybrid Recommendation: Geo Filter → Content Similarity → Popularity → Ranking
        # Flow thực tế giống Klook/ Traveloka
        # """
        candidates = self.df.copy()
        
        #  LAYER 1: GEO-SPATIAL FILTERING 
        if city_name:
            # Case 1: User chọn thành phố
            candidates = candidates[candidates['location'].str.contains(city_name, case=False, na=False)].copy()
            print(f" Lọc theo thành phố: {city_name} → {len(candidates)} địa điểm")
            
        elif user_lat is not None and user_lng is not None:
            # Case 2: User bật GPS
            candidates = candidates.dropna(subset=['lat', 'lng']).copy()
            if len(candidates) > 0:
                candidates['distance_km'] = self.calculate_distances_vectorized(
                    user_lat, user_lng,
                    candidates['lat'].values,
                    candidates['lng'].values
                )
                candidates = candidates[candidates['distance_km'] <= radius_km].copy()
                print(f" Lọc theo GPS (bán kính {radius_km}km) → {len(candidates)} địa điểm")
        
        # Nếu không có kết quả, fallback về gợi ý phổ biến nhất
        if len(candidates) == 0:
            print("Không có địa điểm phù hợp, hiển thị gợi ý phổ biến nhất")
            return self.df.nlargest(top_k, 'booked_count')[['product_id', 'title', 'location', 'rating', 'booked_count']]
        
        #  LAYER 2: CONTENT SIMILARITY 
        if viewed_product_id is not None:
            # Tìm sản phẩm tương tự dựa trên nội dung
            target_indices = self.df[self.df['product_id'] == viewed_product_id].index

            if len(target_indices) > 0:
                target_idx = target_indices[0]

                # vector của item đang xem
                target_vector = self.item_embeddings[target_idx]

                # dot product similarity với tất cả items
                similarity_scores = np.dot(self.item_embeddings, target_vector)

                # gán score cho candidates
                candidates['similarity_score'] = similarity_scores[candidates.index]
            else:
                candidates['similarity_score'] = 0.0
        else:
            candidates['similarity_score'] = 0.0
        
        #  LAYER 3: POPULARITY 
        candidates['popularity_score'] = np.log1p(candidates['booked_count'].fillna(0)) + np.log1p(candidates['review_count'].fillna(0))
        
        #  LAYER 4: COMBINED RANKING 
        # Score = α·Rating + β·Popularity + γ·Similarity - δ·Distance
        alpha, beta, gamma, delta = 0.35, 0.35, 0.20, 0.10
        
        # Normalize các thành phần
        max_popularity = candidates['popularity_score'].max()
        max_similarity = candidates['similarity_score'].max()
        
        candidates['final_score'] = (
            alpha * candidates['rating'].fillna(4.0) +
            beta * (candidates['popularity_score'] / max_popularity if max_popularity > 0 else 0) +
            gamma * (candidates['similarity_score'] / max_similarity if max_similarity > 0 else 0)
        )
        
        # Penalty cho khoảng cách xa (nếu có GPS)
        if 'distance_km' in candidates.columns:
            candidates['final_score'] -= delta * (candidates['distance_km'] / radius_km)
        
        # Sắp xếp theo score
        candidates = candidates.sort_values(
            'final_score',
            ascending=False
        )

        # Danh sách cột trả về
        result_columns = [
            'product_id',
            'title',
            'location',
            'rating',
            'similarity_score',
            'popularity_score',
            'final_score'
        ]

        # Nếu có GPS thì thêm distance
        if 'distance_km' in candidates.columns:
            result_columns.insert(4, 'distance_km')

        # Return Top-K
        return candidates.head(top_k)[result_columns]

    #UTILITY FUNCTIONS 
    def get_popular_places(self, top_k=20):
        """Lấy các địa điểm phổ biến nhất"""
        popular = self.df.copy()
        popular['popularity'] = np.log1p(popular['booked_count'].fillna(0)) + np.log1p(popular['review_count'].fillna(0))
        popular = popular.sort_values('popularity', ascending=False)
        return popular.head(top_k)[['product_id', 'title', 'location', 'rating', 'booked_count', 'review_count']]
    
    def get_highly_rated(self, top_k=20, min_ratings=10):
        """Lấy các địa điểm có rating cao nhất"""
        highly_rated = self.df[self.df['review_count'] >= min_ratings].copy()
        highly_rated = highly_rated.sort_values('rating', ascending=False)
        return highly_rated.head(top_k)[['product_id', 'title', 'location', 'rating', 'review_count']]



# %%
#test & demo
if __name__ == "__main__":
    print("="*80)
    print("LOCATION + CONTENT BASED RECOMMENDATION SYSTEM")
    print("="*80)
    
    service = ContentService()
    
    # Test 1: By City
    print("\nCASE 1: User chọn Đà Nẵng")
    danang_recs = service.filter_by_city("Da Nang", top_k=10)
    print(danang_recs[['product_id', 'title', 'location', 'rating', 'score']].head(10))
    
    # Test 2: Nearby GPS
    print("\nCASE 2: User bật GPS tại Đà Nẵng")
    nearby = service.get_nearby_places(16.0544, 108.2022, radius_km=15, top_k=10)
    print(nearby[['product_id', 'title', 'distance_km', 'rating', 'score']].head(10))
    
    # Test 3: Hybrid
    print("\nCASE 3: Hybrid Recommendation")
    hybrid = service.recommend_hybrid(
        city_name="Da Nang",
        viewed_product_id=2,   # Ba Na Hills
        top_k=10
    )
    print(hybrid[['product_id', 'title', 'location', 'rating', 'final_score']].head(10))



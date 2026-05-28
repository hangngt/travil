import pandas as pd
import numpy as np
import pickle
from pathlib import Path

from ml.content_base.train_tfidf import ContentService, download_file # Import class cũ 

BASE_DIR = Path(__file__).resolve().parents[2]
DATA_PROCESSED = BASE_DIR / "data" / "processed"
MODEL_DIR = BASE_DIR / "ml" / "model"


class HybridService:
    def __init__(self):

        self.content_service = ContentService()
        self.svd_model = None

        print(" Loading SVD model...")
        self._load_svd_model()

    def _load_svd_model(self):

        try:
            SVD_URL = "https://drive.google.com/uc?id=1aumP3Eo6ZwM0HwBk-33B7rOvXQiQsr0F"

            download_file(
                SVD_URL,
                MODEL_DIR / "svd_model.pkl"
            )

            with open(MODEL_DIR / "svd_model.pkl", "rb") as f:
                self.svd_model = pickle.load(f)


        except Exception as e:
            print(" SVD ERROR:", str(e))
            self.svd_model = None
    # SVD RECOMMENDATION 
    def _get_svd_scores(self, user_id: str):
        """Trả về điểm SVD đã được chuẩn hóa cho tất cả items của 1 user"""
        if self.svd_model is None or user_id not in self.svd_model['user_to_idx']:
            return None
        
        P = self.svd_model['P']
        Q = self.svd_model['Q']
        user_idx = self.svd_model['user_to_idx'][user_id]
        
        user_vector = P[user_idx]
        scores = np.dot(Q, user_vector)  # Dot product ẩn
        
        #  Sắp xếp item_ids theo đúng số thứ tự hàng (0, 1, 2...) trong ma trận Q
        sorted_item_mappings = sorted(self.svd_model['item_to_idx'].items(), key=lambda x: x[1])
        item_ids = [item_id for item_id, idx in sorted_item_mappings]
        
        svd_df = pd.DataFrame({
            'product_id': item_ids,
            'raw_svd_score': scores
        })
        
        #  Chuẩn hóa đưa điểm SVD về dải [1.0, 5.0] để cùng pha với final_score
        min_s = svd_df['raw_svd_score'].min()
        max_s = svd_df['raw_svd_score'].max()
        
        if max_s > min_s:
            svd_df['svd_score'] = 1.0 + 4.0 * (svd_df['raw_svd_score'] - min_s) / (max_s - min_s)
        else:
            svd_df['svd_score'] = 4.0  # Fallback nếu mọi điểm số bằng nhau
            
        return svd_df[['product_id', 'svd_score']]

    # HYBRID RECOMMENDATION 
    def recommend(self, 
                  user_id: str = None,
                  city_name: str = None,
                  user_lat: float = None,
                  user_lng: float = None,
                  viewed_product_id: int = None,
                  top_k: int = 15):
        # """
        # Hybrid Recommendation System
        # Ưu tiên: SVD (nếu user có lịch sử) → Content + Location
        # """
        # Bước 1: Lấy candidates từ Content + Geo
        candidates = self.content_service.recommend_hybrid(
            city_name=city_name,
            user_lat=user_lat,
            user_lng=user_lng,
            viewed_product_id=viewed_product_id,
            top_k=top_k * 3  # Lấy dư để rerank
        ).copy()

        # Bước 2: Nếu có user_id → Kết hợp SVD
        if user_id and self.svd_model is not None:
            svd_df = self._get_svd_scores(user_id)
            
            if svd_df is not None and not svd_df.empty:
                # Merge SVD score
                candidates = candidates.merge(svd_df, on='product_id', how='left')
                # Điền giá trị trung bình chuẩn (thường là ~4.0) cho các sản phẩm mới chưa có điểm SVD
                mean_svd = candidates['svd_score'].mean() if pd.notna(candidates['svd_score'].mean()) else 4.0
                candidates['svd_score'] = candidates['svd_score'].fillna(mean_svd)
                
                # Hybrid Score (có thể điều chỉnh trọng số)
                candidates['hybrid_score'] = (
                    0.55 * candidates['final_score'] +      # Content + Location
                    0.45 * candidates['svd_score']          # Collaborative
                )
            else:
                candidates['hybrid_score'] = candidates['final_score']
        else:
            candidates['hybrid_score'] = candidates['final_score']

        # Sắp xếp và trả về Top-K
        candidates = candidates.sort_values('hybrid_score', ascending=False)
        
        #  Tạo danh sách cột động tùy thuộc vào việc có bật định vị GPS hay không
        result_columns = ['product_id', 'title', 'location', 'rating', 'hybrid_score']
        if 'distance_km' in candidates.columns:
            result_columns.append('distance_km')
 
        return candidates.head(top_k)[result_columns].round(4)

#  TEST 3 CASES 
if __name__ == "__main__":
    hybrid = HybridService()
    
    print("="*90)
    print(" HYBRID RECOMMENDATION SYSTEM TEST")
    print("="*90)
 
    #CASE 1: SVD + Content cho User cũ 
    print("\n CASE 1: SVD + Content cho User cũ")
    recs_svd = hybrid.recommend(
        user_id="Klook User",     # User có trong ma trận SVD
        city_name="Da Nang",
        top_k=5
    )
    print(recs_svd)  
 
    #  CASE 2: Content + Location Only 
    print("\n CASE 2: Content + Location (Không dùng SVD, dùng GPS)")
    recs_content = hybrid.recommend(
        city_name="Da Nang",
        user_lat=16.0544,      # Tọa độ trung tâm Đà Nẵng
        user_lng=108.2022,
        top_k=5
    )
    print(recs_content)  
 
    #CASE 3: Hybrid với viewed item 
    print("\n CASE 3: Hybrid + Similar to viewed product")
    recs_hybrid = hybrid.recommend(
        user_id="Klook User",
        city_name="Da Nang",
        viewed_product_id=2,   # Ví dụ: Ba Na Hills
        top_k=5
    )
    print(recs_hybrid)


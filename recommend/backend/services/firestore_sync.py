import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
from pathlib import Path
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FirestoreSync:
    def __init__(self):
        """Khởi tạo Firebase connection"""
        if not firebase_admin._apps:
            try:
                cred = credentials.Certificate("firebase/service_account.json")
                firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase initialized successfully")
            except Exception as e:
                logger.error(f"❌ Firebase init failed: {e}")
                raise
        
        self.db = firestore.client()
        self.processed_dir = Path("data/processed")
        self.processed_dir.mkdir(parents=True, exist_ok=True)

    def sync_products(self) -> pd.DataFrame:
        """Sync toàn bộ products từ Firestore"""
        try:
            logger.info("🔄 Đang sync Products từ Firestore...")
            docs = self.db.collection('products').stream()
            
            data = []
            for doc in docs:
                item = doc.to_dict()
                item['product_id'] = doc.id  # Dùng document ID làm product_id
                data.append(item)
            
            df = pd.DataFrame(data)
            
            # Lưu file
            output_path = self.processed_dir / 'products_clean.csv'
            df.to_csv(output_path, index=False, encoding='utf-8')
            
            logger.info(f"✅ Synced {len(df)} products → {output_path}")
            return df
            
        except Exception as e:
            logger.error(f"❌ Sync products failed: {e}")
            raise

    def sync_interactions(self) -> pd.DataFrame:
        """Sync ratings từ collection interactions"""
        try:
            logger.info("🔄 Đang sync Interactions (ratings) từ Firestore...")
            docs = self.db.collection('interactions').stream()
            
            data = [doc.to_dict() for doc in docs]
            df = pd.DataFrame(data)
            
            # Đảm bảo có các cột cần thiết
            if not df.empty:
                if 'timestamp' not in df.columns:
                    df['timestamp'] = datetime.now()
            
            output_path = self.processed_dir / 'user_item_ratings_real.csv'
            df.to_csv(output_path, index=False, encoding='utf-8')
            
            logger.info(f"✅ Synced {len(df)} ratings → {output_path}")
            return df
            
        except Exception as e:
            logger.error(f"❌ Sync interactions failed: {e}")
            raise

    def sync_all(self):
        """Sync cả products và interactions"""
        self.sync_products()
        self.sync_interactions()
        logger.info("🎉 Firestore Sync hoàn tất!")
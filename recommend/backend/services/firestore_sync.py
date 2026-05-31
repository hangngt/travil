import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import os
from pathlib import Path
from datetime import datetime
import logging


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[3]

SERVICE_ACCOUNT_PATH = BASE_DIR / "recommend" / "backend" / "config" / "firebase-credentials.json"


class FirestoreSync:
    def __init__(self):
        if not firebase_admin._apps:
            try:
                # Thử nhiều cách để lấy credentials
                cred_path = None
                
                # Cách 1: Từ environment variable
                if os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
                    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
                # Cách 2: Từ file mặc định
                elif SERVICE_ACCOUNT_PATH.exists():
                    cred_path = str(SERVICE_ACCOUNT_PATH)
                # Cách 3: Từ thư mục firebase
                elif (BASE_DIR / "firebase" / "service_account.json").exists():
                    cred_path = str(BASE_DIR / "firebase" / "service_account.json")
                
                if cred_path:
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    logger.info(f"Firebase connected successfully using: {cred_path}")
                else:
                    raise Exception("No Firebase credentials found")
                    
            except Exception as e:
                logger.error(f"Firebase connection failed: {e}")
                raise
        
        self.db = firestore.client()
        self.processed_dir = BASE_DIR / "recommend" / "backend" / "data" / "processed"
        self.processed_dir.mkdir(parents=True, exist_ok=True)

    def sync_products(self) -> pd.DataFrame:
        """Sync toàn bộ products từ Firestore với chunking"""
        try:
            logger.info("Syncing Products from Firestore...")
            
            # Dùng pagination để tránh timeout
            all_data = []
            last_doc = None
            batch_count = 0
            
            while True:
                query = self.db.collection('products').limit(500)
                if last_doc:
                    query = query.start_after(last_doc)
                
                docs = query.get()
                if not docs:
                    break
                
                batch_data = []
                for doc in docs:
                    item = doc.to_dict()
                    item['product_id'] = doc.id
                    batch_data.append(item)
                
                all_data.extend(batch_data)
                last_doc = docs[-1]
                batch_count += 1
                logger.info(f"Fetched batch {batch_count}: {len(batch_data)} products")
            
            df = pd.DataFrame(all_data)
            
            # Lưu file
            output_path = self.processed_dir / 'products_clean.csv'
            df.to_csv(output_path, index=False, encoding='utf-8')
            
            logger.info(f"Synced {len(df)} products → {output_path}")
            return df
            
        except Exception as e:
            logger.error(f"Sync products failed: {e}")
            raise

    def sync_interactions(self) -> pd.DataFrame:
        """Sync ratings từ collection interactions với chunking"""
        try:
            logger.info("Syncing Interactions (ratings) from Firestore...")
            
            all_data = []
            last_doc = None
            batch_count = 0
            
            while True:
                query = self.db.collection('interactions').limit(500)
                if last_doc:
                    query = query.start_after(last_doc)
                
                docs = query.get()
                if not docs:
                    break
                
                batch_data = [doc.to_dict() for doc in docs]
                all_data.extend(batch_data)
                last_doc = docs[-1]
                batch_count += 1
                logger.info(f"Fetched batch {batch_count}: {len(batch_data)} interactions")
            
            df = pd.DataFrame(all_data)
            
            if not df.empty and 'timestamp' not in df.columns:
                df['timestamp'] = datetime.now()
            
            output_path = self.processed_dir / 'user_item_ratings_real.csv'
            df.to_csv(output_path, index=False, encoding='utf-8')
            
            logger.info(f"Synced {len(df)} ratings → {output_path}")
            return df
            
        except Exception as e:
            logger.error(f"Sync interactions failed: {e}")
            raise

    def sync_all(self):
        """Sync cả products và interactions"""
        self.sync_products()
        self.sync_interactions()
        logger.info("Firestore Sync completed!")
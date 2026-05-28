import firebase_admin
from firebase_admin import credentials, firestore, storage
from pathlib import Path
import os

class FirebaseService:
    def __init__(self):
        self.db = None
        self.bucket = None
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        if not firebase_admin._apps:
            # Đường dẫn đến file credentials
            BASE_DIR = Path(__file__).resolve().parent.parent.parent
            cred_path = BASE_DIR / "config" / "firebase-credentials.json"  # ← Tên file của bạn
            
            if cred_path.exists():
                cred = credentials.Certificate(str(cred_path))
                firebase_admin.initialize_app(cred, {
                    'storageBucket': 'ten-project-cua-ban.appspot.com'  # ← Thay bằng tên project
                })
                print("✓ Firebase initialized with credentials file")
            else:
                print(f"✗ Credentials file not found at {cred_path}")
                raise FileNotFoundError(f"Please place firebase-credentials.json at {cred_path}")
        
        self.db = firestore.client()
        self.bucket = storage.bucket()
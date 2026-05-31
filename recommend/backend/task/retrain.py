import sys
from pathlib import Path
from datetime import datetime
import logging
import fcntl
import os

BASE_DIR = Path(__file__).resolve().parents[2]  
sys.path.append(str(BASE_DIR))

# Tạo thư mục logs
LOG_DIR = BASE_DIR / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

# LOCK FILE để tránh retrain nhiều lần cùng lúc
LOCK_FILE = LOG_DIR / "retrain.lock"

# LOGGING 
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s | %(levelname)s | %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(LOG_DIR / "retrain.log", encoding='utf-8', mode='a')
    ],
    force=True
)
logger = logging.getLogger(__name__)

from recommend.backend.services.firestore_sync import FirestoreSync
from recommend.backend.ml.content_base.train_tfidf import train_content_model
from recommend.backend.ml.collaborative.train_svd import train_svd_model
from recommend.backend.task.push_github import push_models_to_github


def acquire_lock():
    """Chỉ cho phép một tiến trình retrain chạy tại một thời điểm"""
    try:
        lock_file = open(LOCK_FILE, 'w')
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return lock_file
    except (IOError, OSError):
        logger.warning("Another retrain process is already running")
        return None


def release_lock(lock_file):
    """Giải phóng lock"""
    if lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_UN)
        lock_file.close()


def full_retrain(sync_firestore: bool = True):
    """
    Full Retrain Pipeline - Production Ready
    Chỉ cho phép chạy một instance duy nhất
    """
    # Kiểm tra lock
    lock = acquire_lock()
    if not lock:
        logger.warning("Skipping retrain - another instance is running")
        return False
    
    start_time = datetime.now()
    
    try:
        logger.info(f"STARTING FULL RETRAIN - {start_time.strftime('%Y-%m-%d %H:%M:%S')}")

        # STEP 1: SYNC FIRESTORE 
        if sync_firestore:
            logger.info("Step 1: Syncing data from Firestore...")
            try:
                sync = FirestoreSync()
                sync.sync_all()
                logger.info("Firestore sync completed successfully")
            except Exception as e:
                logger.warning(f"Firestore sync failed (using local data): {e}")
        else:
            logger.info("Skip Firestore sync → Using local CSV files")

        # STEP 2: CONTENT MODEL 
        logger.info("Step 2: Training Content-based Model (TF-IDF)...")
        content_ok = train_content_model()
        if not content_ok:
            raise Exception("Content model training failed")
        logger.info("Content model trained successfully")

        # STEP 3: SVD MODEL
        logger.info("Step 3: Training Collaborative Model (SVD)...")
        svd_ok = train_svd_model()
        if not svd_ok:
            raise Exception("SVD model training failed")
        logger.info("SVD model trained successfully")

        # STEP 4: PUSH TO GITHUB RELEASE
        logger.info("Step 4: Uploading models to GitHub Release...")
        new_tag = push_models_to_github(auto_tag=True)

        if new_tag:
            logger.info(f"Successfully created GitHub Release: {new_tag}")
        else:
            logger.warning("Failed to push to GitHub Release (continuing)")

        # SUMMARY
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds() / 60

        logger.info("FULL RETRAIN COMPLETED!")
        logger.info(f"Time: {duration:.1f} minutes")
        logger.info(f"Completed at: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")

        return True

    except Exception as e:
        logger.error(f"FULL RETRAIN FAILED: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False
    
    finally:
        release_lock(lock)


if __name__ == "__main__":
    # Chạy retrain với sync từ Firestore
    full_retrain(sync_firestore=True)
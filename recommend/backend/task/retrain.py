import sys
from pathlib import Path
from datetime import datetime
import logging

BASE_DIR = Path(__file__).resolve().parents[2]  
sys.path.append(str(BASE_DIR))

from recommend.backend.services.firestore_sync import FirestoreSync
from recommend.backend.ml.content_base.train_tfidf import train_content_model
from recommend.backend.ml.collaborative.train_svd import train_svd_model
from recommend.backend.task.push_github import push_models_to_github

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s : %(levelname)s : %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(BASE_DIR / "logs/retrain.log", encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)


def full_retrain(sync_firestore: bool = True):
    """
    Full Retrain Pipeline - Production Ready
    """
    start_time = datetime.now()
    logger.info("=" * 70)
    logger.info(f"BẮT ĐẦU FULL RETRAIN - {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 70)

    try:
        # STEP 1: SYNC FIRESTORE 
        if sync_firestore:
            logger.info(" Step 1: Syncing data from Firestore...")
            try:
                sync = FirestoreSync()
                sync.sync_all()
                logger.info(" Firestore sync completed successfully")
            except Exception as e:
                logger.warning(f" Firestore sync failed (using local data): {e}")
        else:
            logger.info(" Skip Firestore sync → Using local CSV files")

        #STEP 2: CONTENT MODEL 
        logger.info(" Step 2: Training Content-based Model (TF-IDF)...")
        content_ok = train_content_model()
        if not content_ok:
            raise Exception("Content model training failed")

        logger.info(" Content model trained successfully")

        # STEP 3: SVD MODEL
        logger.info(" Step 3: Training Collaborative Model (SVD)...")
        svd_ok = train_svd_model()
        if not svd_ok:
            raise Exception("SVD model training failed")

        logger.info(" SVD model trained successfully")

        #  PUSH TO GITHUB
        logger.info(" Step 4: Uploading models to GitHub Release...")
        new_tag = push_models_to_github(auto_tag=True)

        if new_tag:
            logger.info(f" Successfully created GitHub Release: {new_tag}")
        else:
            logger.warning(" Failed to push to GitHub Release")

        #  SUMMARY 
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds() / 60

        logger.info("=" * 70)
        logger.info(f" FULL RETRAIN HOÀN TẤT!")
        logger.info(f"  Thời gian: {duration:.1f} phút")
        logger.info(f" Hoàn thành lúc: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 70)

        return True

    except Exception as e:
        logger.error(f" FULL RETRAIN FAILED: {e}")
        
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == "__main__":
    # Chọn mode:
    # True  = Sync Firestore trước khi train (khuyến khích)
    # False = Dùng dữ liệu local CSV (nhanh hơn khi test)
    full_retrain(sync_firestore=True)
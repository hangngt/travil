import sys
from pathlib import Path
from datetime import datetime
import logging

BASE_DIR = Path(__file__).resolve().parents[3]
sys.path.append(str(BASE_DIR))

from recommend.backend.services.firestore_sync import FirestoreSync
from recommend.backend.ml.content_base.train_tfidf import train_content_model
from recommend.backend.ml.collaborative.train_svd import train_svd_model
from recommend.backend.task.push_github import push_models_to_github

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def full_retrain(sync_firestore=False):
    """
    Full retrain pipeline
    """

    start_time = datetime.now()

    logger.info(
        f" BẮT ĐẦU FULL RETRAIN - "
        f"{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
    )

    try:

        # STEP 1 - FIRESTORE SYNC (OPTIONAL)
        if sync_firestore:

            logger.info(" Step 1: Syncing Firestore...")

            try:

                sync = FirestoreSync()
                sync.sync_all()

                logger.info("Firestore sync success")

            except Exception as e:

                logger.warning(
                    f" Firestore sync failed -> dùng local data\n{e}"
                )

        else:

            logger.info("Skip Firestore sync")

        # STEP 2 - CONTENT MODEL
        logger.info(" Step 2: Training Content Model...")

        content_ok = train_content_model()

        if not content_ok:
            raise Exception("Content model failed")

        logger.info(" Content model done")

        # STEP 3 - SVD MODEL
        logger.info(" Step 3: Training SVD Model...")

        svd_ok = train_svd_model()

        if not svd_ok:
            raise Exception("SVD model failed")

        logger.info(" SVD model done")

        # STEP 4 - GITHUB RELEASE
        logger.info(" Step 4: Uploading models...")

        new_tag = push_models_to_github(auto_tag=True)

        if not new_tag:
            logger.warning(" Upload failed")
        else:
            logger.info(f" New Release: {new_tag}")

        end_time = datetime.now()

        duration = (
            end_time - start_time
        ).total_seconds() / 60

        logger.info(
            f" FULL RETRAIN HOÀN TẤT "
            f"({duration:.1f} phút)"
        )

        return True

    except Exception as e:

        logger.error(f" Full retrain failed: {e}")

        import traceback
        logger.error(traceback.format_exc())

        return False


if __name__ == "__main__":

    # False = dùng local CSV
    # True = sync Firestore trước khi train
    full_retrain(sync_firestore=False)
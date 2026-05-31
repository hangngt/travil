import subprocess
from datetime import datetime
from pathlib import Path
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parents[3]


def push_models_to_github(auto_tag=True, custom_tag=None):
    """
    Push models to GitHub Release
    CHỈ PUSH CÁC FILE CẦN THIẾT, BỎ COSINE_SIM.NPY
    """
    try:
        # TAG
        if auto_tag:
            date_str = datetime.now().strftime("%Y%m%d_%H%M")
            tag = f"v1.{date_str}"
        else:
            tag = custom_tag

        logger.info(f"Creating GitHub Release with tag: {tag}")

        # FILES - LOẠI BỎ COSINE_SIM.NPY VÌ QUÁ LỚN
        files = [
            "recommend/backend/data/processed/products_clean.csv",
            "recommend/backend/data/processed/tfidf_vectorizer.pkl",
            "recommend/backend/ml/model/svd_model.pkl"
        ]
        
        # KHÔNG push cosine_sim.npy vì file quá lớn (100-200MB)

        # CHECK FILES
        missing_files = []
        full_paths = []

        for f in files:
            full_path = BASE_DIR / f
            logger.info(f"Checking: {full_path}")

            if not full_path.exists():
                missing_files.append(str(full_path))
            else:
                full_paths.append(str(full_path))
                size_mb = full_path.stat().st_size / (1024 * 1024)
                logger.info(f"{full_path.name} | {size_mb:.2f} MB")

        if missing_files:
            logger.error(f"Missing files:\n{missing_files}")
            return False

        # CHECK GH CLI
        try:
            gh_check = subprocess.run(
                ["gh", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if gh_check.returncode != 0:
                logger.error("GitHub CLI not working")
                return False
        except Exception:
            logger.error("GitHub CLI not found")
            logger.error("Run: gh auth login")
            return False

        # CREATE RELEASE
        cmd = [
            "gh",
            "release",
            "create",
            tag,
            "--title",
            f"Model Update {tag}",
            "--notes",
            f"""
Automatic full retrain from Firebase

Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

Content-based + Collaborative Filtering models updated.

**Note**: cosine_sim.npy is not included to save space.
"""
        ] + full_paths

        logger.info("Uploading models to GitHub Release...")
        logger.info(f"Working dir: {BASE_DIR}")

        process = subprocess.Popen(
            cmd,
            cwd=BASE_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        stdout, stderr = process.communicate()

        if process.returncode == 0:
            release_url = f"https://github.com/hangngt/travil/releases/tag/{tag}"
            logger.info("Upload successful!")
            logger.info(f"Release URL: {release_url}")
            return tag
        else:
            logger.error("GitHub Release failed")
            logger.error(stderr)
            return False

    except KeyboardInterrupt:
        logger.warning("Upload cancelled by user")
        return False
    except Exception as e:
        logger.exception(f"Unexpected Error: {e}")
        return False


if __name__ == "__main__":
    push_models_to_github(auto_tag=True)
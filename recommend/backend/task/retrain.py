from ml.content_base.train_tfidf import train_content_model
from ml.collaborative.train_svd import train_svd_model

def full_retrain():
    sync = FirestoreSync()
    sync.sync_all()
    
    train_content_model()
    train_svd_model()
    
    logger.info("🎉 Full Retrain hoàn tất!")
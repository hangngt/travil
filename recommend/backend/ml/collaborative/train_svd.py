# %%
import pandas as pd
import pickle
from pathlib import Path
import numpy as np


from sklearn.model_selection import KFold

import warnings
warnings.filterwarnings('ignore')
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Đường dẫn
BASE_DIR = Path(__file__).resolve().parents[4]

DATA_PROCESSED = BASE_DIR /"recommend"/"backend"/ "data" / "processed"
MODEL_DIR = BASE_DIR /"recommend"/"backend" / "ml" / "model"

# Hyperparameters
K = 16          # số latent factors (embedding dim)
lambda_reg = 0.01  # regularization
lr = 0.005      # learning rate
epochs = 30     # số epoch
n_folds = 5     # 5-fold CV

# %%
#LOAD DATA
print("Đang load real ratings...")
# print("DATA_PROCESSED:", DATA_PROCESSED)
# csv_path = DATA_PROCESSED / 'user_item_ratings_real.csv'

# print("CSV PATH:", csv_path)

# print("EXISTS:", csv_path.exists())
# print(os.listdir(r'E:\multiproject\multiplatform\travil\data\processed'))
ratings = pd.read_csv(DATA_PROCESSED / 'user_item_ratings_real.csv')
# ratings = pd.read_csv(
#     r"recommend\backend\data\processed\user_item_ratings_real.csv"
# )

# Map user_id và product_id thành index số
user_ids = ratings['user_id'].unique()
item_ids = ratings['product_id'].unique()

user_to_idx = {uid: i for i, uid in enumerate(user_ids)}
item_to_idx = {iid: i for i, iid in enumerate(item_ids)}

ratings['user_idx'] = ratings['user_id'].map(user_to_idx)
ratings['item_idx'] = ratings['product_id'].map(item_to_idx)

n_users = len(user_ids)
n_items = len(item_ids)

print(f"Users: {n_users} | Items: {n_items} | Ratings: {len(ratings)}")

# %%
#HÀM PER-USER 5-FOLD CV
def per_user_kfold_indices(df, n_folds=5, random_state=42):
    # """
    # Step 1: Per-user split.
    # Đảm bảo các rating của cùng 1 user được phân bổ đều vào các fold.
    # Điều này tránh rò rỉ thông tin khi validation (không có user lạ trong validation set).
    # """
    np.random.seed(random_state)
    fold_indices = [[] for _ in range(n_folds)]
   
    for user_idx, group in df.groupby('user_idx'):
        indices = group.index.values
        np.random.shuffle(indices)
        splits = np.array_split(indices, n_folds)
        for fold in range(n_folds):
            fold_indices[fold].extend(splits[fold])
          
    folds = []
    all_indices = np.array(df.index.values)
    for fold in range(n_folds):
        val_idx = np.array(fold_indices[fold])
        train_idx = np.setdiff1d(all_indices, val_idx)
        folds.append((train_idx, val_idx))
    return folds


# %%
#svd training function
def train_svd(train_data, val_data, K, epochs, lr, lambda_reg, n_users, n_items):
    # """
    # Huấn luyện Matrix Factorization bằng Stochastic Gradient Descent (SGD).
    # """
    # Khởi tạo ma trận latent factors W (user) và H (item)
    W = np.random.normal(0, 0.1, (n_users, K))
    H = np.random.normal(0, 0.1, (n_items, K))
   
    train_users = train_data['user_idx'].values.astype(int)
    train_items = train_data['item_idx'].values.astype(int)
    train_ratings = train_data['rating'].values
   
    val_users = val_data['user_idx'].values.astype(int)
    val_items = val_data['item_idx'].values.astype(int)
    val_ratings = val_data['rating'].values
   
    for epoch in range(epochs):
        indices = np.arange(len(train_users))
        np.random.shuffle(indices)
       
        for idx in indices:
            u = train_users[idx]
            i = train_items[idx]
            r = train_ratings[idx]
           
            pred = np.dot(W[u], H[i])
            err = r - pred
           
            w_old = W[u].copy()
            W[u] += lr * (err * H[i] - lambda_reg * W[u])
            H[i] += lr * (err * w_old - lambda_reg * H[i])
       
        if epoch % 5 == 0 or epoch == epochs - 1:
            train_preds = np.sum(W[train_users] * H[train_items], axis=1)
            train_rmse = np.sqrt(np.mean((train_ratings - train_preds) ** 2))
           
            val_preds = np.sum(W[val_users] * H[val_items], axis=1)
            val_rmse = np.sqrt(np.mean((val_ratings - val_preds) ** 2))
           
            logger.info(f"Epoch {epoch+1:2d}/{epochs} | Train RMSE: {train_rmse:.4f} | Val RMSE: {val_rmse:.4f}")
   
    final_val_rmse = np.sqrt(np.mean((val_ratings - np.sum(W[val_users] * H[val_items], axis=1)) ** 2))
    return W, H, final_val_rmse

def train_svd_model():
    """Hàm chính để retrain SVD"""
    logger.info(" Bắt đầu train SVD Model...")
    
    try:
        ratings = pd.read_csv(DATA_PROCESSED / 'user_item_ratings_real.csv')
        
        user_ids = ratings['user_id'].unique()
        item_ids = ratings['product_id'].unique()
        
        user_to_idx = {uid: i for i, uid in enumerate(user_ids)}
        item_to_idx = {iid: i for i, iid in enumerate(item_ids)}
        
        ratings['user_idx'] = ratings['user_id'].map(user_to_idx)
        ratings['item_idx'] = ratings['product_id'].map(item_to_idx)
        
        n_users = len(user_ids)
        n_items = len(item_ids)
        logger.info(f"Users: {n_users} | Items: {n_items} | Ratings: {len(ratings)}")

        folds = per_user_kfold_indices(ratings, n_folds=n_folds)
        
        best_val_rmse = float('inf')
        best_P = None
        best_Q = None

        for fold, (train_idx, val_idx) in enumerate(folds):
            logger.info(f"--- Fold {fold+1}/{n_folds} ---")
            train_data = ratings.iloc[train_idx]
            val_data = ratings.iloc[val_idx]
            
            P, Q, val_rmse = train_svd(train_data, val_data, K, epochs, lr, lambda_reg, n_users, n_items)
            
            if val_rmse < best_val_rmse:
                best_val_rmse = val_rmse
                best_P = P.copy()
                best_Q = Q.copy()

        # Save model
        model_data = {
            'P': best_P,
            'Q': best_Q,
            'user_to_idx': user_to_idx,
            'item_to_idx': item_to_idx,
            'user_ids': user_ids,
            'item_ids': item_ids,
            'K': K
        }
        
        MODEL_DIR.mkdir(parents=True, exist_ok=True)
        with open(MODEL_DIR / 'svd_model.pkl', 'wb') as f:
            pickle.dump(model_data, f)
            
        logger.info(f" SVD Model trained successfully! Best Val RMSE: {best_val_rmse:.4f}")

        return best_P, best_Q, user_ids, item_ids, ratings

    except Exception as e:
        logger.error(f" Train SVD failed: {e}")
        return False

# %%
if __name__ == "__main__":
    best_P, best_Q, user_ids, item_ids, ratings = train_svd_model()

# %%
#TEST DỰ ĐOÁN
print(f"\n{'='*50}")
print("TEST DỰ ĐOÁN CHO USER ĐẦU TIÊN")
print(f"{'='*50}")

# Lấy user đầu tiên để test
test_user_idx = 0
test_user_id = user_ids[test_user_idx]

# Lấy các item user đã rating
user_ratings = ratings[ratings['user_idx'] == test_user_idx]
print(f"\nUser {test_user_id} đã rating {len(user_ratings)} sản phẩm:")

# Dự đoán cho tất cả item
predictions = []
for item_idx in range(n_items):
    pred = np.dot(best_P[test_user_idx], best_Q[item_idx])
    predictions.append(pred)

# Lấy top 5 item có dự đoán cao nhất
top_items = np.argsort(predictions)[-5:][::-1]
print(f"\nTop 5 sản phẩm gợi ý cho user {test_user_id}:")
for i, item_idx in enumerate(top_items, 1):
    item_id = item_ids[item_idx]
    pred_score = predictions[item_idx]
    
    # Kiểm tra xem user đã rating item này chưa
    rated = item_id in user_ratings['product_id'].values
    status = " ĐÃ RATING" if rated else " GỢI Ý MỚI"
    
    print(f"  {i}. Item {item_id} | Score: {pred_score:.4f} | {status}")


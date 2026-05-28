import firebase_admin
from firebase_admin import credentials, storage
import tempfile

# INIT 1 lần duy nhất
cred = credentials.Certificate("serviceAccountKey.json")

firebase_admin.initialize_app(cred, {
    "storageBucket": "your-project-id.appspot.com"
})

bucket = storage.bucket()


def download_from_firebase(blob_name: str):
    blob = bucket.blob(blob_name)

    tmp = tempfile.NamedTemporaryFile(delete=False)
    blob.download_to_filename(tmp.name)

    return tmp.name
import os
import sys
from supabase import create_client, Client

# --- CẤU HÌNH ---
SUPABASE_URL: str = os.environ.get("SUPABASE_URL")
SERVICE_ROLE_KEY: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

BUCKET = "waste-reports"
MODEL_REMOTE_PATH = "models/latest/model_unquant.tflite"
LABELS_REMOTE_PATH = "models/latest/labels.txt"

LOCAL_MODEL_PATH = "model_unquant.tflite"
LOCAL_LABELS_PATH = "labels.txt"


def upload_file(supabase: Client, local_path: str, remote_path: str, content_type: str):
    """Upload một file lên Supabase Storage, ghi đè nếu đã tồn tại (upsert)."""
    if not os.path.exists(local_path):
        print(f"⚠️ Không tìm thấy file '{local_path}', bỏ qua.")
        return False

    file_size = os.path.getsize(local_path) / 1024
    print(f"📤 Đang upload '{local_path}' ({file_size:.1f} KB) → gs://{BUCKET}/{remote_path} ...")

    with open(local_path, "rb") as f:
        data = f.read()

    try:
        # Thử xóa file cũ trước để tránh lỗi "already exists"
        supabase.storage.from_(BUCKET).remove([remote_path])
    except Exception:
        pass  # Bỏ qua nếu file chưa tồn tại

    response = supabase.storage.from_(BUCKET).upload(
        path=remote_path,
        file=data,
        file_options={"content-type": content_type},
    )

    print(f"✅ Upload thành công: {response.path}")
    return True


def upload_model():
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("❌ Lỗi: Thiếu biến môi trường SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY.")
        print("   → Hãy kiểm tra GitHub Secrets của repo.")
        sys.exit(1)

    print("🔗 Đang kết nối Supabase với Service Role Key...")
    supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

    model_ok = upload_file(supabase, LOCAL_MODEL_PATH, MODEL_REMOTE_PATH, "application/octet-stream")
    labels_ok = upload_file(supabase, LOCAL_LABELS_PATH, LABELS_REMOTE_PATH, "text/plain")

    if model_ok and labels_ok:
        print("\n🎉 Hoàn tất! Model và labels đã sẵn sàng tại:")
        print(f"   {SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{MODEL_REMOTE_PATH}")
        print(f"   {SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{LABELS_REMOTE_PATH}")
    elif not model_ok:
        print("\n❌ THẤT BẠI: Không tìm thấy model_unquant.tflite để upload.")
        sys.exit(1)


if __name__ == "__main__":
    upload_model()

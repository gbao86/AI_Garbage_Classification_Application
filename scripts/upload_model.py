import os
import sys
import json
from supabase import create_client, Client

# --- CẤU HÌNH ---
SUPABASE_URL: str = os.environ.get("SUPABASE_URL")
SERVICE_ROLE_KEY: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

BUCKET = "waste-reports"
MODEL_REMOTE_PATH = "models/latest/model_unquant.tflite"
LABELS_REMOTE_PATH = "models/latest/labels.txt"

LOCAL_MODEL_PATH = "model_unquant.tflite"
LOCAL_LABELS_PATH = "labels.txt"
LOCAL_METADATA_PATH = "training_metadata.json"


def upload_file(supabase: Client, local_path: str, remote_path: str, content_type: str) -> bool:
    """Upload một file lên Supabase Storage, ghi đè nếu đã tồn tại."""
    if not os.path.exists(local_path):
        print(f"⚠️ Không tìm thấy file '{local_path}', bỏ qua.")
        return False

    file_size = os.path.getsize(local_path) / 1024
    print(f"📤 Đang upload '{local_path}' ({file_size:.1f} KB) → {BUCKET}/{remote_path} ...")

    with open(local_path, "rb") as f:
        data = f.read()

    try:
        # Xóa file cũ trước để tránh lỗi "already exists"
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


def record_model_version(supabase: Client, image_count: int, model_url: str, labels_url: str):
    """Ghi lịch sử train vào bảng model_versions trong database."""
    print("📋 Đang ghi lịch sử vào bảng model_versions...")
    try:
        supabase.table("model_versions").insert({
            "image_count": image_count,
            "model_url": model_url,
            "labels_url": labels_url,
            "notes": f"Auto-trained by GitHub Actions với {image_count} ảnh approved."
        }).execute()
        print("✅ Đã lưu lịch sử train vào database.")
    except Exception as e:
        # Không fail cả workflow chỉ vì insert DB lỗi
        print(f"⚠️ Không thể ghi vào model_versions: {e}")


def upload_model():
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("❌ Lỗi: Thiếu biến môi trường SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY.")
        print("   → Hãy kiểm tra GitHub Secrets của repo.")
        sys.exit(1)

    # Kiểm tra xem training có chạy thành công không
    if not os.path.exists(LOCAL_MODEL_PATH):
        print("\n⏭️ Bỏ qua upload: Không có model mới (training chưa chạy do thiếu dữ liệu).")
        print("   → Workflow hoàn thành bình thường. Duyệt thêm báo cáo để train lần sau.")
        return

    print("🔗 Đang kết nối Supabase với Service Role Key...")
    supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

    model_ok = upload_file(supabase, LOCAL_MODEL_PATH, MODEL_REMOTE_PATH, "application/octet-stream")
    labels_ok = upload_file(supabase, LOCAL_LABELS_PATH, LABELS_REMOTE_PATH, "text/plain")

    if model_ok and labels_ok:
        model_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{MODEL_REMOTE_PATH}"
        labels_url = f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{LABELS_REMOTE_PATH}"

        # Đọc số ảnh đã train từ file metadata
        image_count = 0
        if os.path.exists(LOCAL_METADATA_PATH):
            with open(LOCAL_METADATA_PATH, "r") as f:
                image_count = json.load(f).get("image_count", 0)

        # Ghi lịch sử vào database
        record_model_version(supabase, image_count, model_url, labels_url)

        print("\n🎉 Hoàn tất! Model và labels đã sẵn sàng tại:")
        print(f"   {model_url}")
        print(f"   {labels_url}")
    else:
        print("\n⚠️ Upload không hoàn chỉnh, kiểm tra lại log ở trên.")


if __name__ == "__main__":
    upload_model()

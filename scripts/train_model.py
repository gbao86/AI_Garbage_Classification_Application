import os
import tensorflow as tf
from supabase import create_client, Client
import requests
from PIL import Image
from io import BytesIO
import numpy as np
import pandas as pd
import gc
from sklearn.model_selection import train_test_split
from sklearn.utils import class_weight

# --- 1. CẤU HÌNH & KẾT NỐI ---
URL: str = os.environ.get("SUPABASE_URL")
KEY: str = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(URL, KEY)

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
NUM_CLASSES = 10

# Thứ tự nhãn cố định để đồng bộ với App và Model
LABEL_MAP = {
    'battery': 0, 'biological': 1, 'cardboard': 2, 'clothes': 3,
    'glass': 4, 'metal': 5, 'paper': 6, 'plastic': 7, 'shoes': 8, 'trash': 9
}

def download_dataset():
    print("🚀 Đang kiểm tra và tải dữ liệu từ Supabase...")
    try:
        response = supabase.table("waste_submissions").select("scan_image_path, tflite_top_label").eq("status", "approved").execute()
        data = response.data
    except Exception as e:
        print(f"❌ Lỗi kết nối Supabase: {e}")
        return None

    # --- NGƯỠNG TỐI THIỂU 50 ẢNH ĐỂ TRAIN ---
    MIN_IMAGES = 50
    if len(data) < MIN_IMAGES:
        print(f"⚠️ Dữ liệu hiện có {len(data)} ảnh, chưa đủ ngưỡng tối thiểu ({MIN_IMAGES}) để bắt đầu huấn luyện.")
        return None

    os.makedirs("dataset", exist_ok=True)
    records = []

    for item in data:
        img_url = item['scan_image_path']
        label_str = item['tflite_top_label']
        if not label_str or not img_url or label_str not in LABEL_MAP: continue

        try:
            label_dir = os.path.join("dataset", label_str)
            os.makedirs(label_dir, exist_ok=True)

            img_name = img_url.split("/")[-1].split("?")[0]
            local_path = os.path.join(label_dir, img_name)

            if not os.path.exists(local_path):
                img_res = requests.get(img_url, timeout=15)
                img = Image.open(BytesIO(img_res.content)).convert('RGB')
                img = img.resize(IMG_SIZE)
                img.save(local_path)

            records.append({'path': local_path, 'label': LABEL_MAP[label_str]})
        except Exception as e:
            print(f"⚠️ Bỏ qua ảnh lỗi: {e}")

    print(f"✅ Đã tải xong {len(records)} ảnh.")
    return pd.DataFrame(records)

# --- 2. XỬ LÝ ẢNH & AUGMENTATION ---
def professional_aug(image):
    if tf.random.uniform([]) > 0.95:
        image = tf.image.rgb_to_grayscale(image)
        image = tf.image.grayscale_to_rgb(image)
    noise = tf.random.normal(shape=tf.shape(image), mean=0.0, stddev=0.05, dtype=tf.float32)
    image = tf.add(image, noise)
    image = tf.image.random_brightness(image, max_delta=0.2)
    image = tf.image.random_contrast(image, 0.8, 1.2)
    image = tf.clip_by_value(image, 0, 255)
    return image

def parse_fn(path, label, augment=False):
    try:
        image = tf.io.read_file(path)
        image = tf.image.decode_jpeg(image, channels=3)
        image = tf.image.resize(image, IMG_SIZE)
        if augment: image = professional_aug(image)
        return image, tf.one_hot(label, NUM_CLASSES)
    except:
        return tf.zeros([224, 224, 3]), tf.zeros([NUM_CLASSES])

def get_dataset(df, augment=False, is_train=False):
    ds = tf.data.Dataset.from_tensor_slices((df['path'], df['label']))
    if is_train: ds = ds.shuffle(len(df))
    ds = ds.map(lambda p, l: parse_fn(p, l, augment), num_parallel_calls=tf.data.AUTOTUNE)
    if is_train:
        ds = ds.repeat().batch(BATCH_SIZE, drop_remainder=True)
    else:
        ds = ds.batch(BATCH_SIZE)
    return ds.prefetch(tf.data.AUTOTUNE)

class MemoryCleanupCallback(tf.keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        gc.collect()
        tf.keras.backend.clear_session()

def train_process():
    df = download_dataset()
    if df is None: return

    train_df, val_df = train_test_split(df, test_size=0.2, stratify=df['label'], random_state=42)
    weights = class_weight.compute_class_weight('balanced', classes=np.unique(df['label']), y=df['label'])
    cw_dict = {i: weights[i] for i in range(len(weights))}

    train_ds = get_dataset(train_df, augment=True, is_train=True)
    val_ds = get_dataset(val_df, augment=False, is_train=False)

    steps_per_epoch = max(1, len(train_df) // BATCH_SIZE)

    base_model = tf.keras.applications.MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
    base_model.trainable = False

    model = tf.keras.Sequential([
        tf.keras.Input(shape=(224, 224, 3)),
        tf.keras.layers.Rescaling(1./255),
        base_model,
        tf.keras.layers.GlobalAveragePooling2D(),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Dropout(0.4),
        tf.keras.layers.Dense(NUM_CLASSES, activation='softmax')
    ])

    print("🔥 GĐ 1: Warm-up (20 Epochs)...")
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-3), loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_ds, steps_per_epoch=steps_per_epoch, validation_data=val_ds, epochs=20, class_weight=cw_dict, callbacks=[MemoryCleanupCallback()])

    print("🎯 GĐ 2: Fine-tuning (50 Epochs)...")
    base_model.trainable = True
    for layer in base_model.layers[:100]: layer.trainable = False

    model.compile(optimizer=tf.keras.optimizers.Adam(1e-5), loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(train_ds, steps_per_epoch=steps_per_epoch, validation_data=val_ds, epochs=50, class_weight=cw_dict, callbacks=[
        tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
        MemoryCleanupCallback()
    ])

    # --- XUẤT FILE TFLITE ---
    print("📦 Đang chuyển đổi sang TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    with open('model_unquant.tflite', 'wb') as f:
        f.write(tflite_model)

    # --- XUẤT FILE LABELS.TXT ---
    print("📝 Đang tạo file labels.txt...")
    sorted_labels = sorted(LABEL_MAP.items(), key=lambda x: x[1])
    with open('labels.txt', 'w') as f:
        for label, _ in sorted_labels:
            f.write(f"{label}\n")

    print("🎯 Hoàn tất! Đã tạo xong model_unquant.tflite và labels.txt thành công.")

if __name__ == "__main__":
    train_process()
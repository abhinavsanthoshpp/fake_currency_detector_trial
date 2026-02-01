import tensorflow as tf
import numpy as np
import cv2
import os
from scipy.spatial import distance

# ================= CONFIGURATION =================
# 1. PATH TO YOUR TRAINED MODEL
MODEL_PATH = "verifier_model.h5"

# 2. PATH TO A TRUSTED "REAL" IMAGE (From your training dataset)
# Go into 'model_2_dataset/Gandhi_potrait/' and copy one filename here.
ANCHOR_IMAGE_PATH = "/home/hannibal/Code/Projects/Currency_Project/model_2_dataset/Gandhi_potrait/20251004_115503_jpg.rf.073aadb67e6e9d6efb34799d8edf9310_Gandhi_potrait_605.jpg" 

# 3. PATH TO THE NEW "OUTSIDE" IMAGE TO TEST
# This is the Dollar or random image you downloaded
TEST_IMAGE_PATH = "trial_image"

# 4. THRESHOLD (The "Strictness" Level)
# Distance < 0.5 means MATCH
# Distance > 0.5 means DIFFERENT
THRESHOLD = 0.5 
# =================================================

def preprocess_image(path):
    if not os.path.exists(path):
        print(f"Error: Image not found at {path}")
        return None

    # 1. Load Image (OpenCV loads as BGR)
    img = cv2.imread(path)
    
    # 2. Convert to RGB (Model expects RGB)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # 3. Resize to 128x128
    img = cv2.resize(img, (128, 128))
    
    # 4. NO DIVIDING BY 255! 
    # Because EfficientNetV2 handles the scaling internally.
    # We keep it as float32 in range [0, 255]
    img = img.astype("float32")
    
    # 5. Add Batch Dimension (128,128,3) -> (1, 128,128,3)
    img = np.expand_dims(img, axis=0)
    return img

def verify():
    if not os.path.exists(MODEL_PATH):
        print("Model not found!")
        return

    print("Loading model...")
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)

    # 1. Load Images
    anchor_img = preprocess_image(ANCHOR_IMAGE_PATH)
    test_img = preprocess_image(TEST_IMAGE_PATH) # Your fake/real image

    if anchor_img is None or test_img is None: return

    # 2. Get Raw Vectors
    vec_a = model.predict(anchor_img, verbose=0)[0]
    vec_b = model.predict(test_img, verbose=0)[0]

    # ================= THE FIX =================
    # Normalize vectors (make their length = 1.0)
    # This forces the Distance to be between 0.0 (Identical) and 2.0 (Opposite)
    vec_a = vec_a / np.linalg.norm(vec_a)
    vec_b = vec_b / np.linalg.norm(vec_b)
    # ===========================================

    # 3. Calculate Distance
    dist = distance.euclidean(vec_a, vec_b)

    print(f"\n--- NORMALIZED RESULTS ---")
    print(f"Distance Score: {dist:.4f}")
    
    # Standard Thresholds for Normalized Vectors:
    # 0.00 - 0.75 : MATCH ✅
    # 0.75 - 1.00 : UNCERTAIN ❓
    # 1.00 +      : NO MATCH ❌
    
    if dist < 0.8:  # Set your threshold to 0.8
        print("✅ MATCH: Genuine Feature")
    else:
        print("❌ NO MATCH: Fake or Different")

if __name__ == "__main__":
    verify()